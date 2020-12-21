# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Whois < Check
      def domain
        return @domain if defined? @domain

        @domain = begin
          whois.lookup host
        rescue Timeout::Error
          nil
        end
      end

      def ip
        return @ip if defined? @ip

        @ip = begin
          whois.lookup ip_address if ip_address
        rescue Timeout::Error
          nil
        end
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
