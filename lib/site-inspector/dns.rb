class SiteInspector

  def resolver
    @resolver ||= begin
      resolver = Dnsruby::Resolver.new
      resolver.config.nameserver = ["8.8.8.8", "8.8.4.4"]
      resolver
    end
  end

  def query(type="ANY")
    resolver.query(domain.to_s, type).answer
  rescue
    []
  end

  def dns
    @dns ||= query
  end

  def has_record?(type)
    dns.any? { |record| record.type == type } || query(type).count != 0
  end

  def dnssec?
    @dnssec ||= has_record? "DNSKEY"
  end

  def ipv6?
    @ipv6 ||= has_record? "AAAA"
  end

  def detect_by_hostname(type)

    haystack = SiteInspector.load_data(type)
    needle = haystack.find { |name, domain|
      cnames.any? { |cname|
        domain == cname.tld || domain == "#{cname.sld}.#{cname.tld}"
      }
    }

    return needle[0] if needle
    return false unless hostname

    needle = haystack.find { |name, domain|
      domain == hostname.tld || domain == "#{hostname.sld}.#{hostname.tld}"
    }

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
    @google ||= dns.any? do |record|
      record.type == "MX" && record.exchange =~ /google(mail)?\.com\.?$/
    end
  end

  def ip
    @ip ||= Resolv.getaddress domain.to_s
  rescue Resolv::ResolvError
    nil
  end

  def hostname
    @hostname ||= PublicSuffix.parse(Resolv.getname(ip))
  rescue Exception => e
    nil
  end

  def cnames
    @cnames ||= dns.select {|record| record.type == "CNAME" }.map { |record| PublicSuffix.parse(record.cname.to_s) }
  end
end
