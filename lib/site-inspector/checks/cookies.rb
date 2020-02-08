# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Cookies < Check
      def any?
        if cookie_header.nil? || cookie_header.empty?
          false
        elsif block_given?
          all.any? { |cookie| yield(cookie) }
        else
          true
        end
      end
      alias cookies? any?

      def all
        @cookies ||= cookie_header.map { |c| CGI::Cookie.parse(c) } if cookies?
      end

      def [](key)
        all.find { |cookie| cookie.keys.first == key } if cookies?
      end

      def secure?
        pairs = cookie_header.join('; ').split('; ') # CGI::Cookies#Parse doesn't seem to like secure headers
        pairs.any? { |c| c.casecmp('secure').zero? } && pairs.any? { |c| c.casecmp('httponly').zero? }
      end

      def to_h
        {
          cookie?: any?,
          secure?: secure?
        }
      end

      private

      def cookie_header
        # Cookie header may be an array or string, always return an array
        [endpoint.headers.all['set-cookie']].flatten.compact
      end
    end
  end
end
