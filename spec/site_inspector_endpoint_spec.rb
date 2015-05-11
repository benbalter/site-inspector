require 'spec_helper'

describe SiteInspector::Endpoint do

  subject { SiteInspector::Endpoint.new("http://example.com") }

  it "downcases the host" do
    endpoint = SiteInspector::Endpoint.new("http://EXAMPLE.com")
    expect(endpoint.host).to eql("example.com")
  end

  it "strips www from the host" do
    endpoint = SiteInspector::Endpoint.new("http://www.example.com")
    expect(endpoint.host).to eql("example.com")
  end

  it "returns the uri" do
    expect(subject.uri.to_s).to eql("http://example.com")
  end

  it "knows if an endpoint is www" do
    expect(subject.www?).to eql(false)
    expect(subject.root?).to eql(true)

    endpoint = SiteInspector::Endpoint.new("http://www.example.com")
    expect(endpoint.www?).to eql(true)
    expect(endpoint.root?).to eql(false)
  end

  it "knows if an endpoint is http" do
    stub_request(:get, "http://example.com/").
      to_return(:status => 200, :body => "content")

    stub_request(:get, "https://example.com/").
      to_return(:status => 500, :body => "content")

    expect(subject.https?).to eql(false)
    expect(subject.http?).to eql(true)
  end

  it "knows if an endpoint is https" do
    stub_request(:get, "http://example.com/").
      to_return(:status => 200, :body => "content")

    stub_request(:get, "https://example.com/").
      to_return(:status => 200, :body => "content")

    endpoint = SiteInspector::Endpoint.new("https://example.com")
    expect(endpoint.https?).to eql(true)
    expect(endpoint.http?).to eql(false)
  end

  it "knows the scheme" do
    expect(subject.scheme).to eql("http")

    endpoint = SiteInspector::Endpoint.new("https://example.com")
    expect(endpoint.scheme).to eql("https")
  end

  context "requests" do

    it "requests a URL" do
      stub = stub_request(:get, "http://example.com/").
           to_return(:status => 200, :body => "content")

      expect(subject.request.body).to eql("content")
      expect(stub).to have_been_requested
    end

    it "requests a requested path" do
      stub = stub_request(:get, "http://example.com/foo").
           to_return(:status => 200, :body => "content")

      expect(subject.request(:path => "foo").body).to eql("content")
      expect(stub).to have_been_requested
    end

    it "requests with typhoeus options" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 301, :headers => { :location => "http://example.com/foo" } )

      response = subject.request(:followlocation => true)
      expect(response.request.options[:followlocation]).to eql(true)
    end

    it "returns the response" do
      stub = stub_request(:get, "http://example.com/").
           to_return(:status => 200, :body => "content")

      expect(subject.response.body).to eql("content")
      expect(subject.response.body).to eql("content")
      expect(stub).to have_been_requested.once
    end

    it "knows if there's a response" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 200, :body => "content")

      expect(subject.response?).to eql(true)
    end

    it "knows when there's not a response" do
      allow(subject).to receive(:response) { Typhoeus::Response.new(code: 0) }
      expect(subject.response?).to eql(false)

      allow(subject).to receive(:response) { Typhoeus::Response.new(:return_code => :operation_timedout) }
      expect(subject.response?).to eql(false)
    end

    it "knows the response code" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 200)

      expect(subject.response_code).to eql("200")
    end

    it "knows if a response has timed out" do
      allow(subject).to receive(:response) { Typhoeus::Response.new(:return_code => :operation_timedout) }
      expect(subject.timed_out?).to eql(true)
    end

    it "considers a 200 response code to be up" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 200)

      expect(subject.up?).to eql(true)
      expect(subject.down?).to eql(false)

    end

    it "considers a 301 response code to be up" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 301)

      expect(subject.up?).to eql(true)
      expect(subject.down?).to eql(false)
    end

    it "doesn't consider a 500 response code to be up" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 500)

      expect(subject.up?).to eql(false)
      expect(subject.down?).to eql(true)
    end
  end

  context "redirects" do
    it "knows when there's a redirect" do
      stub_request(:get, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "http://www.example.com" } )

      expect(subject.redirect?).to eql(true)
    end

    it "returns the redirect" do
      stub_request(:get, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "http://www.example.com" } )

      stub_request(:get, "http://www.example.com/").
        to_return(:status => 200)

      expect(subject.redirect.uri.to_s).to eql("http://www.example.com")
    end

    it "handles relative redirects" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 301, :headers => { :location => "/foo" } )

      expect(subject.redirect?).to eql(false)
    end

    it "handles relative redirects without a leading slash" do
      stub_request(:get, "http://example.com/").
           to_return(:status => 301, :headers => { :location => "foo" } )

      expect(subject.redirect?).to eql(false)
    end

    it "knows what it resolves to" do
      stub_request(:get, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "http://www.example.com" } )

      stub_request(:get, "http://www.example.com/").
        to_return(:status => 200)

      expect(subject.redirect?).to eql(true)
      expect(subject.resolves_to.uri.to_s).to eql("http://www.example.com")
    end

    it "detects external redirects" do
      stub_request(:get, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "http://www.example.gov" } )

      expect(subject.redirect?).to eql(true)
      expect(subject.external_redirect?).to eql(true)
    end

    it "knows internal redirects are not external redirects" do
      stub_request(:get, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "https://example.com" } )

      expect(subject.external_redirect?).to eql(false)
    end
  end

  context "checks" do
    it "identifies checks" do
      expect(SiteInspector::Endpoint.checks.count).to eql(6)
    end

    SiteInspector::Endpoint.checks.each do |check|
      it "responds to the #{check} check" do

        stub_request(:get, "http://example.com/").
          to_return(:status => 200)

        expect(subject.send(check.name)).to_not be_nil
        expect(subject.send(check.name).class).to eql(check)

      end
    end
  end
end
