# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Whois < Check
      def domain
        @domain ||= whois.lookup host
      end

      def ip
        @ip ||= whois.lookup ip_address if ip_address
      end

      def to_h
        {
          domain: record_to_h(domain),
          ip: record_to_h(ip)
        }
      end

      private

      def record_to_h(record)
        return unless record

        record.content.scan(/^\s*(.*?):\s*(.*?)\r?\n/).to_h
      end

      def ip_address
        return @ip_address if defined? @ip_address

        @ip_address = begin
          Resolv.getaddress host
        rescue Resolv::ResolvError
          nil
        end
      end

      def whois
        @whois ||= ::Whois::Client.new
      end
    end
  end
end
