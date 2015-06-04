require 'json'

class SiteInspector
  class Endpoint
    class Accessibility < Check
      
      def section508
        pa11y('Section508')
      end
      
      def wcag2a
        pa11y('WCAG2A')
      end
      
      def wcag2aa
        pa11y('WCAG2AA')
      end
      
      def wcag2aaa
        pa11y('WCAG2AAA')
      end
      
      private
      
      def pa11y(reporter)
        json_string = `pa11y https://18f.gsa.gov -s #{reporter} -r json`
        JSON.parse(json_string)
      end
      
    end
  end
end
