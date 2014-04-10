require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Test::Unit::TestCase
  should "parse a domain" do
    site = SiteInspector.new "foo.gov"
    assert_equal "foo.gov", site.domain.to_s
  end

  should "parse a domain with a scheme" do
    site = SiteInspector.new "http://foo.gov"
    assert_equal "foo.gov", site.domain.to_s
  end

  should "parse a domain with a path" do
    site = SiteInspector.new "foo.gov/bar"
    assert_equal "foo.gov", site.domain.to_s
  end

  should "parse a domain with a path and scheme" do
    site = SiteInspector.new "http://foo.gov/bar"
    assert_equal "foo.gov", site.domain.to_s
  end

  should "generate a URI with a scheme" do
    site = SiteInspector.new "foo.gov"
    assert_equal "http://foo.gov", site.uri.to_s
    assert_equal "https://foo.gov", site.uri("https").to_s
  end

  should "strip www from domain" do
    site = SiteInspector.new "www.foo.gov"
    assert_equal "foo.gov", site.domain.to_s
    
    site = SiteInspector.new "http://www.foo.gov"
    assert_equal "foo.gov", site.domain.to_s
  end
end
