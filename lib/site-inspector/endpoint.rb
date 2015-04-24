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
    attr_accessor :host, :uri

    # Initatiate a new Endpoint object
    #
    # endpoint - (string) the endpoint to query (e.g., `https://example.com`)
    def initialize(host)
      @uri = Addressable::URI.parse(host.downcase)
      @host = uri.host.sub(/^www\./, "")
    end

    def www?
      !!(uri.host =~ /^www\./)
    end

    def root?
      !www?
    end

    def https?
      @uri.scheme == "https"
    end

    def http?
      !https?
    end

    def scheme
      @uri.scheme
    end

    def request(options = {})
      Typhoeus.get(uri, SiteInspector.typhoeus_defaults.merge(options))
    end

    # Makes a GET request of the given host
    #
    # Retutns the Typhoeus::Response object
    def response
      @response ||= request
    end

    # Does the server return any response? (including 50x)
    def response?
      !!response
    end

    # Does the endpoint return a 2xx or 3xx response code?
    def up?
      response && response_code.start_with?("2") || response_code.start_with?("3")
    end

    def down?
      !up?
    end

    def response_code
      response.response_code.to_s if response
    end

    def timed_out?
      response && response.timed_out?
    end

    def https_valid?
      https? && response && response.return_code == :ok
    end

    def https_bad_chain?
      https? && response && response.return_code == :ssl_cacert
    end

    def https_bad_name?
      https? && response && response.return_code == :peer_failed_verification
    end

    def hsts
      @hsts ||= SiteInspector::Endpoint::Hsts.new(headers["strict-transport-security"]) if https_valid?
    end

    # If the domain is a redirect, what's the first endpoint we're redirected to?
    def redirect
      return unless response && response_code.start_with?("3")

      @redirect ||= begin
        redirect = Addressable::URI.parse(headers["location"])

        # This is a relative redirect, but we still need the absolute URI
        if redirect.relative?
          redirect.host = host
          redirect.scheme = scheme
        end

        # This was a redirect to a subpath or back to itself, which we don't care about
        return if redirect.host == host && redirect.scheme == scheme

        # Init a new endpoint representing the redirect
        Endpoint.new(redirect.to_s)
      end
    end

    # Does this endpoint return a redirect?
    def redirect?
      !!redirect
    end

    # What's the effective URL of a request to this domain?
    def resolves_to
      return self unless redirect?
      @resolves_to ||= begin
        url = request(:followlocation => true).effective_url
        Endpoint.new(url)
      end
    end

    def external_redirect?
      uri != resolves_to.uri
    end

    def dns
      @dns ||= Dns.new(uri.host)
    end

    def sniffer
      @sniffer ||= Sniffer.new(response)
    end

    def headers
      @headers ||= Headers.new(response)
    end

    def to_s
      uri.to_s
    end

    def inspect
      "#<SiteInspector::Endpoint uri=\"#{uri.to_s}\">"
    end
  end
end
