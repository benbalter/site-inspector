# frozen_string_literal: true

class SiteInspector
  class Endpoint
    # Utility parser for HSTS headers.
    # RFC: http://tools.ietf.org/html/rfc6797
    class Hsts < Check
      def valid?
        return false unless header

        pairs.none? { |key, value| "#{key}#{value}" =~ /[\s\'\"]/ }
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
          preload_ready: preload_ready?
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

            if /\".*\"/.match?(value)
              value = value.sub(/^\"/, '')
              value = value.sub(/\"$/, '')
            end

            pairs[key.to_sym] = value
          end

          pairs
        end
      end
    end
  end
end
