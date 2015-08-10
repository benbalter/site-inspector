require 'spec_helper'

describe SiteInspector::Domain do

  subject { SiteInspector::Domain.new("example.com") }

  context "domain parsing" do
    it "downcases the domain" do
      domain = SiteInspector::Domain.new("EXAMPLE.com")
      expect(domain.host).to eql("example.com")
    end

    it "strips http from the domain" do
      domain = SiteInspector::Domain.new("http://example.com")
      expect(domain.host).to eql("example.com")
    end

    it "strips https from the domain" do
      domain = SiteInspector::Domain.new("https://example.com")
      expect(domain.host).to eql("example.com")
    end

    it "strips www from the domain" do
      domain = SiteInspector::Domain.new("www.example.com")
      expect(domain.host).to eql("example.com")
    end

    it "strips http://www from the domain" do
      domain = SiteInspector::Domain.new("http://www.example.com")
      expect(domain.host).to eql("example.com")
    end

    it "strips paths from the domain" do
      domain = SiteInspector::Domain.new("http://www.example.com/foo")
      expect(domain.host).to eql("example.com")
    end

    it "strips trailing slashes from the domain" do
      domain = SiteInspector::Domain.new("http://www.example.com/")
      expect(domain.host).to eql("example.com")
    end
  end

  context "endpoints" do
    it "generates the endpoints" do
      endpoints = subject.endpoints
      expect(endpoints.count).to eql(4)
      expect(endpoints[0].to_s).to eql("https://example.com/")
      expect(endpoints[1].to_s).to eql("https://www.example.com/")
      expect(endpoints[2].to_s).to eql("http://example.com/")
      expect(endpoints[3].to_s).to eql("http://www.example.com/")
    end
  end

  it "knows the canonical domain" do
    stub_request(:head, "https://example.com/").to_return(:status => 500)
    stub_request(:head, "https://www.example.com/").to_return(:status => 500)
    stub_request(:head, "http://www.example.com/").to_return(:status => 200)
    stub_request(:head, "http://example.com/").to_return(:status => 200)
    expect(subject.canonical_endpoint.to_s).to eql("http://example.com/")
  end

  it "knows if a domain is a government domain" do
    expect(subject.government?).to eql(false)

    domain = SiteInspector::Domain.new("whitehouse.gov")
    expect(domain.government?).to eql(true)
  end

  context "up" do
    it "considers a domain up if at least one endpoint is up" do
      subject.endpoints.each do |endpoint|
        unless endpoint.uri.to_s.start_with?("http://www")
          allow(endpoint).to receive(:response) { Typhoeus::Response.new(code: 0) }
        end
      end

      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.up?).to eql(true)
    end

    it "doesn't consider a domain up when all endpoints are down" do
      subject.endpoints.each do |endpoint|
        allow(endpoint).to receive(:response) { Typhoeus::Response.new(code: 0) }
      end

      expect(subject.up?).to eql(false)
    end
  end

  context "up" do
    it "considers a domain up if at least one endpoint is up" do
      stub_request(:head, "https://example.com/").to_return(:status => 500)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.up?).to eql(true)
    end

    it "doesn't consider a domain up if all endpoints are down" do
      stub_request(:head, "https://example.com/").to_return(:status => 500)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 500)

      expect(subject.up?).to eql(false)
    end
  end

  context "www" do
    it "considers a site www when at least one endpoint is www" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.www?).to eql(true)
    end

    it "doesn't consider a site www when no endpoint is www" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 200)
      stub_request(:head, "http://www.example.com/").to_return(:status => 500)

      expect(subject.www?).to eql(false)
    end
  end

  context "root" do
    it "considers a domain root if you can connect without www" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 500)

      expect(subject.root?).to eql(true)
    end

    it "doesn't call a www-only domain root" do
      stub_request(:head, "https://example.com/").to_return(:status => 500)
      stub_request(:head, "https://www.example.com/").to_return(:status => 200)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.root?).to eql(false)
    end
  end

  context "https" do
    it "knows when a domain supports https" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 200)
      stub_request(:head, "http://example.com/").to_return(:status => 200)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)
      allow(subject.endpoints.first.https).to receive(:valid?) { true }

      expect(subject.https?).to eql(true)
    end

    it "knows when a domain doesn't support https" do
      stub_request(:head, "https://example.com/").to_return(:status => 500)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 200)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.https?).to eql(false)
    end

    it "considers HTTPS inforced when no http endpoint responds" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 500)

      #expect(subject.enforces_https?).to eql(true)
    end

    it "doesn't consider HTTPS inforced when an http endpoint responds" do
      stub_request(:head, "https://example.com/").to_return(:status => 200)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").to_return(:status => 500)
      stub_request(:head, "http://www.example.com/").to_return(:status => 200)

      expect(subject.enforces_https?).to eql(false)
    end

    it "detects when a domain downgrades to http" do
      # TODO
    end

    it "detects when a domain enforces https" do
      # TODO
    end
  end

  context "canonical" do
    context "www" do
      it "detects a domain as canonically www when root is down" do
        stub_request(:head, "https://example.com/").to_return(:status => 500)
        stub_request(:head, "https://www.example.com/").to_return(:status => 500)
        stub_request(:head, "http://example.com/").to_return(:status => 500)
        stub_request(:head, "http://www.example.com/").to_return(:status => 200)

        expect(subject.canonically_www?).to eql(true)
      end

      it "detects a domain as canonically www when root redirects" do
        stub_request(:head, "https://example.com/").to_return(:status => 500)
        stub_request(:head, "https://www.example.com/").to_return(:status => 500)
        stub_request(:head, "http://example.com/").
          to_return(:status => 301, :headers => { :location => "http://www.example.com" } )
        stub_request(:head, "http://www.example.com/").to_return(:status => 200)

        expect(subject.canonically_www?).to eql(true)
      end
    end

    context "https" do
      it "detects a domain as canonically https when http is down" do
        stub_request(:head, "https://example.com/").to_return(:status => 200)
        stub_request(:head, "https://www.example.com/").to_return(:status => 200)
        stub_request(:head, "http://example.com/").to_return(:status => 500)
        stub_request(:head, "http://www.example.com/").to_return(:status => 500)
        allow(subject.endpoints.first.https).to receive(:valid?) { true }

        expect(subject.canonically_https?).to eql(true)
      end

      it "detects a domain as canonically https when http redirect" do
        stub_request(:head, "https://example.com/").to_return(:status => 200)
        stub_request(:head, "https://www.example.com/").to_return(:status => 200)
        stub_request(:head, "http://example.com/").
          to_return(:status => 301, :headers => { :location => "https://example.com" } )
        stub_request(:head, "http://www.example.com/").to_return(:status => 500)
        allow(subject.endpoints.first.https).to receive(:valid?) { true }

        expect(subject.canonically_https?).to eql(true)
      end
    end
  end

  context "redirects" do
    it "knows when a domain redirects" do
      stub_request(:head, "https://example.com/").to_return(:status => 500)
      stub_request(:head, "https://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://example.com/").
        to_return(:status => 301, :headers => { :location => "http://foo.example.com" } )
      stub_request(:head, "http://www.example.com/").to_return(:status => 500)
      stub_request(:head, "http://foo.example.com/").to_return(:status => 200)

      expect(subject.redirect?).to eql(true)
    end
  end

  context "hsts" do
    it "enabled" do

    end

    it "subdomains" do

    end

    it "preload ready" do

    end
  end

  it "returns the host as a string" do
    expect(subject.to_s).to eql("example.com")
  end
end
