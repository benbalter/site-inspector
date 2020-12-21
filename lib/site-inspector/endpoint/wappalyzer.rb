# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Wappalyzer < Check
      class WappalyzerError < RuntimeError; end

      class << self
        def wappalyzer?
          return @wappalyzer_detected if defined? @wappalyzer_detected

          @wappalyzer_detected = !!wappalyzer.detect
        end

        def enabled?
          @@enabled && wappalyzer?
        end

        def wappalyzer
          @wappalyzer ||= begin
            path = ['*', './bin', './node_modules/.bin'].join(File::PATH_SEPARATOR)
            Cliver::Dependency.new('wappalyzer', path: path)
          end
        end

        def run_command(args)
          Open3.capture2e(wappalyzer.detect, *args)
        end
      end

      def to_h
        return {} unless endpoint.up?
        return {} if endpoint.redirect?

        @to_h ||= begin
          technologies = {}

          data['technologies']&.each do |t|
            category = t['categories'].first
            category = category ? category['name'] : 'other'
            category = category.downcase.tr(' ', '_').to_sym
            technologies[category] ||= []
            technologies[category].push t['name']
          end

          technologies
        end
      end

      private

      def data
        @data ||= begin
          output, _status = self.class.run_command([endpoint.uri.to_s])
          @data = JSON.parse(output)
        rescue Timeout::Error, IOError
          @data = { technologies: {
            categories: ['timeout'],
            name: "https://www.wappalyzer.com/lookup/#{endpoint.host}"
          } }
        end
      rescue JSON::ParserError
        raise WappalyzerError, "Command `wappalyzer #{args.join(' ')}` failed: #{output}"
      end
    end
  end
end
