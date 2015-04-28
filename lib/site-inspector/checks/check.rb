class SiteInspector
  class Endpoint
    class Check

      attr_reader :endpoint

      # A check is an abstract class that takes an Endpoint object
      # and is extended to preform the specific site inspector checks
      #
      # It is automatically accessable within the endpoint object
      # by virtue of extending the Check class
      def initialize(endpoint)
        @endpoint = endpoint
      end

      def response
        endpoint.response
      end

      def request
        response.request
      end

      def host
        request.base_url.host
      end

      def inspect
        "#<#{self.class} endpoint=\"#{response.effective_url}\">"
      end

      def name
        self.class.name
      end

      def self.name
        self.to_s.split('::').last.downcase.to_sym
      end
    end
  end
end
