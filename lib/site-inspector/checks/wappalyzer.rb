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
        return {} unless data['technologies']

        @to_h ||= begin
          technologies = {}
          data['technologies'].each do |t|
            category = t['categories'].first
            category = category ? category['name'] : 'Other'
            technologies[category] ||= []
            technologies[category].push t['name']
          end

          technologies
        end
      end

      private

      def data
        @data ||= begin
          args = [endpoint.uri.to_s]
          output, status = self.class.run_command(args)
          raise WappalyzerError if status.exitstatus == 1

          @data = JSON.parse(output)
        end
      rescue JSON::ParserError
        raise WappalyzerError, "Command `wappalyzer #{args.join(' ')}` failed: #{output}"
      end
    end
  end
end
