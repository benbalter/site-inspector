# frozen_string_literal: true

require 'ipaddr'

class SiteInspector
  class Endpoint
    class Dns < Check
      class LocalhostError < StandardError; end

      # Record types fetched for #records. ANY queries are deprecated
      # (RFC 8482) and most resolvers answer them with a single HINFO record.
      RECORD_TYPES = %w[A AAAA CNAME MX DNSKEY].freeze

      def self.resolver
        require 'dnsruby'
        @resolver ||= begin
          resolver = Dnsruby::Resolver.new
          resolver.config.nameserver = ['8.8.8.8', '8.8.4.4']
          resolver
        end
      end

      def query(type = 'A')
        lookup(host.to_s, type)
      end

      def records
        @records ||= RECORD_TYPES.flat_map { |type| query(type) }.uniq(&:to_s)
      end

      def record?(type)
        return true if records.any? { |record| record.type == type }
        return false if RECORD_TYPES.include?(type.to_s)

        query(type).any?
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
        return false unless ip

        IPAddr.new(ip).loopback?
      rescue IPAddr::InvalidAddressError
        false
      end

      # The host's first IPv4 address, falling back to IPv6
      def ip
        @ip ||= begin
          record = records.find { |r| r.type == 'A' } || records.find { |r| r.type == 'AAAA' }
          record&.address&.to_s
        end
      end

      # The PTR hostname for #ip
      def hostname
        return @hostname if defined?(@hostname)
        return @hostname = nil unless ip

        ptr = lookup(ip, 'PTR').find { |record| record.type == 'PTR' }
        @hostname = ptr ? PublicSuffix.parse(ptr.domainname.to_s) : nil
      rescue PublicSuffix::DomainInvalid
        @hostname = nil
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
          cdn:,
          cloud_provider:,
          google_apps: google_apps?,
          hostname: hostname.to_s,
          ip:
        }
      end

      private

      def lookup(name, type)
        SiteInspector::Endpoint::Dns.resolver.query(name, type).answer
      rescue Dnsruby::ResolvTimeout, Dnsruby::ResolvError => e
        SiteInspector.logger.warn e.message
        []
      end

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
