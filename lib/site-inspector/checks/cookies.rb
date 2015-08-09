class SiteInspector
  class Endpoint
    class Cookies < Check

      def any?(&block)
        if cookie_header.nil? || cookie_header.empty?
          false
        elsif block_given?
          all.any? { |cookie| block.call(cookie) }
        else
          true
        end
      end
      alias_method :cookies?, :any?

      def all
        @cookies ||= cookie_header.map { |c| CGI::Cookie::parse(c) } if cookies?
      end

      def [](key)
        all.find { |cookie| cookie.keys.first == key } if cookies?
      end

      def secure?
        pairs = cookie_header.join("; ").split("; ") # CGI::Cookies#Parse doesn't seem to like secure headers
        pairs.any? { |c| c.downcase == "secure" } && pairs.any? { |c| c.downcase == "httponly" }
      end

      def to_h
        {
          :cookie? => any?,
          :secure? => secure?
        }
      end

      private

      def cookie_header
        endpoint.headers.all["set-cookie"]
      end

    end
  end
end
