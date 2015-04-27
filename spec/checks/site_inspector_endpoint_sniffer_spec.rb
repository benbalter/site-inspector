require 'spec_helper'

describe SiteInspector::Endpoint::Sniffer do

  subject do
    url = Addressable::URI.parse("https://example.com")
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
    response = Typhoeus::Response.new(:return_code => :ok, :body => body)
    response.request = Typhoeus::Request.new(url)

    SiteInspector::Endpoint::Sniffer.new(response)
  end

  it "returns the doc" do
    doc = subject.send(:doc)
    expect(doc.class).to eql(Nokogiri::HTML::Document)
    expect(doc.css("h1").text).to eql("Some page")
  end

  it "returns the body" do
    body = subject.send(:body)
    expect(body).to match("<h1>Some page</h1>")
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
