require "./" + File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  # Until we migrate to a non-curl-based HTTP library, this
  # will hit the network.

  def setup
    # allow network disk cache
    # Typhoeus::Config.cache = SiteInspectorCache.new
  end

  should "evaluate hsts preload" do
    details = SiteInspector.new("uspsoig.gov").http

    # full subdomains and preload
    assert_equal true, details[:hsts]
    assert_equal true, details[:hsts_entire_domain]
    assert_equal true, details[:hsts_entire_domain_preload]

    # just www and root
    details = SiteInspector.new("healthcare.gov").http
    assert_equal true, details[:hsts]
    assert_equal false, details[:hsts_entire_domain]
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

  should "detect default support for HTTPS even when not strictly enforced" do

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

end