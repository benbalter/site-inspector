# frozen_string_literal: true

require 'json'
require 'open3'

class SiteInspector
  class Endpoint
    class Accessibility < Check
      class Pa11yError < RuntimeError; end

      STANDARDS = {
        wcag2a: 'WCAG2A', # Default standard
        wcag2aa: 'WCAG2AA',
        wcag2aaa: 'WCAG2AAA',
        section508: 'Section508'
      }.freeze

      DEFAULT_LEVEL = :error

      REQUIRED_PA11Y_VERSION = '~> 5.0'

      class << self
        def pa11y_version
          @pa11y_version ||= pa11y.version
        end

        def pa11y?
          return @pa11y_detected if defined? @pa11y_detected

          @pa11y_detected = !!pa11y.detect
        end

        def enabled?
          @@enabled && pa11y?
        end

        def pa11y
          @pa11y ||= begin
            node_bin = File.expand_path('../../../node_modules/pa11y/bin', File.dirname(__FILE__))
            path = ['*', node_bin].join(File::PATH_SEPARATOR)
            Cliver::Dependency.new('pa11y.js', REQUIRED_PA11Y_VERSION, path: path)
          end
        end
      end

      def level
        @level ||= DEFAULT_LEVEL
      end

      def level=(level)
        raise ArgumentError, "Invalid level '#{level}'" unless %i[error warning notice].include?(level)

        @level = level
      end

      def standard?(standard)
        STANDARDS.key?(standard)
      end

      def standard
        @standard ||= STANDARDS.keys.first
      end

      def standard=(standard)
        raise ArgumentError, "Unknown standard '#{standard}'" unless standard?(standard)

        @standard = standard
      end

      def valid?
        check[:valid] if check
      end

      def errors
        check[:results].count { |r| r['type'] == 'error' } if check
      end

      def check
        @check ||= run_pa11y(standard)
      rescue Pa11yError
        nil
      end
      alias to_h check

      def method_missing(method_sym, *arguments, &block)
        if standard?(method_sym)
          run_pa11y(method_sym)
        else
          super
        end
      end

      def respond_to_missing?(method_sym, include_private = false)
        if standard?(method_sym)
          true
        else
          super
        end
      end

      private

      def run_pa11y(standard)
        self.class.pa11y.detect! unless ENV['SKIP_PA11Y_CHECK']
        raise ArgumentError, "Unknown standard '#{standard}'" unless standard?(standard)

        args = [
          '--standard', STANDARDS[standard],
          '--reporter', 'json',
          '--level',    level.to_s,
          endpoint.uri.to_s
        ]
        output, status = run_command(args)

        # Pa11y exit codes: https://github.com/nature/pa11y#exit-codes
        # 0: No errors, 1: Technical error within pa11y, 2: accessibility error (configurable via --level)
        raise Pa11yError if status.exitstatus == 1

        {
          valid: status.exitstatus.zero?,
          results: JSON.parse(output)
        }
      rescue Pa11yError, JSON::ParserError
        raise Pa11yError, "Command `pa11y #{args.join(' ')}` failed: #{output}"
      end

      def run_command(args)
        Open3.capture2e(self.class.pa11y.detect, *args)
      end
    end
  end
end
