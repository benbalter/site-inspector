require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  def setup
    Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "detect the redirect surface of an HTTPS WWW site" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      domain = SiteInspector.new("whitehouse.gov").http
      endpoints = domain[:endpoints]

      # http:// -> https://www
      assert endpoints[:http][:root][:redirect]
      assert endpoints[:http][:root][:redirect_away]
      assert !endpoints[:http][:root][:redirect_external]

      # http://www -> https://www
      assert endpoints[:http][:www][:redirect]
      assert endpoints[:http][:www][:redirect_away]
      assert !endpoints[:http][:www][:redirect_external]

      # https:// -> https://www
      assert endpoints[:https][:root][:redirect]
      assert endpoints[:https][:root][:redirect_away]
      assert !endpoints[:https][:root][:redirect_external]

      assert !endpoints[:https][:www][:redirect]
    end
  end

  should "detect a totally forced HTTPS site" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      domain = SiteInspector.new("whitehouse.gov").http
      endpoints = domain[:endpoints]

      assert domain[:support_https]
      assert domain[:default_https]
      assert !domain[:downgrade_https]
      assert domain[:enforce_https]
    end
  end

  should "detect the base HSTS header of a WWW site" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      domain = SiteInspector.new("whitehouse.gov").http
      endpoints = domain[:endpoints]

      assert domain[:hsts]
      assert domain[:https][:root][:hsts]
      assert_equal "www", domain[:canonical_endpoint]
      assert domain[:hsts_entire_domain]
      assert domain[:hsts_entire_domain_preload]
    end
  end
end
