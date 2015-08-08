class SiteInspector
  class Domain

    attr_reader :host

    def initialize(host)
      host = host.downcase
      host = host.sub /^https?\:/, ""
      host = host.sub /^\/+/, ""
      host = host.sub /^www\./, ""
      uri = Addressable::URI.parse "//#{host}"
      @host = uri.host
    end

    def endpoints
      @endpoints ||= [
        Endpoint.new("https://#{host}"),
        Endpoint.new("https://www.#{host}"),
        Endpoint.new("http://#{host}"),
        Endpoint.new("http://www.#{host}")
      ]
    end

    def canonical_endpoint
      @canonical_endpoint ||= endpoints.find do |e|
        e.https? == canonically_https? && e.www? == canonically_www?
      end
    end

    def government?
      require 'gman'
      Gman.valid? host
    end

    # Does *any* endpoint return a 200 or 300 response code?
    def up?
      endpoints.any? { |e| e.up? }
    end

    # Does *any* endpoint respond to HTTP?
    # TODO: needs to allow an invalid chain.
    def responds?
      endpoints.any? { |e| e.responds? }
    end


    # TODO: These weren't present before, and may not be useful.
    # Can you connect to www?
    def www?
      endpoints.any? { |e| e.www? && e.up? }
    end

    # Can you connect without www?
    def root?
      endpoints.any? { |e| e.root? && e.up? }
    end

    # HTTPS is "supported" (different than "canonical" or "enforced") if:
    #
    # * Either of the HTTPS endpoints is listening, and doesn't have
    #   an invalid hostname.
    #
    # TODO: needs to allow an invalid chain.
    def https?
      endpoints.any? { |e| e.https? && e.up? && e.https.valid? }
    end

    # HTTPS is enforced if one of the HTTPS endpoints is "up",
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
    #
    # TODO: need to ensure the redirect *immediately* goes to HTTPS.
    # TODO: don't need to require that the HTTPS cert is valid for this purpose.
    def enforces_https?
      return false unless https?
      endpoints.select { |e| e.http? }.all? { |e| !e.up? || (e.redirect && e.redirect.https?) }
    end

    # we can say that a canonical HTTPS site "defaults" to HTTPS,
    # even if it doesn't *strictly* enforce it (e.g. having a www
    # subdomain first to go HTTP root before HTTPS root).
    #
    # TODO: not implemented.
    def defaults_https?
      raise "Not implemented. Halp?"
    end

    # HTTPS is "downgraded" if both:
    #
    # * HTTPS is supported, and
    # * The 'canonical' endpoint gets an immediate internal redirect to HTTP.
    #
    # TODO: the redirect must be internal.
    def downgrades_https?
      return false unless https?
      canonical_endpoint.redirect? && canonical_endpoint.redirect.http?
    end

    # A domain is "canonically" at www if:
    #  * at least one of its www endpoints responds
    #  * both root endpoints are either down ~~or redirect *somewhere*~~, or
    #  * at least one root endpoint redirect should immediately go to
    #    an *internal* www endpoint
    # This is meant to affirm situations like:
    #   http:// -> https:// -> https://www
    #   https:// -> http:// -> https://www
    # and meant to avoid affirming situations like:
    #   http:// -> http://non-www,
    #   http://www -> http://non-www
    # or like:
    #   https:// -> 200, http:// -> http://www
    def canonically_www?
      # Does any endpoint respond?
      return false unless up?

      # Does at least one www endpoint respond?
      return false unless www?

      # Are both root endpoints down?
      return true if endpoints.select { |e| e.root? }.all? { |e| !e.up? }

      # Does either root endpoint redirect to a www endpoint?
      endpoints.select { |e| e.root? }.any? { |e| e.redirect && e.redirect.www? }
    end

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
    def canonically_https?
      # Does any endpoint respond?
      return false unless up?

      # At least one of its https endpoints is live and doesn't have an invalid hostname
      return false unless https?

      # Both http endpoints are down
      return true if endpoints.select { |e| e.http? }.all? { |e| !e.up? }

      # at least one http endpoint redirects immediately to https
      endpoints.select { |e| e.http? }.any? { |e| e.redirect && e.redirect.https? }
    end

    # A domain redirects if
    # 1. At least one endpoint is an external redirect, and
    # 2. All endpoints are either down or an external redirect
    def redirect?
      return false unless redirect
      endpoints.all? { |e| !e.up? || e.external_redirect? }
    end

    # The first endpoint to respond with a redirect
    def redirect
      endpoints.find { |e| e.external_redirect? }
    end

    # HSTS on the canonical domain?
    def hsts?
      canonical_endpoint.hsts && canonical_endpoint.hsts.enabled?
    end

    def hsts_subdomains?
      endpoints.find { |e| e.root? && e.https? }.hsts.include_subdomains?
    end

    def hsts_preload_ready?
      return false unless hsts_subdomains?
      endpoints.find { |e| e.root? && e.https? }.hsts.preload_ready?
    end

    def to_s
      host
    end

    def inspect
      "#<SiteInspector::Domain host=\"#{host}\">"
    end

    # We know most API calls to the domain model are going to require
    # That the root of all four endpoints are called. Rather than process them
    # In serial, lets grab them in parallel and cache the results to speed
    # up later calls.
    def prefetch
      endpoints.each do |endpoint|
        request = Typhoeus::Request.new(endpoint.uri, SiteInspector.typhoeus_defaults)
        SiteInspector.hydra.queue(request)
      end
      SiteInspector.hydra.run
    end

    # Converts the domain to a hash
    #
    # By default, it only returns domain-wide information and
    # information about the canonical endpoint
    #
    # It will also pass options allong to each endpoint's to_h method
    #
    # options:
    #  :all - return information about all endpoints
    #
    # Returns a complete hash of the domain's information
    def to_h(options={})
      prefetch

      hash = {
        host:               host,
        up:                 up?,
        responds:           responds?,
        www:                www?,
        root:               root?,
        https:              https?,
        enforces_https:     enforces_https?,
        downgrades_https:   downgrades_https?,
        canonically_www:    canonically_www?,
        canonically_https:  canonically_https?,
        redirect:           redirect?,
        hsts:               hsts?,
        hsts_subdomains:    hsts_subdomains?,
        hsts_preload_ready: hsts_preload_ready?,
        canonical_endpoint: canonical_endpoint.to_h(options)
      }

      if options["all"]
        hash.merge!({
          endpoints: {
            https: {
              root: endpoints[0].to_h(options),
              www:  endpoints[1].to_h(options)
            },
            http: {
              root: endpoints[2].to_h(options),
              www:  endpoints[3].to_h(options)
            }
          }
        })
      end

      hash
    end

    def to_json
      to_h.to_json
    end
  end
end
