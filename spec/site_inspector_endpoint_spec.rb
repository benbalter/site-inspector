# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint do
  subject { described_class.new('http://example.com') }

  it 'downcases the host' do
    endpoint = described_class.new('http://EXAMPLE.com')
    expect(endpoint.host.to_s).to eql('example.com')
  end

  it 'strips www from the host' do
    skip
    endpoint = described_class.new('http://www.example.com')
    expect(endpoint.host.to_s).to eql('example.com')
  end

  it 'returns the uri' do
    expect(subject.uri.to_s).to eql('http://example.com/')
  end

  it 'knows if an endpoint is www' do
    expect(subject.www?).to be(false)
    expect(subject.root?).to be(true)

    endpoint = described_class.new('http://www.example.com')
    expect(endpoint.www?).to be(true)
    expect(endpoint.root?).to be(false)
  end

  it 'knows if an endpoint is http' do
    stub_request(:head, 'http://example.com/')
      .to_return(status: 200, body: 'content')

    stub_request(:head, 'https://example.com/')
      .to_return(status: 500, body: 'content')

    expect(subject.https?).to be(false)
    expect(subject.http?).to be(true)
  end

  it 'knows if an endpoint is https' do
    stub_request(:head, 'http://example.com/')
      .to_return(status: 200, body: 'content')

    stub_request(:head, 'https://example.com/')
      .to_return(status: 200, body: 'content')

    endpoint = described_class.new('https://example.com')
    expect(endpoint.https?).to be(true)
    expect(endpoint.http?).to be(false)
  end

  it 'knows the scheme' do
    expect(subject.scheme).to eql('http')

    endpoint = described_class.new('https://example.com')
    expect(endpoint.scheme).to eql('https')
  end

  context 'requests' do
    it 'requests a URL' do
      stub = stub_request(:head, 'http://example.com/')
             .to_return(status: 200, body: 'content')

      expect(subject.request.body).to eql('content')
      expect(stub).to have_been_requested
    end

    it 'requests a requested path' do
      stub = stub_request(:head, 'http://example.com/foo')
             .to_return(status: 200, body: 'content')

      expect(subject.request(path: 'foo').body).to eql('content')
      expect(stub).to have_been_requested
    end

    it 'requests with typhoeus options' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'http://example.com/foo' })

      response = subject.request(followlocation: true)
      expect(response.request.options[:followlocation]).to be(true)
    end

    it 'returns the response' do
      stub = stub_request(:head, 'http://example.com/')
             .to_return(status: 200, body: 'content')

      expect(subject.response.body).to eql('content')
      expect(subject.response.body).to eql('content')
      expect(stub).to have_been_requested.once
    end

    it "knows if there's a response" do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200, body: 'content')

      expect(subject.responds?).to be(true)
    end

    it "knows when there's not a response" do
      allow(subject).to receive(:response) { Typhoeus::Response.new(code: 0) }
      expect(subject.responds?).to be(false)

      allow(subject).to receive(:response) { Typhoeus::Response.new(return_code: :operation_timedout) }
      expect(subject.responds?).to be(false)
    end

    it 'knows the response code' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200)

      expect(subject.response_code).to eql('200')
    end

    it 'knows if a response has timed out' do
      allow(subject).to receive(:response) { Typhoeus::Response.new(return_code: :operation_timedout) }
      expect(subject.timed_out?).to be(true)
    end

    it 'considers a 200 response code to be live and a response' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 200)

      expect(subject.up?).to be(true)
      expect(subject.responds?).to be(true)
    end

    it 'considers a 301 response code to be live and a response' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301)

      expect(subject.up?).to be(true)
      expect(subject.responds?).to be(true)
    end

    it 'considers a 404 response code to be down but a response' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 404)

      expect(subject.up?).to be(false)
      expect(subject.responds?).to be(true)
    end

    it 'considers a 500 response code to be down but a response' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 500)

      expect(subject.up?).to be(false)
      expect(subject.responds?).to be(true)
    end

    it 'considers a 0 response code (error) to down and unresponsive' do
      allow(subject).to receive(:response) { Typhoeus::Response.new(code: 0) }

      expect(subject.up?).to be(false)
      expect(subject.responds?).to be(false)
    end

    it 'considers a timeout to be down and unresponsive' do
      allow(subject).to receive(:response) { Typhoeus::Response.new(return_code: :operation_timedout) }

      expect(subject.up?).to be(false)
      expect(subject.responds?).to be(false)
    end
  end

  context 'redirects' do
    it "knows when there's a redirect" do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'http://www.example.com' })

      expect(subject.redirect?).to be(true)
    end

    it 'returns the redirect' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'http://www.example.com' })

      stub_request(:head, 'http://www.example.com/')
        .to_return(status: 200)

      expect(subject.redirect.uri.to_s).to eql('http://www.example.com/')
    end

    it 'handles relative redirects' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: '/foo' })

      expect(subject.redirect?).to be(false)
    end

    it 'handles relative redirects without a leading slash' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'foo' })

      expect(subject.redirect?).to be(false)
    end

    it 'knows what it resolves to' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'http://www.example.com' })

      stub_request(:head, 'http://www.example.com/')
        .to_return(status: 200)

      expect(subject.redirect?).to be(true)
      expect(subject.resolves_to.uri.to_s).to eql('http://www.example.com/')
    end

    it 'detects external redirects' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'http://www.example.gov' })

      stub_request(:head, 'http://www.example.gov')
        .to_return(status: 200)

      expect(subject.redirect?).to be(true)
      expect(subject.external_redirect?).to be(true)
    end

    it 'knows internal redirects are not external redirects' do
      stub_request(:head, 'http://example.com/')
        .to_return(status: 301, headers: { location: 'https://example.com' })

      stub_request(:head, 'https://example.com/')
        .to_return(status: 200)

      expect(subject.external_redirect?).to be(false)
    end
  end

  context 'checks' do
    it 'identifies checks' do
      expected = 9
      pa11y = SiteInspector::Endpoint::Accessibility.pa11y?
      expected -= 1 unless pa11y
      expect(described_class.checks.count).to eql(expected)
    end

    described_class.checks.each do |check|
      it "responds to the #{check} check" do
        stub_request(:head, 'http://example.com/')
          .to_return(status: 200)

        expect(subject.send(check.name)).not_to be_nil
        expect(subject.send(check.name).class).to eql(check)
      end
    end
  end
end
