# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Whois < Check
      def domain
        whois.lookup host
      end

      def ip
        whois.lookup ip_address
      end

      def to_h
        {
          domain: domain,
          ip: ip
        }
      end

      private

      def ip_address
        @ip_address ||= Resolv.getaddress host
      end

      def whois
        @whois ||= ::Whois::Client.new
      end
    end
  end
end
