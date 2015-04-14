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

if ENV['CACHE']
  Typhoeus::Config.cache = SiteInspectorDiskCache.new(ENV['CACHE'])
else
  Typhoeus::Config.cache = SiteInspectorCache.new
end

class SiteInspector

  def self.load_data(name)
    YAML.load_file File.expand_path "./data/#{name}.yml", File.dirname(__FILE__)
  end

  # makes no network requests
  def initialize(domain, options = {})
    domain = domain.downcase
    domain = domain.sub /^https?\:/, ""
    domain = domain.sub /^\/+/, ""
    domain = domain.sub /^www\./, ""
    @uri = Addressable::URI.parse "//#{domain}"
    @domain = PublicSuffix.parse @uri.host
    @timeout = options[:timeout] || 10
  end

  def inspect
    "<SiteInspector domain=\"#{domain}\">"
  end

  def uri(ssl=enforce_https?,www=www?)
    uri = @uri.clone
    uri.host = www ? "www.#{uri.host}" : uri.host
    uri.scheme = ssl ? "https" : "http"
    uri
  end

  def domain
    www? ? PublicSuffix.parse("www.#{@uri.host}") : @domain
  end

  def request(ssl=false, www=false, followlocation=true, ssl_verifypeer=true, ssl_verifyhost=true)
    to_get = uri(ssl, www)

    # debugging
    # puts "fetching: #{to_get}, #{followlocation ? "follow" : "no follow"}, #{ssl_verifypeer ? "verify peer, " : ""}#{ssl_verifyhost ? "verify host" : ""}"

    Typhoeus.get(to_get, followlocation: followlocation, ssl_verifypeer: ssl_verifypeer, ssl_verifyhost: (ssl_verifyhost ? 2 : 0), timeout: @timeout)
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

  def http
    details = {
      # site-inspector's best guess
      canonical: uri.to_s,
      canonical_protocol: https? ? :https : :http,
      canonical_endpoint: www? ? :www : :root,

      endpoints: endpoints
    }

    combos = details[:endpoints]

    details[:live] = !!(
      combos[:https][:www][:live] or
      combos[:https][:root][:live] or
      combos[:http][:www][:live] or
      combos[:http][:root][:live]
    )

    details[:broken_root] = !!(
      (combos[:https][:root][:status] == 0) and
      (combos[:http][:root][:status] == 0)
    )

    details[:broken_www] = !!(
      (combos[:https][:www][:status] == 0) and
      (combos[:http][:www][:status] == 0)
    )

    details[:enforce_https] = !!(
      (
        (combos[:http][:www][:status] == 0) ||
        (combos[:http][:www][:redirect_to_https])
      ) and
      (
        (combos[:http][:root][:status] == 0) or
        (combos[:http][:root][:redirect_to_https])
      ) and
      (
        combos[:https][:www][:live] or
        combos[:https][:root][:live]
      )
    )

    details[:redirect] = !!(
      combos[:http][:www][:redirect_to_external] and
      combos[:http][:root][:redirect_to_external] and
      combos[:https][:www][:redirect_to_external] and
      combos[:https][:root][:redirect_to_external]
    )

    # HSTS on the canonical domain? (valid HTTPS checked in endpoint)
    details[:hsts] = !!combos[:https][details[:canonical_endpoint]][:hsts]
    details[:hsts_header] = combos[:https][details[:canonical_endpoint]][:hsts_header]

    # HSTS on the entire domain?
    details[:hsts_entire_domain] = !!(
      combos[:https][:root][:hsts] and
      combos[:https][:root][:hsts_header].downcase.include?("includesubdomains")
    )

    # HSTS preload --ready?
    details[:hsts_entire_domain_preload] = !!(
      details[:hsts_entire_domain] and
      combos[:https][:root][:hsts_header].downcase.include?("preload")
    )

    details
  end

  def endpoints
    https_www = http_endpoint(true, true)
    http_www = http_endpoint(false, true)
    https_root = http_endpoint(true, false)
    http_root = http_endpoint(false, false)

    {
      https: {
        www: https_www,
        root: https_root
      },
      http: {
        www: http_www,
        root: http_root
      }
    }
  end

  # State of affairs at a particular endpoint.
  def http_endpoint(ssl, www)
    details = {}

    # Don't follow redirects for first ping.
    response = request(ssl, www, false)


    # For HTTPS: examine the full range of possibilities.
    if ssl
      if response.return_code == :ok
        details[:https_valid] = true

      # Bad certificate chain.
      elsif response.return_code == :ssl_cacert
        details[:https_valid] = false
        details[:https_bad_chain] = true
        response = request(ssl, www, false, false, true)
        # Bad everything.
        if response.return_code == :peer_failed_verification
          details[:https_bad_name] = true
          response = request(ssl, www, false, false, false)
        end
      # Bad hostname.
      elsif response.return_code == :peer_failed_verification
        details[:https_valid] = false
        details[:https_bad_name] = true
        response = request(ssl, www, false, true, false)
        # Bad everything.
        if response.return_code == :ssl_cacert
          details[:https_bad_chain] = true
          response = request(ssl, www, false, false, false)
        end
      end
    end

    # If we ended up with a failure, return it.
    details[:status] = response.response_code
    return details if response.response_code == 0

    headers = Hash[response.headers.map{ |k,v| [k.downcase,v] }]
    details[:headers] = headers


    # HSTS only takes effect when delivered over valid HTTPS.
    details[:hsts] = !!(ssl and details[:https_valid] and headers["strict-transport-security"])
    details[:hsts_header] = headers["strict-transport-security"]


    # If it's a redirect, go find the ultimate response starting from this combo.
    redirect_code = response.response_code.to_s.start_with?("3")
    location_header = headers["location"]
    if redirect_code and location_header
      details[:redirect] = true

      ultimate_response = request(ssl, www, true, !details[:https_bad_chain], !details[:https_bad_name])
      uri_original = URI(ultimate_response.request.url)
      uri_eventual = URI(ultimate_response.effective_url)

      details[:redirect_to] = uri_eventual.to_s
      details[:redirect_to_external] = ((uri_original.hostname != uri_eventual.hostname) or (uri_original.scheme != uri_eventual.scheme))
      details[:redirect_to_https] = (uri_eventual.scheme == "https")

      details[:live] = ultimate_response.success?

    # otherwise, judge it here
    else
      details[:redirect] = false
      details[:redirect_to_external] = false
      details[:redirect_to_https] = false
      details[:live] = response.success?
    end

    details
  end

  def to_hash(http_only=false)
    if http_only
      {
        :domain => domain.to_s,
        :uri => uri.to_s,
        :live => !!response,
        :ssl => https?,
        :enforce_https => enforce_https?,
        :non_www => non_www?,
        :redirect => redirect,
        :headers => headers
      }
    else
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
        :strict_transport_security => strict_transport_security?,
        :headers => headers
      }
    end
  end
end
