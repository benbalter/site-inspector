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
    raise "not yet implemented"
  end

  def cloud_provider
    raise "not yet implemented"
  end

  def google_apps?
    raise "not yet implemented"
  end

  def ip
    @ip ||= Resolv.getaddress domain.to_s
  end

  def hostname
    @hostname ||= Resolv.getname ip
  rescue Resolv::ResolvError => e
    nil
  end
end
