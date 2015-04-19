require "./" + File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  # Until we migrate to a non-curl-based HTTP library, this
  # will hit the network.

  def setup
    Typhoeus::Config.cache = SiteInspectorCache.new
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

end
