class SiteInspector
  def server
    response && response.headers["Server"]
  end

  def xss_protection?
    response && response.headers["X-XSS-Protection"] == "1; mode=block"
  end

  def has_cookies?
    response && response.headers.include?("Set-Cookie")
  end

  def secure_cookies?
    return nil if !response || !has_cookies?
    cookie = response.headers["Set-Cookie"]
    cookie = cookie.first if cookie.is_a?(Array)
    marked_secure = !!(cookie.downcase =~ /secure/)
    marked_http_only = !!(cookie.downcase =~ /HttpOnly/)
    marked_secure and marked_http_only
  end

  def strict_transport_security?
    response && response.headers.include?("Strict-Transport-Security")
  end

  def content_security_policy?
    response && response.headers.include?("Content-Security-Policy")
  end

  def click_jacking_protection?
    response && response.headers.include?("X-Frame-Options")
  end
end
