class SiteInspector
  class Endpoint
    class Sniffer < Check

      def framework
        cms = sniff :cms
        return cms unless cms.nil?
        return :expression_engine if endpoint.cookies.any? { |c| c.keys.first =~ /^exp_/ }
        return :php if endpoint.cookies["PHPSESSID"]
        nil
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
          :framework   => framework,
          :analytics   => analytics,
          :javascript  => javascript,
          :advertising => advertising
        }
      end

      private

      def sniff(type)
        require 'sniffles'
        results = Sniffles.sniff(endpoint.content.body, type).select { |name, meta| meta[:found] }
        results.keys.first if results
      rescue
        nil
      end
    end
  end
end
