class SiteInspector

  # cookies can have multiple set-cookie headers, so this detects
  # whether cookies are set, but not all their values.
  def has_cookies?
    !!headers["set-cookie"]
  end

  def strict_transport_security?
    !!strict_transport_security
  end

  def content_security_policy?
    !!content_security_policy
  end

  def click_jacking_protection?
    !!click_jacking_protection
  end

  # return the found header value

  def strict_transport_security
    headers["strict-transport-security"]
  end

  def content_security_policy
    headers["content-security-policy"]
  end

  def click_jacking_protection
    headers["x-frame-options"]
  end

  def server
    headers["server"]
  end

  def xss_protection
    headers["x-xss-protection"]
  end

  # more specific checks than presence of headers
  def xss_protection?
    xss_protection == "1; mode=block"
  end

  def secure_cookies?
    return nil if !has_cookies?
    cookie = headers["set-cookie"]
    cookie = cookie.first if cookie.is_a?(Array)
    !!(cookie =~ /; (secure|httponly)/i)
  end

  # Returns an array of hashes of downcased key/value header pairs (or nil)
  def headers
    @headers ||= Hash[response.headers.map{ |k,v| [k.downcase,v] }] if response
  end
end
