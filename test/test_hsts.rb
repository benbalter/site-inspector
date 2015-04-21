require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspector < Minitest::Test

  def setup
    Typhoeus::Config.cache = SiteInspector::Cache.new
  end

  # Official HSTS RFC:
  # http://tools.ietf.org/html/rfc6797

  should "parse the gold standard hsts header" do
    gold = "max-age=31536000; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(gold)

    # parsed:
    assert_equal 31536000, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    # inferred:
    assert_equal true, hsts[:enabled]
    assert_equal true, hsts[:preload_ready]
  end

  should "parse other valid hsts headers" do
    # not observed - allow quoted strings
    gold = "max-age=\"31536000\"; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(gold)

    assert_equal 31536000, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal true, hsts[:preload_ready]


    # observed on uspsoig.gov - long, lowercase 'Subdomains'
    header = "max-age=63072000; includeSubdomains; preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 63072000, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal true, hsts[:preload_ready]

    # not observed anywhere, but a stray semicolon should change nothing
    header = "max-age=63072000; includeSubdomains; preload;"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 63072000, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal true, hsts[:preload_ready]

    # observed on fws.gov
    header = "max-age=0"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 0, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # not observed, but just in case
    header = "max-age=0; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 0, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # observed on www.bfelob.gov - 1 hour
    header = "max-age=86400"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 86400, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # observed on wh.gov - not long enough
    header = "max-age=3600;includeSubDomains;preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 3600, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal false, hsts[:preload_ready] # too short!

    # observed on healthcare.gov - no subdomains
    header = "max-age=31536000;preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 31536000, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal true, hsts[:preload]
    assert_equal true, hsts[:enabled]
    # judgment call: preload-ready means *automatically* preload-ready
    assert_equal false, hsts[:preload_ready]

    # observed on jamesmadison.gov - just includeSubDomains
    header = "includeSubDomains"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]
  end

  should "handle invalid hsts headers" do
    # observed on whitehouse.gov
    header = "max-age=3600;include_subdomains"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal 3600, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal true, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # observed on www.tedcruz.org - no commas allowed!
    # RFC specifies that invalid syntax is unprocessable,
    # so no HSTS. Spaces are not valid characters unless helping
    # separating directives, which only semicolons can do.
    header = "max-age=15552000, includeSubDomains"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # not observed anywhere (yet!)
    header = "max-age3600; includeSubDomains"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal true, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # not observed - single quotes are not allowed
    header = "max-age='31536000'; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # not observed - neither is just one quote
    header = "max-age=\"31536000; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]

    # not observed - no quotes on max-age
    header = "\"max-age\"=31536000; includeSubDomains; preload"
    hsts = SiteInspector.hsts_parse(header)

    assert_equal nil, hsts[:max_age]
    assert_equal false, hsts[:include_subdomains]
    assert_equal false, hsts[:preload]
    assert_equal false, hsts[:enabled]
    assert_equal false, hsts[:preload_ready]


    # fuzzing!
    ["312384761283746", 0, nil, "", "-1", "$!#@%!#}"].each do |header|
      hsts = SiteInspector.hsts_parse(header)
      assert_equal nil, hsts[:max_age], header
      assert_equal false, hsts[:include_subdomains], header
      assert_equal false, hsts[:preload], header
      assert_equal false, hsts[:enabled], header
      assert_equal false, hsts[:preload_ready], header
    end
  end
end
