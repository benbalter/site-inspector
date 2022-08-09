# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector do
  before do
    described_class.instance_variable_set(:@cache, nil)
    described_class.instance_variable_set(:@timeout, nil)
  end

  it 'defaults to ephemeral cache' do
    with_env 'CACHE', nil do
      expect(described_class.cache.class).to be(SiteInspector::Cache)
    end
  end

  it 'uses disk cache when requested' do
    with_env 'CACHE', '/tmp' do
      expect(described_class.cache.class).to be(SiteInspector::DiskCache)
    end
  end

  it 'returns the default timeout' do
    expect(described_class.timeout).to be(10)
  end

  it 'honors custom timeouts' do
    described_class.timeout = 20
    expect(described_class.timeout).to be(20)
  end

  it 'returns a domain when inspecting' do
    expect(described_class.inspect('example.com').class).to be(SiteInspector::Domain)
  end

  it 'returns the typhoeus defaults' do
    expected = {
      accept_encoding: 'gzip',
      followlocation: false,
      method: :head,
      timeout: 10
    }
    expect(described_class.typhoeus_defaults).to eql(expected)
  end
end
