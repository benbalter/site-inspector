# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Wappalyzer < Check
      ENDPOINT = 'https://api.wappalyzer.com/lookup/v2/'

      def to_h
        return {} unless data['technologies']

        @to_h ||= begin
          technologies = {}
          data['technologies'].each do |t|
            category = t['categories'].first
            category = category ? category['name'] : 'Other'
            technologies[category] ||= []
            technologies[category].push t['name']
          end

          technologies
        end
      end

      private

      def request
        @request ||= begin
          options = SiteInspector.typhoeus_defaults
          headers = options[:headers].merge({ "x-api-key": api_key })
          options = options.merge(method: :get, headers: headers)
          Typhoeus::Request.new(url, options)
        end
      end

      def data
        return {} unless api_key && api_key != ''

        @data ||= begin
          SiteInspector.hydra.queue(request)
          SiteInspector.hydra.run

          response = request.response
          if response.success?
            JSON.parse(response.body).first
          else
            {}
          end
        end
      end

      def url
        url = Addressable::URI.parse(ENDPOINT)
        url.query_values = { urls: endpoint.uri }
        url
      end

      def api_key
        @api_key ||= ENV['WAPPALYZER_API_KEY']
      end
    end
  end
end
