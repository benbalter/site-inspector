# frozen_string_literal: true

class SiteInspector
  class Endpoint
    # Utility parser for HSTS headers.
    # RFC: http://tools.ietf.org/html/rfc6797
    class Hsts < Check
      STATUS_ENDPOINT = 'https://hstspreload.org/api/v2/status'

      def valid?
        return false unless header

        pairs.none? { |key, value| "#{key}#{value}" =~ /[\s'"]/ }
      end

      def max_age
        pairs[:"max-age"].to_i
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

      # Google's minimum max-age for automatic preloading
      def preload_ready?
        include_subdomains? && preload? && max_age >= 10_886_400
      end

      def to_h
        {
          valid: valid?,
          max_age: max_age,
          include_subdomains: include_subdomains?,
          preload: preload?,
          enabled: enabled?,
          preload_ready: preload_ready?,
          preload_list_status: preload_list['status']
        }
      end

      private

      def headers
        endpoint.headers
      end

      def header
        @header ||= headers['strict-transport-security']
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
