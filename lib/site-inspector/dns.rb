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

  def cdn
    cdns = load_data "cdn"
    cdn = cdns.find { |name, domain| domain == hostname.domain }
    cdn[0] if cdn
  end

  def cloud_provider
    raise "not yet implemented"
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
