class SiteInspector
  def dns
    @dns ||= Net::DNS::Resolver.start(domain.to_s).answer
  end

  def dnsec?
    dns.any? { |answer| answer.class == Net::DNS::RR::DNSKEY }
  end

  def ipv6?
    dns.any? { |answer| answer.class == Net::DNS::RR::AAAA }
  end

  def cdn
    raise "not yet implemented"
  end

  def cloud_provider
    raise "not yet implemented"
  end

  def google_apps?
    raise "not yet implemented"
  end

end
