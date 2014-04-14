require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorCompliance < Minitest::Test
  should "detect a site's /data.json file" do
    VCR.use_cassette "ed.gov", :record => :new_episodes do
      site = SiteInspector.new "ed.gov"
      assert_equal true, site.data_dot_json?
    end
  end

  should "detect a site's /data page" do
    VCR.use_cassette "ed.gov", :record => :new_episodes do
      site = SiteInspector.new "ed.gov"
      assert_equal true, site.slash_data?
    end
  end

  should "detect a site's /developers page" do
    VCR.use_cassette "ed.gov", :record => :new_episodes do
      site = SiteInspector.new "ed.gov"
      assert_equal true, site.slash_developer?
    end
  end

  should "not raise false positives" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.slash_developer?
      assert_equal false, site.data_dot_json?
    end
  end
end
