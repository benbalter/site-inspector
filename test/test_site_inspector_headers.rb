require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorHeaders < Minitest::Test
  should "detect HTTP headers designed for XSS protection" do
    VCR.use_cassette "www.google.co.uk", :record => :new_episodes do
      site = SiteInspector.new "www.google.co.uk"
      assert_equal true, site.xss_protection?
      assert_equal "1; mode=block", site.xss_protection
    end
  end

  should "detect when cookies not present" do
    VCR.use_cassette "ed.gov", :record => :new_episodes do
      site = SiteInspector.new "ed.gov"
      assert_equal false, site.has_cookies?
      assert_nil site.has_cookies
    end
  end

  should "detect when cookies are present" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.has_cookies?
      assert !site.has_cookies.nil? # uses a generated ID
    end
  end

  should "detect strict transport security" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.strict_transport_security?
      assert !site.strict_transport_security.nil?
    end
  end

  should "detect HTTP headers designed for clickjacking protection" do
    VCR.use_cassette "www.google.co.uk", :record => :new_episodes do
      site = SiteInspector.new "www.google.co.uk"
      assert_equal true, site.click_jacking_protection?
      assert !site.click_jacking_protection.nil?
    end
  end

  should "detect a content security policy" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal false, site.content_security_policy?
      assert_nil site.content_security_policy
    end
  end

end
