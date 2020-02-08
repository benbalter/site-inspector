# frozen_string_literal: true

class SiteInspector
  class Endpoint
    class Dns < Check
      class LocalhostError < StandardError; end

      def self.resolver
        require 'dnsruby'
        @resolver ||= begin
          resolver = Dnsruby::Resolver.new
          resolver.config.nameserver = ['8.8.8.8', '8.8.4.4']
          resolver
        end
      end

      def query(type = 'ANY')
        SiteInspector::Endpoint::Dns.resolver.query(host.to_s, type).answer
      rescue Dnsruby::ResolvTimeout, Dnsruby::ServFail, Dnsruby::NXDomain
        []
      end

      def records
        @records ||= query
      end

      def record?(type)
        records.any? { |record| record.type == type } || query(type).count != 0
      end
      alias has_record? record?

      def dnssec?
        @dnssec ||= has_record? 'DNSKEY'
      end

      def ipv6?
        @ipv6 ||= has_record? 'AAAA'
      end

      def cdn
        detect_by_hostname 'cdn'
      end

      def cdn?
        !!cdn
      end

      def cloud_provider
        detect_by_hostname 'cloud'
      end

      def cloud?
        !!cloud_provider
      end

      def google_apps?
        @google_apps ||= records.any? do |record|
          record.type == 'MX' && record.exchange.to_s =~ /google(mail)?\.com\.?\z/i
        end
      end

      def localhost?
        ip == '127.0.0.1'
      end

      def ip
        @ip ||= Resolv.getaddress host
      rescue Resolv::ResolvError
        nil
      end

      def hostname
        require 'resolv'
        @hostname ||= PublicSuffix.parse(Resolv.getname(ip))
      rescue Resolv::ResolvError, PublicSuffix::DomainInvalid
        nil
      end

      def cnames
        @cnames ||= records.select { |record| record.type == 'CNAME' }.map do |record|
          PublicSuffix.parse(record.cname.to_s)
        end
      end

      def inspect
        "#<SiteInspector::Domain::Dns host=\"#{host}\">"
      end

      def to_h
        return { error: LocalhostError } if localhost?

        {
          dnssec: dnssec?,
          ipv6: ipv6?,
          cdn: cdn,
          cloud_provider: cloud_provider,
          google_apps: google_apps?,
          hostname: hostname,
          ip: ip
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
        needle = haystack.find do |_name, domain|
          cnames.any? do |cname|
            [cname.tld, "#{cname.sld}.#{cname.tld}"].include? domain
          end
        end

        return needle[0].to_sym if needle
        return nil unless hostname

        needle = haystack.find do |_name, domain|
          [hostname.tld, "#{hostname.sld}.#{hostname.tld}"].include? domain
        end

        needle ? needle[0].to_sym : nil
      end
    end
  end
end
