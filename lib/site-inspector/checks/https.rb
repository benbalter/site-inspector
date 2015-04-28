class SiteInspector
  class Endpoint
    class Https < Check

      def scheme?
        scheme == "https"
      end

      def valid?
        scheme? && response && response.return_code == :ok
      end

      def bad_chain?
        scheme? && response && response.return_code == :ssl_cacert
      end

      def bad_name?
        scheme? && response && response.return_code == :peer_failed_verification
      end

      def inspect
        "#<SiteInspector::Endpoint::Https valid=#{valid?}>"
      end

      def to_h
        {
          valid: valid?,
          return_code: response.return_code,
        }
      end

      private

      def scheme
        @scheme ||= request.base_url.scheme
      end

    end
  end
end
