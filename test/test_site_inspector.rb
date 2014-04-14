require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Test::Unit::TestCase
  should "parse a domain" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal "whitehouse.gov", site.domain.to_s
    end
  end

  should "parse a domain with a scheme" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "http://whitehouse.gov"
      assert_equal "whitehouse.gov", site.domain.to_s
    end
  end

  should "parse a domain with a path" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov/bar"
      assert_equal "whitehouse.gov", site.domain.to_s
    end
  end

  should "parse a domain with a path and scheme" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "http://whitehouse.gov/bar"
      assert_equal "whitehouse.gov", site.domain.to_s
    end
  end

  should "generate a URI with a scheme" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal "http://whitehouse.gov", site.uri.to_s
      assert_equal "https://whitehouse.gov", site.uri("https").to_s
    end
  end

  should "strip www from domain" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "www.whitehouse.gov"
      assert_equal "whitehouse.gov", site.domain.to_s

      site = SiteInspector.new "http://www.whitehouse.gov"
      assert_equal "whitehouse.gov", site.domain.to_s
    end
  end
end
