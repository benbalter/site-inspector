# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Whois < Check
      def host
        whois.lookup host
      end

      def ip
        whois.lookup endpoint.checks.dns.ip
      end

      private
    end
  end
end
