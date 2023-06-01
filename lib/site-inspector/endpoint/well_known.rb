# frozen_string_literal: true

require 'yaml'

class SiteInspector
  class Endpoint
    class WellKnown < Check
      BASE_PATH = './.well-known/'

      class << self
        def well_knowns
          data = File.expand_path '../../data/well-known.yml', File.dirname(__FILE__)
          wks = YAML.load_file(data)
          wks.reject { |wk| wk.include?('deprecated') }
        end

        def keys
          well_knowns.map { |wk| key_for(wk) }
        end

        def key_paths
          @key_paths ||= begin
            key_paths = well_knowns.map do |wk|
              [key_for(wk), path_for(wk)]
            end

            key_paths.to_h
          end
        end

        def path_for(wk)
          return unless well_knowns.include?(wk)

          "#{BASE_PATH}#{wk}"
        end

        def key_for(well_known)
          well_known.gsub(/(\.|-)/, '_').to_sym
        end
      end

      def exists?(path)
        endpoint.content.path_exists?(path)
      end

      def uri_for(key)
        path = self.class.key_paths[key]
        endpoint.join(path) if path
      end

      def to_h
        return {} unless endpoint.up?
        return {} if endpoint.redirect?
        return @hash if defined?(@hash)

        prefetch
        @hash = {}

        self.class.keys.each do |key|
          @hash[key] = public_send(key)
        end

        @hash
      end

      def method_missing(method_sym, *arguments, &)
        if respond_to_missing?(method_sym)
          exists?(self.class.key_paths[method_sym])
        else
          super
        end
      end

      def respond_to_missing?(method_sym, include_private = false)
        if self.class.keys.include?(method_sym)
          true
        else
          super
        end
      end

      private

      def prefetch
        options = SiteInspector.typhoeus_defaults.merge(followlocation: true)
        self.class.key_paths.each do |_key, path|
          uri = endpoint.join(path)
          request = Typhoeus::Request.new(uri, options)
          SiteInspector.hydra.queue(request)
        end
        SiteInspector.hydra.run
      end
    end
  end
end
