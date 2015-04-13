require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  def setup
    Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "detect the redirect surface of an HTTPS WWW site" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      domain = SiteInspector.new "whitehouse.gov"
      endpoints = domain.http[:endpoints]
      assert endpoints[:http][:www][:redirect]
      assert endpoints[:http][:www][:redirect_to_external]
    end
  end
end
