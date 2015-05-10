class SiteInspector
  class Endpoint
    class Dns < Check

      def self.resolver
        require "dnsruby"
        @resolver ||= begin
          resolver = Dnsruby::Resolver.new
          resolver.config.nameserver = ["8.8.8.8", "8.8.4.4"]
          resolver
        end
      end

      def query(type="ANY")
        SiteInspector::Endpoint::Dns.resolver.query(host.to_s, type).answer
      rescue Dnsruby::ResolvTimeout, Dnsruby::ServFail
        []
      end

      def records
        @records ||= query
      end

      def has_record?(type)
        records.any? { |record| record.type == type } || query(type).count != 0
      end

      def dnssec?
        @dnssec ||= has_record? "DNSKEY"
      end

      def ipv6?
        @ipv6 ||= has_record? "AAAA"
      end

      def cdn
        detect_by_hostname "cdn"
      end

      def cdn?
        !!cdn
      end

      def cloud_provider
        detect_by_hostname "cloud"
      end

      def cloud?
        !!cloud_provider
      end

      def google_apps?
        @google ||= records.any? do |record|
          record.type == "MX" && record.exchange.to_s =~ /google(mail)?\.com\.?$/
        end
      end

      def ip
        require 'resolv'
        @ip ||= Resolv.getaddress host
      rescue Resolv::ResolvError
        nil
      end

      def hostname
        require 'resolv'
        @hostname ||= PublicSuffix.parse(Resolv.getname(ip))
      rescue Resolv::ResolvError
        nil
      end

      def cnames
        @cnames ||= records.select { |record| record.type == "CNAME" }.map do |record|
          PublicSuffix.parse(record.cname.to_s)
        end
      end

      def inspect
        "#<SiteInspector::Domain::Dns host=\"#{host}\">"
      end

      def to_h
        {
          :dnssec => dnssec?,
          :ipv6   => ipv6?,
          :cdn    => cdn,
          :cloud_provider => cloud_provider,
          :google_apps => google_apps?,
          :hostname => hostname,
          :ip => ip
        }
      end

      private

      def data
        @data ||= {}
      end

      def data_path(name)
        File.expand_path "../../data/#{name}.yml", File.dirname(__FILE__)
      end

      def load_data(name)
        require 'yaml'
        path = data_path(name)
        data[name] ||= YAML.load_file(path)
      end

      def detect_by_hostname(type)
        haystack = load_data(type)
        needle = haystack.find do |name, domain|
          cnames.any? do |cname|
            domain == cname.tld || domain == "#{cname.sld}.#{cname.tld}"
          end
        end

        return needle[0].to_sym if needle
        return nil unless hostname

        needle = haystack.find do |name, domain|
          domain == hostname.tld || domain == "#{hostname.sld}.#{hostname.tld}"
        end

        needle ? needle[0].to_sym : nil
      end
    end
  end
end
