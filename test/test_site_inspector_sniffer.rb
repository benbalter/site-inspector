require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorSniffer < Minitest::Test
  should "detect a site's CMS" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal :wordpress, site.cms.keys[0]
    end
  end

  should "detect a site's server" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal "Apache", site.server
    end
  end

  should "detect a site's javascript" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal :jquery, site.javascript.keys[0]
    end
  end

  should "detect a site's analytics" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal :google_analytics, site.analytics.keys[0]
    end
  end
end
