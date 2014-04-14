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
require File.expand_path './site-inspector/cache',      File.dirname(__FILE__)
require File.expand_path './site-inspector/sniffer',    File.dirname(__FILE__)
require File.expand_path './site-inspector/dns',        File.dirname(__FILE__)
require File.expand_path './site-inspector/compliance', File.dirname(__FILE__)

class SiteInspector

  def initialize(domain)
    domain = domain.sub /^http\:/, ""
    domain = domain.sub /^\/+/, ""
    domain = domain.sub /^www\./, ""
    @uri = Addressable::URI.parse "//#{domain}"
    @domain = PublicSuffix.parse @uri.host
    Typhoeus::Config.cache = SiteInspectorCache.new
  end

  def inspect
    "<SiteInspector domain=\"#{domain}\">"
  end

  def uri(ssl=false,www=false)
    uri = @uri.clone
    uri.host = "www.#{uri.host}" if www
    uri.scheme = ssl ? "https" : "http"
    uri
  end

  def domain
    non_www? ? @domain : PublicSuffix.parse("www.#{@uri.host}")
  end

  def request(ssl=false, www=false)
    response = Typhoeus::Request.get(uri(ssl, www), followlocation: true)
    response if response.success?
  end

  def response
    @response ||= begin
      if response = request(false, false)
        @non_www = true
        response
      elsif response = request(false, true)
        @non_www = false
        response
      else
        false
      end
    end
  end

  def doc
    @doc ||= Nokogiri::HTML response.body if response
  end

  def body
    doc.to_s
  end

  def load_data(name)
    YAML.load_file File.expand_path "./data/#{name}.yml", File.dirname(__FILE__)
  end

  def government?
    Gman.valid? domain.to_s
  end

  def https?
    @https ||= !!request(true, !non_www?)
  end

  def enforce_https?
    return false unless https?
    @enforce_https ||= begin
      response = request(false, !non_www?)
      if response.effective_url
        Addressable::URI.parse(response.effective_url).scheme == "https"
      else
        puts response.inspect
        false
      end
    end
  end

  def non_www?
    response && @non_www
  end

  def to_json
    {
      :government => government?,
      :live => !!response,
      :ssl => https?,
      :enforce_https => enforce_https?,
      :non_www => non_www?,
      :ip => ip,
      :hostname => hostname,
      :ipv6 => ipv6?,
      :dnssec => dnssec?,
      :cdn => cdn,
      :google_apps => google_apps?,
      :could_provider => cloud_provider,
      :server => server,
      :cms => cms,
      :analytics => analytics,
      :javascript => javascript,
      :advertising => advertising,
      :slash_data => slash_data?,
      :slash_developer => slash_developer?,
      :data_dot_json => data_dot_json?
    }.to_json
  end
end
