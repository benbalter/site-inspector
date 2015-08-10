require 'json'
require 'open3'

class SiteInspector
  class Endpoint
    class Accessibility < Check
      class Pa11yError < RuntimeError; end

      STANDARDS = {
        section508: 'Section508', # Default standard
        wcag2a:     'WCAG2A',
        wcag2aa:    'WCAG2AA',
        wcag2aaa:   'WCAG2AAA'
      }

      DEFAULT_LEVEL = :error

      class << self
        def pa11y_version
          output, status = Open3.capture2e("pa11y", "--version")
          output.strip if status == 0
        end

        def pa11y?
          !!(Cliver.detect('pa11y'))
        end

        def enabled?
          @@enabled && pa11y?
        end
      end

      def level
        @level ||= DEFAULT_LEVEL
      end

      def level=(level)
        raise ArgumentError, "Invalid level '#{level}'" unless [:error, :warning, :notice].include?(level)
        @level = level
      end

      def standard?(standard)
        STANDARDS.keys.include?(standard)
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
        check[:results].count { |r| r["type"] == "error" } if check
      end

      def check
        @check ||= pa11y(standard)
      rescue Pa11yError
        nil
      end
      alias_method :to_h, :check

      def method_missing(method_sym, *arguments, &block)
        if standard?(method_sym)
          pa11y(method_sym)
        else
          super
        end
      end

      def respond_to?(method_sym, include_private = false)
        if standard?(method_sym)
          true
        else
          super
        end
      end

      private

      def pa11y(standard)
        Cliver.assert('pa11y')
        raise ArgumentError, "Unknown standard '#{standard}'" unless standard?(standard)

        args = [
          "--standard", STANDARDS[standard],
          "--reporter", "json",
          "--level",    level.to_s,
          endpoint.uri.to_s
        ]
        output, status = run_command(args)

        # Pa11y exit codes: https://github.com/nature/pa11y#exit-codes
        # 0: No errors, 1: Technical error within pa11y, 2: accessibility error (configurable via --level)
        raise Pa11yError if status == 1

        {
          valid:   status == 0,
          results: JSON.parse(output)
        }
      rescue Pa11yError, JSON::ParserError
        raise Pa11yError, "Command `pa11y #{args.join(" ")}` failed: #{output}"
      end

      def run_command(args)
        Open3.capture2e("pa11y", *args)
      end
    end
  end
end
