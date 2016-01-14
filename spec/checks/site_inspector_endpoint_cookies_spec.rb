require 'spec_helper'

describe SiteInspector::Endpoint::Cookies do
  context 'without cookies' do
    subject do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '')
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      SiteInspector::Endpoint::Cookies.new(endpoint)
    end

    it 'knows when there are no cookies' do
      expect(subject.cookies?).to eql(false)
      expect(subject.all).to eql(nil)
    end
  end

  context 'with cookies' do
    subject do
      cookies = [
        CGI::Cookie.new(
          'name'   => 'foo',
          'value'  => 'bar',
          'domain' => 'example.com',
          'path'   => '/'
        ),
        CGI::Cookie.new(
          'name'   => 'foo2',
          'value'  => 'bar2',
          'domain' => 'example.com',
          'path'   => '/'
        )
      ].map(&:to_s)

      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '', headers: { 'set-cookie' => cookies })
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      SiteInspector::Endpoint::Cookies.new(endpoint)
    end

    it 'knows when there are cookies' do
      expect(subject.cookies?).to eql(true)
      expect(subject.all.count).to eql(2)
    end

    it 'returns a cookie by name' do
      expect(subject['foo'].to_s).to match(/foo=bar/)
    end

    it "knows cookies aren't secure" do
      expect(subject.secure?).to eql(false)
    end
  end

  context 'with secure cookies' do
    subject do
      cookies = [
        'foo=bar; domain=example.com; path=/; secure; HttpOnly',
        'foo2=bar2; domain=example.com; path=/'
      ]
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '', headers: { 'set-cookie' => cookies })
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      SiteInspector::Endpoint::Cookies.new(endpoint)
    end

    it 'knows cookies are secure' do
      expect(subject.secure?).to eql(true)
    end
  end
end
