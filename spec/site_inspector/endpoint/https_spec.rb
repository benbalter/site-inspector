# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Https do
  subject do
    stub_request(:head, 'https://example.com/')
      .to_return(status: 200)
    endpoint = SiteInspector::Endpoint.new('https://example.com')
    allow(endpoint.response).to receive(:return_code).and_return(:ok)
    described_class.new(endpoint)
  end

  it 'knows the scheme' do
    expect(subject.send(:scheme)).to eql('https')
  end

  it 'knows if the scheme is https' do
    expect(subject.scheme?).to be(true)
    allow(subject).to receive(:scheme).and_return('http')
    expect(subject.scheme?).to be(false)
  end

  it "knows if it's valid" do
    expect(subject.valid?).to be(true)
  end

  it "knows when there's a bad chain" do
    expect(subject.bad_chain?).to be(false)

    url = Addressable::URI.parse('https://example.com')
    response = Typhoeus::Response.new(return_code: :ssl_cacert)
    response.request = Typhoeus::Request.new(url)

    allow(subject).to receive(:response) { response }
    expect(subject.bad_chain?).to be(true)
  end

  it "knows when there's a bad name" do
    expect(subject.bad_name?).to be(false)

    url = Addressable::URI.parse('https://example.com')
    response = Typhoeus::Response.new(return_code: :peer_failed_verification)
    response.request = Typhoeus::Request.new(url)

    allow(subject).to receive(:response) { response }
    expect(subject.bad_name?).to be(true)
  end
end
