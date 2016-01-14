class SiteInspector
  class Endpoint
    class Sniffer < Check
      OPEN_SOURCE_FRAMEWORKS = [
        # Sniffles
        :drupal,
        :joomla,
        :movabletype,
        :phpbb,
        :wordpress,

        # Internal
        :php,
        :expression_engine,
        :cowboy
      ]

      def framework
        cms = sniff :cms
        return cms unless cms.nil?
        return :expression_engine if endpoint.cookies.any? { |c| c.keys.first =~ /^exp_/ }
        return :php if endpoint.cookies['PHPSESSID']
        return :coldfusion if endpoint.cookies['CFID'] && endpoint.cookies['CFTOKEN']
        return :cowboy if endpoint.headers.server.to_s.downcase == 'cowboy'
        nil
      end

      def open_source?
        OPEN_SOURCE_FRAMEWORKS.include?(framework)
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
          framework:   framework,
          analytics:   analytics,
          javascript:  javascript,
          advertising: advertising
        }
      end

      private

      def sniff(type)
        require 'sniffles'
        results = Sniffles.sniff(endpoint.content.body, type).select { |_name, meta| meta[:found] }
        results.keys.first if results
      rescue
        nil
      end
    end
  end
end
