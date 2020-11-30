# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Wappalyzer do
  subject { described_class.new(endpoint) }

  let(:domain) { 'http://ben.balter.com.com' }
  let(:endpoint) { SiteInspector::Endpoint.new(domain) }
  let(:url) { "https://api.wappalyzer.com/lookup/v2/?urls=#{domain}/" }

  before do
    path = File.expand_path '../../fixtures/wappalyzer.json', __dir__
    body = File.read path
    stub_request(:get, url).to_return(status: 200, body: body)
  end

  it 'returns the API response' do
    expected = {
      'Analytics' => ['Google Analytics'],
      'CDN' => %w[Cloudflare Fastly],
      'Caching' => ['Varnish'],
      'Other' => %w[Disqus Jekyll],
      'PaaS' => ['GitHub Pages'],
      'Web frameworks' => ['Ruby on Rails']
    }
    expect(subject.to_h).to eql(expected)
  end

  it 'fails gracefully' do
    stub_request(:get, url).to_return(status: 400, body: '')
    expect(subject.to_h).to eql({})
  end
end
