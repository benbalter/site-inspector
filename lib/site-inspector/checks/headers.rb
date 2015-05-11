class SiteInspector
  class Endpoint
    class Headers < Check

      # cookies can have multiple set-cookie headers, so this detects
      # whether cookies are set, but not all their values.
      def cookies?
        !!headers["set-cookie"]
      end

      # TODO: kill this
      def strict_transport_security?
        !!strict_transport_security
      end

      def content_security_policy?
        !!content_security_policy
      end

      def click_jacking_protection?
        !!click_jacking_protection
      end

      # return the found header value

      # TODO: kill this
      def strict_transport_security
        headers["strict-transport-security"]
      end

      def content_security_policy
        headers["content-security-policy"]
      end

      def click_jacking_protection
        headers["x-frame-options"]
      end

      def server
        headers["server"]
      end

      def xss_protection
        headers["x-xss-protection"]
      end

      # more specific checks than presence of headers
      def xss_protection?
        xss_protection == "1; mode=block"
      end

      def secure_cookies?
        return false if !cookies?
        cookie = headers["set-cookie"]
        cookie = cookie.first if cookie.is_a?(Array)
        !!(cookie =~ /(; secure.*; httponly|; httponly.*; secure)/i)
      end


      def proper_404s?
        @proper_404s ||= begin
          require 'securerandom'
          endpoint.request(path: SecureRandom.hex, followlocation: true).response_code == 404
        end
      end

      # Returns an array of hashes of downcased key/value header pairs (or an empty hash)
      def all
        @all ||= (response && response.headers) ? Hash[response.headers.map{ |k,v| [k.downcase,v] }] : {}
      end
      alias_method :headers, :all

      def [](header)
        headers[header]
      end

      def to_h
        {
          :cookies => cookies?,
          :strict_transport_security => strict_transport_security || false,
          :content_security_policy => content_security_policy || false,
          :click_jacking_protection => click_jacking_protection || false,
          :click_jacking_protection => click_jacking_protection || false,
          :server => server,
          :xss_protection => xss_protection || false,
          :secure_cookies => secure_cookies?,
          :proper_404s => proper_404s?
        }
      end
    end
  end
end
