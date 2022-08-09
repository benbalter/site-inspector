# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Headers < Check
      COMMON = %w[
        strict-transport-security
        content-security-policy
        x-frame-options
        server
        x-xss-protection
      ].freeze

      COMMON.each do |header|
        name = header.gsub(/^x-/, '').tr('-', '_')

        define_method name do
          headers[header]
        end

        define_method "#{name}?" do
          !!headers[header]
        end
      end

      # more specific checks than presence of headers
      def xss_protection?
        xss_protection == '1; mode=block'
      end

      # Returns an array of hashes of downcased key/value header pairs (or an empty hash)
      def all
        @all ||= response&.headers ? response.headers.transform_keys(&:downcase) : {}
      end
      alias headers all

      def custom_headers
        @custom_headers ||= all.select do |header|
          header.start_with?('x-') && !COMMON.include?(header)
        end
      end

      def [](header)
        headers[header]
      end

      def to_h
        return {} if endpoint.redirect?

        hash = COMMON.to_h { |h| [h, headers[h] || false] }
        hash.merge custom_headers
      end
    end
  end
end
