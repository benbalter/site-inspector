class SiteInspector
  def dns
    @dns ||= Net::DNS::Resolver.start(domain.to_s).answer
  end

  def dnsec?
    false #dns.any? { |answer| answer.class == Net::DNS::RR::DNSKEY }
  end

  def ipv6?
    dns.any? { |answer| answer.class == Net::DNS::RR::AAAA }
  end

  def detect_by_hostname(type)
    haystack = load_data(type)
    needle = haystack.find { |name,domain| domain == hostname.domain }
    needle ? needle[0] : false
  end

  def cdn
    detect_by_hostname "cdn"
  end

  def cloud_provider
    detect_by_hostname "cloud"
  end

  def google_apps?
    raise "not yet implemented"
  end

  def ip
    @ip ||= Resolv.getaddress domain.to_s
  rescue Resolv::ResolvError
    nil
  end

  def hostname
    @hostname ||= PublicSuffix.parse(Resolv.getname(ip))
  rescue Resolv::ResolvError => e
    nil
  end
end
