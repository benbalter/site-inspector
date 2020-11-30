# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Check do
  subject do
    stub_request(:head, 'http://example.com/').to_return(status: 200)
    endpoint = SiteInspector::Endpoint.new('http://example.com')
    described_class.new(endpoint)
  end

  it 'returns the endpoint' do
    expect(subject.endpoint.class).to eql(SiteInspector::Endpoint)
  end

  it 'returns the response' do
    expect(subject.response.class).to eql(Typhoeus::Response)
  end

  it 'returns the request' do
    expect(subject.request.class).to eql(Typhoeus::Request)
  end

  it 'returns the host' do
    expect(subject.host).to eql('example.com')
  end

  it 'returns its name' do
    expect(subject.name).to be(:check)
  end

  it 'returns the instance name' do
    expect(described_class.name).to be(:check)
  end

  it 'enables and disables the check' do
    expect(described_class.enabled?).to be(true)
    described_class.enabled = false
    expect(described_class.enabled?).to be(false)
    described_class.enabled = true
  end
end
