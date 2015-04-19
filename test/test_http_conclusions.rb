require "./" + File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  # Until we migrate to a non-curl-based HTTP library, this
  # will hit the network.

  def setup
    # allow network disk cache
    # Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "evaluate hsts preload" do
    details = SiteInspector.new("uspsoig.gov").http

    # full subdomains and preload
    assert_equal true, details[:hsts]
    assert_equal true, details[:hsts_entire_domain]
    assert_equal true, details[:hsts_entire_domain_preload]

    # just www and root
    details = SiteInspector.new("healthcare.gov").http
    assert_equal true, details[:hsts]
    assert_equal false, details[:hsts_entire_domain]
    assert_equal false, details[:hsts_entire_domain_preload]
  end

  should "ignore a 404 root for a proper www" do
    # https://asc.gov is 404, http
    details = SiteInspector.new("asc.gov").http

    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :https, details[:canonical_protocol]
  end

  should "detect canonical www sites whose http sites are both down" do
    # searanchlakesflorida.gov has:
    #   * http:// -> invalid https://
    #   * http://www -> valid https://www
    details = SiteInspector.new("searanchlakesflorida.gov").http

    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :https, details[:canonical_protocol]

    # nasa.gov has no DNS entries for the bare domain
    details = SiteInspector.new("nasa.gov").http
    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :http, details[:canonical_protocol]
  end

end
