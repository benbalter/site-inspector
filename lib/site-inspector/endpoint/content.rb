# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Content < Check
      PATHS = [
        'robots.txt', 'sitemap.xml', 'humans.txt', 'vulnerability-disclosure-policy', 'security.txt', '.well-known/security.txt', 'data.json'
      ].freeze

      class << self
        def paths
          @paths ||= PATHS.to_h { |p| [key_for(p), p] }
        end

        def path_for(key)
          paths[key]
        end

        def key_for(path)
          path.gsub(/(\.|-)/, '_').to_sym
        end
      end

      # Given a path (e.g, "/data"), check if the given path exists on the canonical endpoint
      def path_exists?(path)
        return unless proper_404s?

        @exists ||= {}
        @exists[path] ||= endpoint.up? && endpoint.request(path:, followlocation: true).success?
      rescue URI::InvalidURIError
        false
      end

      # The default Check#response method is from a HEAD request
      # The content check has a special response which includes the body from a GET request
      def response
        @response ||= endpoint.request(method: :get, followlocation: true)
      end

      def document
        require 'nokogiri'
        @doc ||= Nokogiri::HTML response.body if response
      end
      alias doc document

      def body
        @body ||= document.to_s.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, replace: '')
      end

      def method_missing(method_sym, *arguments, &)
        key = method_sym.to_s.gsub(/\?$/, '').to_sym
        if respond_to_missing?(key)
          path = self.class.paths[key]
          path_exists?(path)
        else
          super
        end
      end

      def respond_to_missing?(method_sym, include_private = false)
        if self.class.paths.key?(method_sym)
          true
        else
          super
        end
      end

      def security_txt?
        @security_txt ||= if proper_404s?
                            path_exists?('security.txt') || path_exists?('./well-known/security.txt')
                          else
                            false
                          end
      end

      def uri_for(key)
        return nil unless self.class.paths.key?(key)

        endpoint.join(self.class.paths[key]) if proper_404s?
      end

      def doctype
        document.internal_subset.external_id
      end

      def generator
        @generator ||= begin
          tag = document.at('meta[name="generator"]')
          tag['content'] if tag
        end
      end

      def prefetch
        return unless endpoint.up?

        paths = self.class.paths.values.concat(random_paths)
        paths.each do |path|
          request = endpoint.build_request(path:, followlocation: true)
          SiteInspector.hydra.queue(request)
        end

        # Request for content is a GET, not a HEAD request
        request = endpoint.build_request(method: :get, followlocation: true)
        SiteInspector.hydra.queue(request)

        SiteInspector.hydra.run
      end

      def proper_404s?
        @proper_404s ||= begin
          return unless endpoint.up?

          random_paths.all? do |random_path|
            endpoint.request(path: random_path, followlocation: true).code == 404
          end
        end
      end

      def to_h
        return {} unless endpoint.up?
        return {} if endpoint.redirect?
        return @hash if defined?(@hash)

        prefetch
        @hash = {
          doctype:,
          generator:,
          proper_404s: proper_404s?
        }

        self.class.paths.each do |key, _path|
          @hash[key] = send(key) unless key.to_s.start_with?('_')
        end

        @hash[:security_txt] = security_txt?
        @hash
      end

      private

      def random_paths
        require 'securerandom'
        @random_paths ||= [
          SecureRandom.hex,
          "#{SecureRandom.hex}.html",
          "#{SecureRandom.hex}.json"
        ]
      end
    end
  end
end
