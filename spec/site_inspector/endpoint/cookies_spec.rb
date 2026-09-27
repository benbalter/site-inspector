# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Cookies do
  context 'without cookies' do
    subject do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '')
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      described_class.new(endpoint)
    end

    it 'knows when there are no cookies' do
      expect(subject.cookies?).to be(false)
      expect(subject.all).to be_nil
    end
  end

  context 'with cookies' do
    subject do
      cookies = [
        'foo=bar; domain=example.com; path=/',
        'foo2=bar2; domain=example.com; path=/'
      ]

      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '', headers: { 'set-cookie' => cookies })
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      described_class.new(endpoint)
    end

    it 'knows when there are cookies' do
      expect(subject.cookies?).to be(true)
      expect(subject.all.count).to be(2)
    end

    it 'returns a cookie by name' do
      expect(subject['foo'].to_s).to match(/foo=bar/)
    end

    it "knows cookies aren't secure" do
      expect(subject.secure?).to be(false)
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
      described_class.new(endpoint)
    end

    it 'knows cookies are secure' do
      expect(subject.secure?).to be(true)
    end

    it 'parses cookie attributes' do
      expect(subject['foo'].secure?).to be(true)
      expect(subject['foo'].httponly?).to be(true)
      expect(subject['foo2'].secure?).to be(false)
    end
  end

  context 'with Secure and HttpOnly on different cookies' do
    subject do
      cookies = [
        'foo=bar; domain=example.com; path=/; secure',
        'foo2=bar2; domain=example.com; path=/; HttpOnly'
      ]
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: '', headers: { 'set-cookie' => cookies })
      endpoint = SiteInspector::Endpoint.new('http://example.com')
      described_class.new(endpoint)
    end

    it "doesn't count split flags as secure" do
      expect(subject.secure?).to be(false)
    end
  end
end
