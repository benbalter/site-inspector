require 'json'
require 'open3'
require 'mkmf'

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
      
      def pa11y_installed?
        !`which pa11y`.empty?
      end
      
      def pa11y(standard)
        if pa11y_installed?
          standards = {
            section508: 'Section508',
            wcag2a: 'WCAG2A',
            wcag2aa: 'WCAG2AA',
            wcag2aaa: 'WCAG2AAA'
          }
          standard = standards[standard]
                             
          cmd = "pa11y #{endpoint.uri} -s #{standard} -r json"
          response = ""
          error = nil
                  
          Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
            response = stdout.read
            error = stderr.read          
          end    
        
          if error && !error.empty?
            raise error
          end
        
          JSON.parse(response) 
        else
          raise "pa11y not found. To install: [sudo] npm install -g pa11y"
        end
      end
      
    end
  end
end
