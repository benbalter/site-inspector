require File.join(File.dirname(__FILE__), 'helper')

require 'oj'

class TestSiteInspector < Minitest::Test

  def setup
    Typhoeus::Config.cache = SiteInspector::Cache.new
  end

  should "parse a domain" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal "www.whitehouse.gov", site.domain.to_s
    end
  end

  should "parse a domain with a scheme" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "http://whitehouse.gov"
      assert_equal "www.whitehouse.gov", site.domain.to_s
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
    VCR.use_cassette "gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "gsa.gov"
      assert_equal "http://gsa.gov", site.uri(false).to_s
      assert_equal "https://gsa.gov", site.uri(true).to_s
    end
  end

  should "strip www from domain" do
    VCR.use_cassette "www.cio.gov", :record => :new_episodes do
      site = SiteInspector.new "www.cio.gov"
      assert_equal "cio.gov", site.domain.to_s

      site = SiteInspector.new "http://www.cio.gov"
      assert_equal "cio.gov", site.domain.to_s
    end
  end

  should "build a uri from a domain" do
    VCR.use_cassette "gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "gsa.gov"
      assert_equal "http://gsa.gov", site.uri(false).to_s
    end
  end

  should "build an https uri from a domain" do
    VCR.use_cassette "gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "gsa.gov"
      assert_equal "https://gsa.gov", site.uri(true).to_s
    end
  end

  should "build a www uri from a domain" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal "http://www.whitehouse.gov", site.uri(false, true).to_s
    end
  end

  should "validate HTTPS support" do
    VCR.use_cassette "gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "gsa.gov"
      assert_equal false, site.https?
    end

    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal true, site.https?
    end
  end

  should "validate HTTPS enforcement" do
    VCR.use_cassette "cio.gov", :record => :new_episodes do
      site = SiteInspector.new "cio.gov"
      assert_equal true, site.enforce_https?
    end

    VCR.use_cassette "gsa.gov", :record => :new_episodes do
      site = SiteInspector.new "gsa.gov"
      assert_equal false, site.enforce_https?
    end
  end

  should "validate non-www support" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal true, site.non_www?
    end

    VCR.use_cassette "nasa.gov", :record => :new_episodes do
      site = SiteInspector.new "nasa.gov"
      assert_equal false, site.non_www?
    end
  end

  should "output json" do
    VCR.use_cassette "whitehouse.gov", :record => :new_episodes do
      site = SiteInspector.new "whitehouse.gov"
      assert_equal Hash, Oj.load(Oj.dump(site.to_hash)).class
    end
  end

  should "detect www redirects" do
    VCR.use_cassette "consumerfinance.gov", :record => :new_episodes do
      site = SiteInspector.new "consumerfinance.gov"
      assert_equal true, site.www?
    end
  end

  should "detect redirects" do
    VCR.use_cassette "cfpb.gov", :record => :new_episodes do
      site = SiteInspector.new "cfpb.gov"
      assert_equal true, site.redirect?
      assert_equal "www.consumerfinance.gov", site.redirect
    end
  end
end
