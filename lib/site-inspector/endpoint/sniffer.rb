class SiteInspector
  class Endpoint
    class Sniffer

      attr_reader :response

      def initialize(response)
        @response = response
      end

      def doc
        require 'nokogiri'
        @doc ||= Nokogiri::HTML response.body if response
      end

      def body
        doc.to_s.force_encoding("UTF-8").encode("UTF-8", :invalid => :replace, :replace => "")
      end

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

      def inspect
        "#<SiteInspector::Endpoint::Sniffer endpoint=\"#{response.effective_url}\">"
      end

      private

      def sniff(type)
        require 'sniffles'
        results = Sniffles.sniff(body, type).select { |name, meta| meta[:found] == true }
        results.each { |name, result| result.delete :found} if results
        results
      rescue
        nil
      end
    end
  end
end
