require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorHeaders < Minitest::Test
  should "detect HTTP headers designed for XSS protection" do
    VCR.use_cassette "www.google.co.uk", :record => :new_episodes do
      site = SiteInspector.new "www.google.co.uk"
      assert_equal true, site.xss_protection?
    end
  end

  should "detect when cookies not present" do
    VCR.use_cassette "ed.gov", :record => :new_episodes do
      site = SiteInspector.new "ed.gov"
      assert_equal false, site.has_cookies?
    end
  end

  should "detect when cookies are present" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.has_cookies?
    end
  end

  should "detect strict transport security" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.strict_transport_security?
    end
  end

  should "detect HTTP headers designed for clickjacking protection" do
    VCR.use_cassette "www.google.co.uk", :record => :new_episodes do
      site = SiteInspector.new "www.google.co.uk"
      assert_equal true, site.click_jacking_protection?
    end
  end

  should "detect a content security policy" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.content_security_policy?
    end
  end

end
