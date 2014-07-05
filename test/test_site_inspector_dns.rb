require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorDns < Minitest::Test
  should "retrieve a site's DNS records" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal Dnsruby::Message::Section, site.dns.class
      assert_equal false, site.dns.empty?
    end
  end

  should "detect DNSSec support" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal true, site.dnssec?
    end
  end

  should "detect IPV6 support" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal true, site.ipv6?
    end
  end

  should "detect a site's CDN" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal "akamai", site.cdn
    end
  end

  should "detect a site's cloud provider" do
    VCR.use_cassette "18f.gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "18f.gsa.gov"
      assert_equal "Amazon GovCloud", site.cloud_provider
      assert_equal true, site.cloud?
    end
  end

  should "retrieve a site's IP" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal 0, site.ip =~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
    end
  end

  should "retrieve a site's hostname" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal 0, site.hostname.to_s =~ /.*akamaitechnologies\.com$/
    end
  end

end
