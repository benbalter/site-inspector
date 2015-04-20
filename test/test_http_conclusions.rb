require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  # Until we migrate to a non-curl-based HTTP library, this
  # will hit the network.

  def setup
    # allow network disk cache
    # Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "evaluate hsts preload" do
    # full subdomains and preload
    details = SiteInspector.new("uspsoig.gov").http
    assert_equal true, details[:hsts]
    assert_equal true, details[:hsts_entire_domain]
    assert_equal true, details[:hsts_entire_domain_preload]

    # just www and root
    details = SiteInspector.new("healthcare.gov").http
    assert_equal true, details[:hsts]
    assert_equal false, details[:hsts_entire_domain]
    assert_equal false, details[:hsts_entire_domain_preload]

    # max-age=0 doesn't get you hsts
    details = SiteInspector.new("c3.gov").http
    assert_equal false, details[:hsts]
    assert_equal false, details[:hsts_entire_domain]
    assert_equal false, details[:hsts_entire_domain_preload]

    # wh.gov uses "max-age=3600;includeSubDomains;preload"
    # not long enough!
    details = SiteInspector.new("wh.gov").http
    assert_equal true, details[:hsts]
    assert_equal true, details[:hsts_entire_domain]
    assert_equal false, details[:hsts_entire_domain_preload]
  end

  should "ignore a 404 root for a proper www" do
    # https://asc.gov is 404, http
    details = SiteInspector.new("asc.gov").http

    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :https, details[:canonical_protocol]
  end

  should "detect canonical www sites whose http sites are both down" do
    # searanchlakesflorida.gov has:
    #   * http:// -> invalid https://
    #   * http://www -> valid https://www
    details = SiteInspector.new("searanchlakesflorida.gov").http

    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :https, details[:canonical_protocol]

    # nasa.gov has no DNS entries for the bare domain
    details = SiteInspector.new("nasa.gov").http
    assert_equal true, details[:up]
    assert_equal :www, details[:canonical_endpoint]
    assert_equal :http, details[:canonical_protocol]
  end

  should "detect apathetic support for HTTPS" do
    # nist.gov supports HTTPS but 404's on root and www
    details = SiteInspector.new("nist.gov").http

    assert_equal true, details[:up]
    assert_equal :http, details[:canonical_protocol]

    assert_equal true, details[:support_https]
    assert_equal false, details[:downgrade_https]
    assert_equal false, details[:default_https]
    assert_equal false, details[:enforce_https]
  end

  should "detect downgraded support for HTTPS" do
    # aoc.gov downgrades all HTTPS to http://www
    details = SiteInspector.new("aoc.gov").http

    assert_equal true, details[:up]
    assert_equal :http, details[:canonical_protocol]

    assert_equal true, details[:support_https]
    assert_equal true, details[:downgrade_https]
    assert_equal false, details[:default_https]
    assert_equal false, details[:enforce_https]
  end

  should "associate relative redirects with its domain's properties" do
    # dap.digitalgov.gov redirects relatively, stays HTTPS and not www
    details = SiteInspector.new("dap.digitalgov.gov").http

    assert_equal true, details[:up]
    assert_equal :https, details[:canonical_protocol]

    endpoint = details[:endpoints][:https][:root]
    assert_equal true, endpoint[:redirect]
    assert_equal true, endpoint[:headers]["location"].start_with?("/")
    assert_equal false, endpoint[:redirect_immediately_to_www]
    assert_equal true, endpoint[:redirect_immediately_to_https]

    assert_equal false, details[:redirect]
    assert_equal false, details[:downgrade_https]

    # TODO: http example, esp http://www example
  end

  should "detect default support for HTTPS even when not strictly enforced" do
    # ecpic.gov is so good but redirects http:// -> http://www first
    details = SiteInspector.new("ecpic.gov").http

    assert_equal true, details[:up]
    assert_equal :https, details[:canonical_protocol]

    assert_equal true, details[:support_https]
    assert_equal false, details[:downgrade_https]
    assert_equal true, details[:default_https]
    assert_equal false, details[:enforce_https]
  end


  should "detect strictly enforced valid HTTPS" do
    # uspsoig.gov is perfect
    details = SiteInspector.new("uspsoig.gov").http

    assert_equal true, details[:up]
    assert_equal :https, details[:canonical_protocol]

    assert_equal true, details[:support_https]
    assert_equal false, details[:downgrade_https]
    assert_equal true, details[:default_https]
    assert_equal true, details[:enforce_https]
  end

  should "detect strictly enforced but invalid HTTPS" do
    # clinicaltrial.gov redirects everything to https://
    # but its cert is only good for clinicaltrials.gov (plural)
    # strictly enforced but not supported!
    details = SiteInspector.new("clinicaltrial.gov").http

    assert_equal true, details[:up]
    assert_equal :http, details[:canonical_protocol]

    assert_equal false, details[:support_https]
    assert_equal false, details[:downgrade_https]
    assert_equal false, details[:default_https]
    assert_equal true, details[:enforce_https]
  end

  should "conclude that a domain forces HTTPS even if its HTTPS endpoints downgrade" do

    # nationalserviceresources.gov redirects HTTP->HTTPS, but then
    # its HTTPS endpoints redirect to external HTTP endpoints. (nationalservice.gov)
    # Under our current definition, this domain enforces HTTPS.
    #
    # This makes sense if you consider each domain as responsible for
    # itself: if nationalservice.gov implemented HSTS, then an informed
    # client redirected to it over HTTP would not be exposed.
    #
    # It's still obviously not ideal. But a redirector domain shouldn't
    # be "punished" for doing its job as securely as it can, if the domain
    # it redirects to doesn't use HTTPS/HSTS.
    details = SiteInspector.new("nationalserviceresources.gov").http

    assert_equal true, details[:up]
    assert_equal :https, details[:canonical_protocol]
    assert_equal :www, details[:canonical_endpoint]

    assert_equal true, details[:support_https]
    assert_equal false, details[:downgrade_https]
    assert_equal true, details[:default_https]
    assert_equal true, details[:enforce_https]
  end

  should "only need one endpoint up to be up" do
    # intelink.gov is only up at https://www
    details = SiteInspector.new("intelink.gov").http

    assert_equal true, details[:endpoints][:https][:www][:up]
    assert_equal false, details[:endpoints][:http][:www][:up]
    assert_equal false, details[:endpoints][:https][:root][:up]
    assert_equal false, details[:endpoints][:http][:root][:up]

    assert_equal true, details[:up]
  end

  should "be a redirect even if one endpoint is a 403" do
    # businessusa.gov redirects to business.usa.gov,
    # except on https:// where it's a 403 (and bad cert)

    details = SiteInspector.new("businessusa.gov").http

    assert_equal true, details[:redirect]
    assert_equal "http://business.usa.gov/", details[:redirect_to]
  end

  should "be a redirect even if the HTTPS endpoints are busted" do
    # atvsafety.gov redirects on HTTP, misconfigured on HTTPS

    details = SiteInspector.new("atvsafety.gov").http

    assert_equal true, details[:redirect]
    assert_equal true, details[:redirect_to].start_with?("http://www.cpsc.gov")

    # cancernet.gov redirects to cancer.gov on HTTP,
    # but its HTTPS www is down, and its HTTPS root endpoint busted
    details = SiteInspector.new("cancernet.gov").http

    assert_equal false, details[:endpoints][:https][:www][:up]
    assert_equal true, details[:endpoints][:https][:root][:https_bad_name]

    assert_equal true, details[:redirect]
    assert_equal true, details[:redirect_to].include?("cancer.gov")

  end

  should "be considered at www even if https root is busted" do
    # base case -- normal www canonical domain
    details = SiteInspector.new("whitehouse.gov").http

    assert_equal true, details[:endpoints][:https][:root][:redirect]
    assert_equal true, details[:endpoints][:https][:root][:redirect_immediately_to_www]

    assert_equal true, details[:endpoints][:http][:root][:redirect]
    assert_equal true, details[:endpoints][:http][:root][:redirect_immediately_to_www]

    # esc.gov redirects http:// -> http://www, but https:// is misconfigured
    details = SiteInspector.new("esc.gov").http

    assert_equal 200, details[:endpoints][:https][:root][:status]
    assert_equal true, details[:endpoints][:https][:root][:https_bad_name]

    assert_equal true, details[:endpoints][:http][:root][:redirect]
    assert_equal true, details[:endpoints][:http][:root][:redirect_immediately_to_www]

    assert_equal :www, details[:canonical_endpoint]
  end

end
