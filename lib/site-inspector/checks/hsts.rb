class SiteInspector
  class Endpoint
    # Utility parser for HSTS headers.
    # RFC: http://tools.ietf.org/html/rfc6797
    class Hsts < Check

      def valid?
        pairs.none? { |key, value| "#{key}#{value}" =~ /[\s\'\"]/ }
      end

      def max_age
        pairs[:"max-age"].to_i
      end

      def include_subdomains?
        pairs.keys.include? :includesubdomains
      end

      def preload?
        pairs.keys.include? :preload
      end

      def enabled?
        return false unless max_age
        max_age > 0
      end

      # Google's minimum max-age for automatic preloading
      def preload_ready?
        include_subdomains? and preload? and max_age >= 10886400
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
        @headers ||= SiteInspector::Endpoint::Headers.new(response)
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

            if value =~ /\".*\"/
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
