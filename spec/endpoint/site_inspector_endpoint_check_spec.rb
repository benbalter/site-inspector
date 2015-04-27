require 'spec_helper'

describe SiteInspector::Endpoint::Check do

  subject do
    url = Addressable::URI.parse("http://example.com")
    response = Typhoeus::Response.new
    response.request = Typhoeus::Request.new(url)
    SiteInspector::Endpoint::Check.new(response)
  end

  it "returns the response" do
    expect(subject.response.class).to eql(Typhoeus::Response)
  end

  it "returns the request" do
    expect(subject.request.class).to eql(Typhoeus::Request)
  end

  it "returns the host" do
    expect(subject.host).to eql("example.com")
  end

  it "returns its name" do
    expect(subject.name).to eql(:check)
  end

  it "returns the instance name" do
    expect(SiteInspector::Endpoint::Check.name).to eql(:check)
  end
end
