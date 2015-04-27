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

      # Returns an array of hashes of downcased key/value header pairs (or an empty hash)
      def all
        @all ||= response ? Hash[response.headers.map{ |k,v| [k.downcase,v] }] : {}
      end
      alias_method :headers, :all

      def [](header)
        headers[header]
      end

      def to_h
        {
          :cookies => cookies?,
          :strict_transport_security => strict_transport_security,
          :content_security_policy => content_security_policy,
          :click_jacking_protection => click_jacking_protection,
          :click_jacking_protection => click_jacking_protection,
          :server => server,
          :xss_protection => xss_protection,
          :secure_cookies => secure_cookies?
        }
      end
    end
  end
end
