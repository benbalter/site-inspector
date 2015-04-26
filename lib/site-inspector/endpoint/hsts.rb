class SiteInspector
  class Endpoint
    # Utility parser for HSTS headers.
    # RFC: http://tools.ietf.org/html/rfc6797
    class Hsts < Check

      def valid?
        invalid_chars = /[\s\'\"]/
        pairs.none? do |name, value|
          (name =~ invalid_chars) or (value =~ invalid_chars)
        end
      end

      def max_age
        pairs[:"max-age"][1].to_i if pairs[:"max-age"]
      end

      def include_subdomains?
        !!pairs[:includesubdomains]
      end

      def preload?
        !!pairs[:preload]
      end

      def [](key)
        pairs[key]
      end

      def enabled?
        return false unless max_age
        max_age > 0
      end

      # Google's minimum max-age for automatic preloading
      def preload_ready?
        return false unless include_subdomains? and preload?
        return false unless max_age
        max_age >= 10886400
      end

      def to_h
        {
          max_age: max_age,
          include_subdomains: include_subdomains?,
          preload: preload?,
          enabled: enabled?,
          preload_ready: preaload_ready?
        }
      end

      private

      def headers
        @headers ||= Header.new(response)
      end

      def header
        @header ||= headers["strict-transport-security"]
      end

      def directives
        @directives ||= header.split(/\s*;\s*/)
      end

      def pairs
        @pairs ||= begin
          pairs = {}
          directives.each do |directive|
            key, value = directive.downcase.split("=")

            if value and value.start_with?("\"") and value.end_with?("\"")
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
