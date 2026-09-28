# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector do
  before do
    described_class.instance_variable_set(:@cache, nil)
    described_class.instance_variable_set(:@timeout, nil)
  end

  it 'defaults to an in-memory cache' do
    with_env 'CACHE', nil do
      expect(described_class.cache).to be_a(Typhoeus::Cache::Rails)
      store = described_class.cache.instance_variable_get(:@cache)
      expect(store).to be_a(ActiveSupport::Cache::MemoryStore)
    end
  end

  it 'uses a file cache when requested' do
    with_env 'CACHE', tmpdir do
      expect(described_class.cache).to be_a(Typhoeus::Cache::Rails)
      store = described_class.cache.instance_variable_get(:@cache)
      expect(store).to be_a(ActiveSupport::Cache::FileStore)
      expect(store.cache_path).to eql(tmpdir)
    end
  end

  context 'with the response cache' do
    let(:url) { 'https://example.com/' }
    let(:response) do
      Typhoeus::Response.new(code: 200, body: 'content', headers: { 'Server' => 'nginx' })
    end

    before { FileUtils.rm_rf(tmpdir) }

    after { FileUtils.rm_rf(tmpdir) }

    {
      'memory' => -> { ActiveSupport::Cache::MemoryStore.new },
      'file' => -> { ActiveSupport::Cache::FileStore.new(tmpdir) }
    }.each do |name, store|
      it "round-trips a response through the #{name} store using an equal request" do
        cache = Typhoeus::Cache::Rails.new(store.call)
        request = Typhoeus::Request.new(url, described_class.typhoeus_defaults)
        request.finish(response)
        cache.set(request, response)

        cached = cache.get(Typhoeus::Request.new(url, described_class.typhoeus_defaults))
        expect(cached).to be_a(Typhoeus::Response)
        expect(cached.code).to be(200)
        expect(cached.body).to eql('content')
      end
    end

    it 'misses for a different request' do
      cache = Typhoeus::Cache::Rails.new(ActiveSupport::Cache::MemoryStore.new)
      cache.set(Typhoeus::Request.new(url, described_class.typhoeus_defaults), response)

      expect(cache.get(Typhoeus::Request.new('https://example.org/', described_class.typhoeus_defaults))).to be_nil
    end
  end

  it 'restores the environment when a with_env block raises' do
    ENV['SITE_INSPECTOR_TEST_ENV'] = 'before'
    expect do
      with_env('SITE_INSPECTOR_TEST_ENV', 'during') { raise 'boom' }
    end.to raise_error('boom')
    expect(ENV.fetch('SITE_INSPECTOR_TEST_ENV')).to eql('before')
  ensure
    ENV.delete('SITE_INSPECTOR_TEST_ENV')
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
