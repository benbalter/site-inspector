require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  # Until we migrate to a non-curl-based HTTP library, this
  # will hit the network.

  def setup
    # allow network disk cache
    # Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "handle a www, enforced HSTS site" do
    endpoint = SiteInspector.new("whitehouse.gov").http_endpoint(true, true)
    assert_equal false, endpoint[:redirect]
    assert_equal true, endpoint[:hsts]
    assert_equal true, endpoint[:https_valid]
    assert_equal 200, endpoint[:status]

    # https:// => https://www.
    endpoint = SiteInspector.new("whitehouse.gov").http_endpoint(true, false)
    assert_equal true, endpoint[:redirect]
    assert_equal true, endpoint[:redirect_immediately_to_https]
    assert_equal true, endpoint[:redirect_immediately_to_www]
    assert_equal false, endpoint[:redirect_immediately_external]
    assert_equal false, endpoint[:redirect_external]
  end

  should "handle external redirector" do
    # http:// => http://www.whitehouse => https://www.whitehouse
    endpoint = SiteInspector.new("save.gov").http_endpoint(false, false)
    assert_equal true, endpoint[:redirect]
    assert_equal false, endpoint[:redirect_immediately_to_https]
    assert_equal true, endpoint[:redirect_immediately_to_www]
    assert_equal true, endpoint[:redirect_immediately_external]
    assert_equal true, endpoint[:redirect_external]

    # while we're here, make sure HSTS not recognized over http://
    assert_equal false, endpoint[:hsts]
  end

  should "handle relative redirect headers" do
    # http://www.gsa.gov
    endpoint = SiteInspector.new("gsa.gov").http_endpoint(false, true)
    assert_equal true, endpoint[:redirect]
    assert endpoint[:headers]['location'].start_with?("/")
    assert_equal false, endpoint[:redirect_immediately_to_https]

    # TODO: this should be true, since it's staying www
    assert_equal false, endpoint[:redirect_immediately_to_www]

    assert_equal false, endpoint[:redirect_immediately_external]
    assert_equal false, endpoint[:redirect_external]
  end

  should "treat domains as case-insensitive" do
    endpoint = SiteInspector.new("searanchlakesflorida.gov").http_endpoint(false, false)

    assert_equal true, endpoint[:redirect]
    assert_equal false, endpoint[:redirect_external]
    assert_equal false, endpoint[:redirect_immediately_external]
    assert_equal true, endpoint[:redirect_immediately_to_https]
    assert_equal false, endpoint[:redirect_immediately_to_www]
  end

  should "handle IP address redirects" do
    endpoint = SiteInspector.new("greensboro-ga.gov").http_endpoint(false, false)

    assert_equal true, endpoint[:redirect]
    assert_equal true, endpoint[:redirect_external]
    assert_equal true, endpoint[:redirect_immediately_external]
    assert_equal false, endpoint[:redirect_immediately_to_https]
    assert_equal false, endpoint[:redirect_immediately_to_www]
  end

  should "ignore HSTS with max-age=0" do
    endpoint = SiteInspector.new("c3.gov").http_endpoint(true, true)

    assert_equal "max-age=0", endpoint[:hsts_header]
    assert_equal false, endpoint[:hsts]
  end

  should "handle bad Location headers with grace and aplomb" do
    # Location: "//?"
    endpoint = SiteInspector.new("walkersvillemd.gov").http_endpoint(true, true)

    assert_equal "//?", endpoint[:redirect_immediately_to]
    assert_equal false, endpoint[:redirect_immediately_to_www]
    assert_equal false, endpoint[:redirect_immediately_to_https]
  end

end
