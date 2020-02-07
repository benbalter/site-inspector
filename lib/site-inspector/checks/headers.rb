# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Headers < Check
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
        headers['strict-transport-security']
      end

      def content_security_policy
        headers['content-security-policy']
      end

      def click_jacking_protection
        headers['x-frame-options']
      end

      def server
        headers['server']
      end

      def xss_protection
        headers['x-xss-protection']
      end

      # more specific checks than presence of headers
      def xss_protection?
        xss_protection == '1; mode=block'
      end

      # Returns an array of hashes of downcased key/value header pairs (or an empty hash)
      def all
        @all ||= response&.headers ? Hash[response.headers.map { |k, v| [k.downcase, v] }] : {}
      end
      alias headers all

      def [](header)
        headers[header]
      end

      def to_h
        {
          strict_transport_security: strict_transport_security || false,
          content_security_policy: content_security_policy || false,
          click_jacking_protection: click_jacking_protection || false,
          server: server,
          xss_protection: xss_protection || false
        }
      end
    end
  end
end
