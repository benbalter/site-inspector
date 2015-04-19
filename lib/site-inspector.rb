
# needed for HTTP analysis
require 'open-uri'
require "addressable/uri"
require 'public_suffix'
require 'typhoeus'

require_relative 'site-inspector/cache'
require_relative 'site-inspector/headers'
require_relative 'site-inspector/sniffer'
require_relative 'site-inspector/dns'
require_relative 'site-inspector/compliance'


if ENV['CACHE']
  Typhoeus::Config.cache = SiteInspectorDiskCache.new(ENV['CACHE'], ENV['CACHE_REPLACE'])
else
  Typhoeus::Config.cache = SiteInspectorCache.new
end

class SiteInspector

  def self.load_data(name)
    require 'yaml'
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
    require 'nokogiri'
    @doc ||= Nokogiri::HTML response.body if response
  end

  def body
    doc.to_s.force_encoding("UTF-8").encode("UTF-8", :invalid => :replace, :replace => "")
  end

  def government?
    require 'gman'
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
    response && response.effective_url && !!response.effective_url.match(/^https?:\/\/www\./)
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

  def http
    details = {
      endpoints: endpoints
    }

    # convenient shorthand for the extensive statements to come
    combos = details[:endpoints]

    # A domain is "canonically" at www if:
    #  * at least one of its www endpoints responds
    #  * both root endpoints are either down or redirect *somewhere*
    #  * either both root endpoints are down, *or* at least one
    #    root endpoint redirect should immediately go to
    #    an *internal* www endpoint
    # This is meant to affirm situations like:
    #   http:// -> https:// -> https://www
    #   https:// -> http:// -> https://www
    # and meant to avoid affirming situations like:
    #   http:// -> http://non-www,
    #   http://www -> http://non-www
    # or like:
    #   https:// -> 200, http:// -> http://www

    www = !!(
      (
        combos[:https][:www][:up] or
        combos[:http][:www][:up]
      ) and (
        (
          combos[:https][:root][:redirect] or
          !combos[:https][:root][:up] or
          combos[:https][:root][:https_bad_name] or
          !combos[:https][:root][:status].to_s.start_with?("2")
        ) and (
          combos[:http][:root][:redirect] or
          !combos[:http][:root][:up] or
          !combos[:http][:root][:status].to_s.start_with?("2")
        )
      ) and (
        (
          (
            !combos[:https][:root][:up] or
            combos[:https][:root][:https_bad_name] or
            !combos[:https][:root][:status].to_s.start_with?("2")
          ) and
          (
            !combos[:http][:root][:up] or
            !combos[:http][:root][:status].to_s.start_with?("2")
          )
        ) or
        (
          combos[:https][:root][:redirect_immediately_to_www] and
          !combos[:https][:root][:redirect_immediately_external]
        ) or
        (
          combos[:http][:root][:redirect_immediately_to_www] and
          !combos[:http][:root][:redirect_immediately_external]
        )
      )
    )

    # A domain is "canonically" at https if:
    #  * at least one of its https endpoints is live and
    #    doesn't have an invalid hostname
    #  * both http endpoints are either down or redirect *somewhere*
    #  * at least one http endpoint redirects immediately to
    #    an *internal* https endpoint
    # This is meant to affirm situations like:
    #   http:// -> http://www -> https://
    #   https:// -> http:// -> https://www
    # and meant to avoid affirming situations like:
    #   http:// -> http://non-www
    #   http://www -> http://non-www
    # or:
    #   http:// -> 200, http://www -> https://www
    #
    # It allows a site to be canonically HTTPS if the cert has
    # a valid hostname but invalid chain issues.

    https = !!(
      (
        (
          combos[:https][:root][:up] and
          !combos[:https][:root][:https_bad_name]
        ) or
        (
          combos[:https][:www][:up] and
          !combos[:https][:www][:https_bad_name]
        )
      ) and (
        (
          combos[:http][:root][:redirect] or
          !combos[:http][:root][:up] or
          !combos[:http][:root][:status].to_s.start_with?("2")
        ) and (
          combos[:http][:www][:redirect] or
          !combos[:http][:www][:up] or
          !combos[:http][:www][:status].to_s.start_with?("2")
        )
      ) and (
        (
          combos[:http][:root][:redirect_immediately_to_https] and
          !combos[:http][:root][:redirect_immediately_external]
        ) or (
          combos[:http][:www][:redirect_immediately_to_https] and
          !combos[:http][:www][:redirect_immediately_external]
        )
      )
    )

    details[:canonical_endpoint] = www ? :www : :root
    details[:canonical_protocol] = https ? :https : :http
    details[:canonical] = uri(https, www).to_s

    # If any endpoint is up, the domain is up.
    details[:up] = !!(
      combos[:https][:www][:up] or
      combos[:https][:root][:up] or
      combos[:http][:www][:up] or
      combos[:http][:root][:up]
    )

    # A domain's root is broken if neither protocol can connect.
    details[:broken_root] = !!(
      !combos[:https][:root][:up] and
      !combos[:http][:root][:up]
    )

    # A domain's www is broken if neither protocol can connect.
    details[:broken_www] = !!(
      !combos[:https][:www][:up] and
      !combos[:http][:www][:up]
    )

    # HTTPS is "supported" (different than "canonical" or "enforced") if:
    #
    # * Either of the HTTPS endpoints is listening, and doesn't have
    #   an invalid hostname.
    details[:support_https] = !!(
      (
        (combos[:https][:root][:status] != 0) and
        !combos[:https][:root][:https_bad_name]
      ) or (
        (combos[:https][:www][:status] != 0) and
        !combos[:https][:www][:https_bad_name]
      )
    )

    # we can say that a canonical HTTPS site "defaults" to HTTPS,
    # even if it doesn't *strictly* enforce it (e.g. having a www
    # subdomain first to go HTTP root before HTTPS root).
    details[:default_https] = https

    # HTTPS is "downgraded" if both:
    #
    # * HTTPS is supported, and
    # * The 'canonical' endpoint gets an immediate internal redirect to HTTP.

    details[:downgrade_https] = !!(
      details[:support_https] and
      (
        combos[:https][details[:canonical_endpoint]][:redirect] and
        !combos[:https][details[:canonical_endpoint]][:redirect_immediately_external] and
        !combos[:https][details[:canonical_endpoint]][:redirect_immediately_to_https]
      )
    )

    # HTTPS is enforced if one of the HTTPS endpoints is "live",
    # and if both *HTTP* endpoints are either:
    #
    #  * down, or
    #  * redirect immediately to HTTPS.
    #
    # This is different than whether a domain is "canonically" HTTPS.
    #
    # * an HTTP redirect can go to HTTPS on another domain, as long
    #   as it's immediate.
    # * a domain with an invalid cert can still be enforcing HTTPS.
    details[:enforce_https] = !!(
      (
        !combos[:http][:www][:up] or
        (combos[:http][:www][:redirect_immediately_to_https])
      ) and
      (
        !combos[:http][:root][:up] or
        (combos[:http][:root][:redirect_immediately_to_https])
      ) and
      (
        combos[:https][:www][:up] or
        combos[:https][:root][:up]
      )
    )

    # The domain is a redirect if at least one endpoint is up,
    # and each one is *either* an external redirect or down entirely.
    details[:redirect] = !!(
      details[:up] and
      (
        combos[:http][:www][:redirect_external] or
        !combos[:http][:www][:up] or
        combos[:http][:www][:status] >= 400
      ) and
      (
        combos[:http][:root][:redirect_external] or
        !combos[:http][:root][:up] or
        combos[:http][:root][:status] >= 400
      ) and
      (
        combos[:https][:www][:redirect_external] or
        !combos[:https][:www][:up] or
        combos[:https][:www][:https_bad_name] or
        combos[:https][:www][:status] >= 400
      ) and
      (
        combos[:https][:root][:redirect_external] or
        !combos[:https][:root][:up] or
        combos[:https][:root][:https_bad_name] or
        combos[:https][:root][:status] >= 400
      )
    )

    # OK, we've said a domain is a "redirect" domain.
    # What does the domain redirect to?
    if details[:redirect]
      canon = combos[details[:canonical_protocol]][details[:canonical_endpoint]]
      details[:redirect_to] = canon[:redirect_to]
    else
      details[:redirect_to] = nil
    end

    # HSTS on the canonical domain? (valid HTTPS checked in endpoint)
    details[:hsts] = !!combos[:https][details[:canonical_endpoint]][:hsts]
    details[:hsts_header] = combos[:https][details[:canonical_endpoint]][:hsts_header]

    # HSTS on the entire domain?
    details[:hsts_entire_domain] = !!(
      combos[:https][:root][:hsts] and
      combos[:https][:root][:hsts_header].downcase.include?("includesubdomains")
    )

    # HSTS preload-ready?
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
        details[:https_bad_chain] = false
        details[:https_bad_name] = false

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

      # not sure what else would happen
      elsif response.response_code != 0
        details[:https_valid] = false
        details[:https_unknown_issue] = response.return_code
      end
    end

    # If we ended up with a failure, return it.
    details[:status] = response.response_code
    details[:up] = (response.response_code != 0)
    return details if !details[:up]

    headers = Hash[response.headers.map{ |k,v| [k.downcase,v] }]
    details[:headers] = headers


    # HSTS only takes effect when delivered over valid HTTPS, and
    # when the max-age is > 0. max-age=0 disables HSTS.
    details[:hsts] = !!(
      ssl and
      details[:https_valid] and
      headers["strict-transport-security"] and
      !(headers["strict-transport-security"] =~ /max-age=0\b/)
    )

    details[:hsts_header] = headers["strict-transport-security"]


    # If it's a redirect, go find the ultimate response starting from this combo.
    redirect_code = response.response_code.to_s.start_with?("3")
    location_header = headers["location"]
    if redirect_code and location_header
      location_header = location_header.downcase
      details[:redirect] = true

      ultimate_response = request(ssl, www, true, !details[:https_bad_chain], !details[:https_bad_name])
      uri_original = URI(ultimate_response.request.url)

      # treat relative Location headers as having the original hostname
      if location_header.start_with?("http:") or location_header.start_with?("https:")
        uri_immediate = URI(URI.escape(location_header))
      else
        uri_immediate = URI.join(uri_original, URI.escape(location_header))
      end

      uri_eventual = URI(ultimate_response.effective_url.downcase)

      # compare base domain names
      base_original = PublicSuffix.parse(uri_original.hostname).domain

      # if the redirects aren't to valid hostnames (e.g. IP addresses)
      # then fine just compare them directly, they're not going to be
      # identical anyway.
      base_immediate = begin
        PublicSuffix.parse(uri_immediate.hostname).domain
      rescue PublicSuffix::DomainInvalid
        uri_immediate.to_s
      end

      base_eventual = begin
        PublicSuffix.parse(uri_eventual.hostname).domain
      rescue PublicSuffix::DomainInvalid
        uri_eventual.to_s
      end

      details[:redirect_immediately_to] = uri_immediate.to_s
      details[:redirect_immediately_to_www] = !!uri_immediate.to_s.match(/^https?:\/\/www\./)
      details[:redirect_immediately_to_https] = uri_immediate.to_s.start_with?("https://")
      details[:redirect_immediately_external] = (base_original != base_immediate)

      details[:redirect_to] = uri_eventual.to_s
      details[:redirect_external] = (base_original != base_eventual)

    # otherwise, mark all the redirect fields as false/null
    else
      details[:redirect] = false
      details[:redirect_immediately_to] = nil
      details[:redirect_immediately_to_www] = false
      details[:redirect_immediately_to_https] = false
      details[:redirect_immediately_external] = false

      details[:redirect_to] = nil
      details[:redirect_external] = false
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
      init! # load non-HTTP dependencies

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
