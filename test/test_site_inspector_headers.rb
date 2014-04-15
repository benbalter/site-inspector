require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorHeaders < Minitest::Test
  should "detect HTTP headers designed for XSS protection" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.xss_protection?
    end
  end

  should "detect secure cookies" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.secure_cookies?
    end
  end

  should "detect strict transport security" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.strict_transport_security?
    end
  end

  should "detect HTTP headers designed for clickjacking protection" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.click_jacking_protection?
    end
  end

  should "detect a content security policy" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.content_security_policy?
    end
  end

end
