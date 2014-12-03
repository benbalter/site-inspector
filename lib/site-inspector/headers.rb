class SiteInspector

  # cookies can have multiple set-cookie headers, so this detects
  # whether cookies are set, but not all their values.
  def has_cookies?
    !!header_from("Set-Cookie")
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
    header_from("Strict-Transport-Security")
  end

  def content_security_policy
    header_from("Content-Security-Policy")
  end

  def click_jacking_protection
    header_from("X-Frame-Options")
  end

  def server
    header_from("Server")
  end

  def xss_protection
    header_from("X-XSS-Protection")
  end

  # more specific checks than presence of headers
  def xss_protection?
    xss_protection == "1; mode=block"
  end

  def secure_cookies?
    return nil if !response || !has_cookies?
    cookie = header_from("Set-Cookie")
    cookie = cookie.first if cookie.is_a?(Array)
    marked_secure = !!(cookie.downcase =~ /secure/)
    marked_http_only = !!(cookie.downcase =~ /httponly/)
    marked_secure and marked_http_only
  end

  # helper function: case-insensitive sweep for header, return value
  def header_from(header)
    return nil unless response

    the_header = response.headers.keys.find {|h| h.downcase =~ /^#{header.downcase}/}
    response.headers[the_header]
  end
end
