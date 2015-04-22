class SiteInspector
  class Dns

    attr_reader :host

    def initialize(host)
      @host = host.to_s
    end

    def self.resolver
      require "dnsruby"
      @resolver ||= begin
        resolver = Dnsruby::Resolver.new
        resolver.config.nameserver = ["8.8.8.8", "8.8.4.4"]
        resolver
      end
    end

    def query(type="ANY")
      SiteInspetor::DNS.resolver.query(host.to_s, type).answer
    rescue
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

    def detect_by_hostname(type)

      haystack = load_data(type)
      needle = haystack.find do |name, domain|
        cnames.any? do |cname|
          domain == cname.tld || domain == "#{cname.sld}.#{cname.tld}"
        end
      end

      return needle[0] if needle
      return false unless hostname

      needle = haystack.find do |name, domain|
        domain == hostname.tld || domain == "#{hostname.sld}.#{hostname.tld}"
      end

      needle ? needle[0] : false
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
        record.type == "MX" && record.exchange =~ /google(mail)?\.com\.?$/
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
    rescue Exception => e
      nil
    end

    def cnames
      @cnames ||= records.select do |record|
        record.type == "CNAME" }.map do |record|
          PublicSuffix.parse(record.cname.to_s)
        end
      end
    end

    private

    def load_data(name)
      require 'yaml'
      YAML.load_file File.expand_path "../data/#{name}.yml", File.dirname(__FILE__)
    end
  end
end
