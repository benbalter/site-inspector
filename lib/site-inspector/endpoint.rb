# frozen_string_literal: true

require 'site-inspector/endpoint/check'
require 'site-inspector/endpoint/accessibility'
require 'site-inspector/endpoint/content'
require 'site-inspector/endpoint/dns'
require 'site-inspector/endpoint/headers'
require 'site-inspector/endpoint/hsts'
require 'site-inspector/endpoint/https'
require 'site-inspector/endpoint/sniffer'
require 'site-inspector/endpoint/cookies'
require 'site-inspector/endpoint/well_known'
require 'site-inspector/endpoint/whois'
require 'site-inspector/endpoint/wappalyzer'

class SiteInspector
  # Every domain has four possible "endpoints" to evaluate
  #
  # For example, if you had `example.com` you'd have:
  #   1. `http://example.com`
  #   2. `http://www.example.com`
  #   3. `https://example.com`
  #   4. `https://www.example.com`
  #
  # Because each of the four endpoints could potentially respond differently
  # We must evaluate all four to make certain determination
  class Endpoint
    attr_accessor :host, :uri, :domain

    def self.build(domain, https: true, www: false)
      uri = Addressable::URI.new
      uri.host = www ? "www.#{domain.host}" : domain.host.to_s
      uri.scheme = https ? 'https' : 'http'

      new(uri.to_s, domain: domain)
    end

    # Initatiate a new Endpoint object
    #
    # endpoint - (string) the endpoint to query (e.g., `https://example.com`)
    # options  - A hash of options
    #   domain - the parent domain object, if passed, facilitates caching of redirects
    def initialize(host, options = {})
      host = host.downcase if host.is_a?(String)
      @uri = Addressable::URI.parse(host)
      # The root URL always has an implict path of "/", even if not requested
      # Make it explicit to facilitate caching and prevent a potential redirect
      @uri.path = '/'
      @host = DomainParser.parse(host)
      @checks = {}
      @domain = options[:domain]
    end

    def www?
      @host.trd == 'www'
    end

    def root?
      !www?
    end

    def https?
      https.scheme?
    end

    def http?
      !https?
    end

    def scheme
      @uri.scheme
    end

    def request(options = {})
      target = options[:path] ? join(options.delete(:path)) : uri
      request = Typhoeus::Request.new(target, SiteInspector.typhoeus_defaults.merge(options))
      hydra.queue(request)
      hydra.run
      request.response
    end

    def join(*args)
      URI.join(uri, *args)
    end

    # Makes a GET request of the given host
    #
    # Retutns the Typhoeus::Response object
    def response
      @response ||= request
    end

    def response_code
      response.response_code.to_s if response
    end

    def timed_out?
      response&.timed_out?
    end

    # Does the endpoint return a 2xx or 3xx response code?
    def up?
      response && response_code.start_with?('2') || response_code.start_with?('3')
    end

    # Does the server respond at all?
    def responds?
      response.code != 0 && !timed_out?
    end

    # If the domain is a redirect, what's the first endpoint we're redirected to?
    def redirect
      return unless response && response_code.start_with?('3')

      @redirect ||= begin
        redirect = Addressable::URI.parse(headers['location'])

        # This is a relative redirect, but we still need the absolute URI
        if redirect.relative?
          redirect.path = "/#{redirect.path}" unless redirect.path[0] == '/'
          redirect.host = host.to_s
          redirect.scheme = scheme
        end

        # This was a redirect to a subpath or back to itself, which we don't care about
        return if redirect.host == host.to_s && redirect.scheme == scheme

        # Init a new endpoint representing the redirect
        find_or_create_by_uri(redirect.to_s)
      end
    end

    # Does this endpoint return a redirect?
    def redirect?
      !!redirect
    end

    # What's the effective URL of a request to this domain?
    def resolves_to
      return self unless redirect?

      # If the redirect doesn't return a 30x response code, return the redirected endpoint
      # Otherwise, we'll need to go down the rabbit hole and see how deep it goes
      return redirect unless redirect.redirect?

      @resolves_to ||= begin
        response = request(followlocation: true)

        # Workaround for Webmock not playing nicely with Typhoeus redirects
        url = if response.mock?
                response.headers['Location'] || response.request.url
              else
                response.effective_url
              end

        find_or_create_by_uri(url)
      end
    end

    def external_redirect?
      host.to_s != resolves_to.host.to_s
    end

    def to_s
      uri.to_s
    end

    def inspect
      "#<SiteInspector::Endpoint uri=\"#{uri}\">"
    end

    # Returns information about the endpoint
    #
    # By default, all checks are run. If one or more check names are passed
    # in the options hash, only those checks will be run.
    #
    # options:
    #   a hash of check symbols and bools representing which checks should be run
    #
    # Returns the hash representing the endpoint and its checks
    def to_h(options = {})
      hash = {
        uri: uri.to_s,
        host: host.to_s,
        www: www?,
        https: https?,
        scheme: scheme,
        up: up?,
        responds: responds?,
        timed_out: timed_out?,
        redirect: redirect?,
        resolves_to: resolves_to.to_s,
        external_redirect: external_redirect?
      }

      # Either they've specifically asked for a check, or we throw everything at them
      checks = SiteInspector::Endpoint.checks.select { |c| options.key?(c.name) }
      checks = SiteInspector::Endpoint.checks if checks.empty?

      Parallel.each(checks, in_threads: 4) do |check|
        hash[check.name] = send(check.name).to_h
      end

      hash
    end

    def self.checks
      return @checks if defined? @checks

      @checks = ObjectSpace.each_object(Class).select { |klass| klass < Check }.select(&:enabled?).sort_by(&:name)
    end

    def method_missing(method_sym, *arguments, &block)
      check = SiteInspector::Endpoint.checks.find { |c| c.name == method_sym }
      if check
        @checks[method_sym] ||= check.new(self)
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_private = false)
      if checks.key?(method_sym)
        true
      else
        super
      end
    end

    def eql?(other)
      other.class == self.class && other.uri == uri
    end
    alias == eql?

    private

    def hydra
      SiteInspector.hydra
    end

    # In the event that a redirect is to one of the domain's four endpoints,
    # Try to return the existing endpoint, rather than create a new one
    def find_or_create_by_uri(uri)
      uri = Addressable::URI.parse(uri.downcase)
      cached_endpoint = domain.endpoints.find { |e| e.uri.to_s == uri.to_s } if domain
      cached_endpoint || Endpoint.new(uri.to_s)
    end
  end
end
