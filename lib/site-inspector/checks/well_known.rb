# frozen_string_literal: true

require 'yaml'

class SiteInspector
  class Endpoint
    class WellKnown < Check
      BASE_PATH = './.well-known/'

      class << self
        def well_knowns
          @well_knowns ||= begin
            data = File.expand_path '../../data/well-known.yml', File.dirname(__FILE__)
            wks = YAML.load_file(data)
            wks = wks.reject { |wk| wk.include?('deprecated') }

            wks = wks.map do |wk|
              [key_for(wk), path_for(wk)]
            end

            wks.to_h
          end
        end

        def path_for(well_known)
          return unless well_knowns.key?(well_known)

          "#{BASE_PATH}#{well_knowns[well_known]}"
        end

        def key_for(well_known)
          well_known.gsub(/(\.|-)/, '_').to_sym
        end
      end

      def exists?(path)
        @exists ||= {}
        @exists[path] ||= endpoint.content.path_exists?(path)
      end

      def uri_for(well_known)
        path = self.class.path_for(well_known)
        endpoint.join(path) if path
      end

      def to_h
        return @hash if defined?(@hash)

        prefetch
        @hash = {}

        self.class.well_knowns.each do |key, _path|
          @hash[key] = public_send(key)
        end

        @hash
      end

      def method_missing(method_sym, *arguments, &block)
        if respond_to_missing?(method_sym)
          exists?(self.class.well_knowns[method_sym])
        else
          super
        end
      end

      def respond_to_missing?(method_sym, include_private = false)
        if self.class.well_knowns.key?(method_sym)
          true
        else
          super
        end
      end

      private

      def prefetch
        options = SiteInspector.typhoeus_defaults.merge(followlocation: true)
        self.class.well_knowns.each do |_wk, path|
          uri = endpoint.join(path)
          request = Typhoeus::Request.new(uri, options)
          SiteInspector.hydra.queue(request)
        end
        SiteInspector.hydra.run
      end
    end
  end
end
