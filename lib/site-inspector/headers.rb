class SiteInspector
  def server
    response.headers["Server"]
  end

  def xss_protection?
    response.headers["X-XSS-Protection"] == "1; mode=block"
  end

  def has_cookies?
    response.headers.include? "Set-Cookie"
  end

  def secure_cookies?
    return nil if !has_cookies?
    cookie = response.headers["Set-Cookie"]
    marked_secure = !!(cookie.downcase =~ /secure/)
    marked_http_only = !!(cookie.downcase =~ /HttpOnly/)
    marked_secure and marked_http_only
  end

  def strict_transport_security?
    response.headers.include? "Strict-Transport-Security"
  end

  def content_security_policy?
    response.headers.include? "Content-Security-Policy"
  end

  def click_jacking_protection?
    response.headers["X-Frame-Options"] == "DENY" and \
      response.headers["X-Content-Type-Options"] == "nosniff"
  end
end
