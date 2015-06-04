require 'json'

class SiteInspector
  class Endpoint
    class Accessibility < Check
      
      def section508
        pa11y(:section508)
      end
      
      def wcag2a
        pa11y(:wcag2a)
      end
      
      def wcag2aa
        pa11y(:wcag2aa)
      end
      
      def wcag2aaa
        pa11y(:wcag2aaa)
      end
      
      private
      
      def pa11y(standard)
        standards = {
          section508: 'Section508',
          wcag2a: 'WCAG2A',
          wcag2aa: 'WCAG2AA',
          wcag2aaa: 'WCAG2AAA'
        }
        standard = standards[standard]
                
        json_string = `pa11y #{host} -s #{standard} -r json`
        JSON.parse(json_string)
      end
      
    end
  end
end
