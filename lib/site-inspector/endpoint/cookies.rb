# frozen_string_literal: true

require 'http-cookie'

class SiteInspector
  class Endpoint
    class Cookies < Check
      def any?(&block)
        if cookie_header.nil? || cookie_header.empty?
          false
        elsif block
          all.any?(&block)
        else
          true
        end
      end
      alias cookies? any?

      # Returns an array of HTTP::Cookie objects parsed from the Set-Cookie headers
      def all
        @cookies ||= cookie_header.flat_map { |c| HTTP::Cookie.parse(c, endpoint.uri.to_s) } if cookies?
      end

      def [](key)
        all.find { |cookie| cookie.name == key } if cookies?
      end

      # Does at least one cookie set both the Secure and HttpOnly flags?
      def secure?
        return false unless cookies?

        all.any? { |cookie| cookie.secure? && cookie.httponly? }
      end

      def to_h
        return {} unless endpoint.up?
        return {} if endpoint.redirect?

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
