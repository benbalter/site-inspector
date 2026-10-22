# frozen_string_literal: true

class SiteInspector
  class Endpoint
    # Utility parser for HSTS headers.
    # RFC: http://tools.ietf.org/html/rfc6797
    class Hsts < Check
      STATUS_ENDPOINT = 'https://hstspreload.org/api/v2/status'

      # Minimum max-age (one year) required by the HSTS preload list,
      # see https://hstspreload.org/#submission-requirements
      PRELOAD_MIN_MAX_AGE = 31_536_000

      def valid?
        return false if header.empty?
        return false unless pairs.none? { |key, value| "#{key}#{value}" =~ /[\s'"]/ }

        valid_max_age?
      end

      def max_age
        pairs[:'max-age'].to_i
      end

      def include_subdomains?
        pairs.key?(:includesubdomains)
      end

      def preload?
        pairs.key?(:preload)
      end

      def enabled?
        return false unless max_age

        max_age.positive?
      end

      # Whether the header meets the HSTS preload list's requirements
      # (includeSubDomains, preload, and a max-age of at least one year)
      def preload_ready?
        include_subdomains? && preload? && max_age >= PRELOAD_MIN_MAX_AGE
      end

      def to_h
        {
          valid: valid?,
          max_age:,
          include_subdomains: include_subdomains?,
          preload: preload?,
          enabled: enabled?,
          preload_ready: preload_ready?,
          preload_list_status: preload_list['status']
        }
      end

      private

      # RFC 6797 §6.1.1 requires a max-age directive whose value is a
      # non-negative integer (optionally quoted, already unquoted in #pairs).
      def valid_max_age?
        value = pairs[:'max-age']
        !value.nil? && /\A\d+\z/.match?(value)
      end

      def headers
        endpoint.headers
      end

      def header
        @header ||= [headers['strict-transport-security']].flatten.join('; ').squeeze(';')
      end

      def directives
        @directives ||= header ? header.split(/\s*;\s*/) : []
      end

      def pairs
        @pairs ||= begin
          pairs = {}
          directives.each do |directive|
            key, value = directive.downcase.split('=')

            if /".*"/.match?(value)
              value = value.sub(/^"/, '')
              value = value.sub(/"$/, '')
            end

            pairs[key.to_sym] = value
          end

          pairs
        end
      end

      def request
        @request ||= begin
          options = SiteInspector.typhoeus_defaults
          options = options.merge(method: :get)
          Typhoeus::Request.new(url, options)
        end
      end

      def url
        url = Addressable::URI.parse(STATUS_ENDPOINT)
        url.query_values = { domain: endpoint.host.to_s }
        url
      end

      def preload_list
        @preload_list ||= begin
          SiteInspector.hydra.queue(request)
          SiteInspector.hydra.run

          response = request.response
          if response.success?
            JSON.parse(response.body)
          else
            {}
          end
        end
      end
    end
  end
end
