require 'nokogiri'
require 'open-uri'
require 'public_suffix'
require 'gman'
require 'net/http'
require "dnsruby"
require 'yaml'
require 'sniffles'
require "addressable/uri"
require 'typhoeus'
require 'json'
require 'resolv'

require_relative 'site-inspector/cache'
require_relative 'site-inspector/sniffer'
require_relative 'site-inspector/dns'
require_relative 'site-inspector/compliance'
require_relative 'site-inspector/headers'

Typhoeus::Config.cache = SiteInspectorCache.new
#Typhoeus::Config.memoize = true

class SiteInspector

  def self.load_data(name)
    YAML.load_file File.expand_path "./data/#{name}.yml", File.dirname(__FILE__)
  end

  def initialize(domain)
    domain = domain.downcase
    domain = domain.sub /^https?\:/, ""
    domain = domain.sub /^\/+/, ""
    domain = domain.sub /^www\./, ""
    @uri = Addressable::URI.parse "//#{domain}"
    @domain = PublicSuffix.parse @uri.host
  end

  def inspect
    "<SiteInspector domain=\"#{domain}\">"
  end

  def uri(ssl=https?,www=www?)
    uri = @uri.clone
    uri.host = "www.#{uri.host}" if www
    uri.scheme = ssl ? "https" : "http"
    uri
  end

  def domain
    www? ? PublicSuffix.parse("www.#{@uri.host}") : @domain
  end

  def request(ssl=false, www=false, followlocation=true)
    Typhoeus.get(uri(ssl, www), followlocation: followlocation, timeout: 10)
  end

  def response
    @response ||= begin
      if response = request(false, false) and response.success?
        @non_www = true
        response
      elsif response = request(false, true) and response.success?
        @non_www = false
        response
      else
        false
      end
    end
  end

  def timed_out?
    response && response.timed_out?
  end

  def doc
    @doc ||= Nokogiri::HTML response.body if response
  end

  def body
    doc.to_s.force_encoding("UTF-8").encode("UTF-8", :invalid => :replace, :replace => "")
  end

  def government?
    Gman.valid? domain.to_s
  end

  def https?
    @https ||= request(true, www?).success?
  end
  alias_method :ssl?, :https?

  def enforce_https?
    return false unless https?
    @enforce_https ||= begin
      response = request(false, www?)
      if response.effective_url
        Addressable::URI.parse(response.effective_url).scheme == "https"
      else
        false
      end
    end
  end

  def www?
    response && response.effective_url && !!response.effective_url.match(/https?:\/\/www\./)
  end

  def non_www?
    response && @non_www
  end

  def redirect?
    !!redirect
  end

  def redirect
    @redirect ||= begin
      if location = request(https?, www?, false).headers["location"]
        redirect_domain = SiteInspector.new(location).domain
        redirect_domain.to_s if redirect_domain.to_s != domain.to_s
      end
    rescue
      nil
    end
  end

  def to_json
    to_hash.to_json
  end

  def to_hash
    {
      :domain => domain.to_s,
      :uri => uri.to_s,
      :government => government?,
      :live => !!response,
      :ssl => https?,
      :enforce_https => enforce_https?,
      :non_www => non_www?,
      :redirect => redirect,
      :ip => ip,
      :hostname => hostname.to_s,
      :ipv6 => ipv6?,
      :dnssec => dnssec?,
      :cdn => cdn,
      :google_apps => google_apps?,
      :cloud_provider => cloud_provider,
      :server => server,
      :cms => cms,
      :analytics => analytics,
      :javascript => javascript,
      :advertising => advertising,
      :slash_data => slash_data?,
      :slash_developer => slash_developer?,
      :data_dot_json => data_dot_json?,
      :click_jacking_protection => click_jacking_protection?,
      :content_security_policy => content_security_policy?,
      :xss_protection => xss_protection?,
      :secure_cookies => secure_cookies?,
      :strict_transport_security => strict_transport_security?
    }
  end
end
