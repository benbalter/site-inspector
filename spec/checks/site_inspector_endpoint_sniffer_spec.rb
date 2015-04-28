require 'spec_helper'

describe SiteInspector::Endpoint::Sniffer do

  subject do
    body = <<-eos
      <html>
        <head>
          <link rel='stylesheet' href='/wp-content/themes/foo/style.css type='text/css' media='all' />
        </head>
        <body>
          <h1>Some page</h1>
          <script>
            jQuery(); googletag.pubads();
          </script>
          <script>
            var _gaq=[['_setAccount','UA-12345678-1'],['_trackPageview']];
            (function(d,t){var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
            g.src=('https:'==location.protocol?'//ssl':'//www')+'.google-analytics.com/ga.js';
            s.parentNode.insertBefore(g,s)}(document,'script'));
          </script>
        </body>
      </html>
    eos

    stub_request(:get, "http://example.com/").
      to_return(:status => 200, :body => body )
    endpoint = SiteInspector::Endpoint.new("http://example.com")
    SiteInspector::Endpoint::Sniffer.new(endpoint)
  end

  it "sniffs" do
    sniff = subject.send(:sniff, :cms)
    expect(sniff.keys.first).to eql(:wordpress)
  end

  it "detects the CMS" do
    expect(subject.cms.keys.first).to eql(:wordpress)
  end

  it "detects the analytics" do
    expect(subject.analytics.keys.first).to eql(:google_analytics)
  end

  it "detects javascript" do
    expect(subject.javascript.keys.first).to eql(:jquery)
  end

  it "detects advertising" do
    expect(subject.advertising.keys.first).to eql(:adsense)
  end
end
