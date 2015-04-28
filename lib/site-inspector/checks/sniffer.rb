class SiteInspector
  class Endpoint
    class Sniffer < Check

      def cms
        sniff :cms
      end

      def analytics
        sniff :analytics
      end

      def javascript
        sniff :javascript
      end

      def advertising
        sniff :advertising
      end

      def to_h
        {
          :cms         => cms,
          :analytics   => analytics,
          :javascript  => javascript,
          :advertising => advertising
        }
      end

      private

      def sniff(type)
        require 'sniffles'
        results = Sniffles.sniff(endpoint.content.body, type).select { |name, meta| meta[:found] == true }
        results.each { |name, result| result.delete :found} if results
        results
      rescue
        nil
      end
    end
  end
end
