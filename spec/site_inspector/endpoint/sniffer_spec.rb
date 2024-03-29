# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Sniffer do
  def stub_header(header, value)
    allow(subject.endpoint.headers).to receive(:headers) { { header => value } }
  end

  def set_cookie(key, value)
    cookies = [
      CGI::Cookie.new(
        'name' => 'foo',
        'value' => 'bar',
        'domain' => 'example.com',
        'path' => '/'
      ),
      CGI::Cookie.new(
        'name' => key,
        'value' => value,
        'domain' => 'example.com',
        'path' => '/'
      )
    ].map(&:to_s)

    stub_request(:get, 'http://example.com/')
      .to_return(status: 200, body: '')

    stub_request(:head, 'http://example.com/')
      .to_return(status: 200, headers: { 'set-cookie' => cookies })
  end

  context 'stubbed body' do
    subject do
      body = <<-BODY
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
      BODY

      stub_request(:get, 'http://example.com/')
        .to_return(status: 200, body:)

      stub_request(:head, 'http://example.com/')
        .to_return(status: 200)
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      described_class.new(endpoint)
    end

    it 'sniffs' do
      sniff = subject.send(:sniff, :cms)
      expect(sniff).to be(:wordpress)
    end

    it 'detects the CMS' do
      expect(subject.framework).to be(:wordpress)
    end

    it 'detects the analytics' do
      expect(subject.analytics).to be(:google_analytics)
    end

    it 'detects javascript' do
      expect(subject.javascript).to be(:jquery)
    end

    it 'detects advertising' do
      expect(subject.advertising).to be(:adsense)
    end

    it 'knows wordpress is open source' do
      expect(subject.open_source?).to be(true)
    end
  end

  context 'no body' do
    subject do
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      described_class.new(endpoint)
    end

    it "knows when something isn't open source" do
      set_cookie('foo', 'bar')
      expect(subject.open_source?).to be(false)
    end

    it 'detects PHP' do
      set_cookie('PHPSESSID', '1234')
      expect(subject.framework).to be(:php)
      expect(subject.open_source?).to be(true)
    end

    it 'detects Expression Engine' do
      set_cookie('exp_csrf_token', '1234')
      expect(subject.framework).to be(:expression_engine)
      expect(subject.open_source?).to be(true)
    end

    it 'detects cowboy' do
      stub_request(:get, 'http://example.com/')
        .to_return(status: 200, body: '')

      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, headers: { 'server' => 'Cowboy' })

      expect(subject.framework).to be(:cowboy)
      expect(subject.open_source?).to be(true)
    end

    it 'detects ColdFusion' do
      cookies = [
        CGI::Cookie.new(
          'name' => 'CFID',
          'value' => '1234',
          'domain' => 'example.com',
          'path' => '/'
        ),
        CGI::Cookie.new(
          'name' => 'CFTOKEN',
          'value' => '5678',
          'domain' => 'example.com',
          'path' => '/'
        )
      ].map(&:to_s)

      stub_request(:get, 'http://example.com/')
        .to_return(status: 200, body: '')

      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, headers: { 'set-cookie' => cookies })

      expect(subject.framework).to be(:coldfusion)
      expect(subject.open_source?).to be(false)
    end
  end
end
