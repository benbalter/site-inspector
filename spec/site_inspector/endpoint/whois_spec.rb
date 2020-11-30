# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Whois do
  subject do
    stub_request(:head, site).to_return(status: 200)
    endpoint = SiteInspector::Endpoint.new(site)
    described_class.new(endpoint)
  end

  let(:site) { 'https://example.com' }

  it 'returns the whois for the IP' do
    expect(subject.ip).to match(/Derrick Sawyer/)
  end

  it 'returns the whois for the domain' do
    expect(subject.domain).to match(/Domain Name: EXAMPLE\.COM/)
  end

  it 'returns the hash' do
    expect(subject.to_h[:domain].keys.first).to eql('Domain Name')
    expect(subject.to_h[:domain].values.first).to eql('EXAMPLE.COM')
  end
end
