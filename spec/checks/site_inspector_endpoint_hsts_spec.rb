require 'spec_helper'

describe SiteInspector::Endpoint::Hsts do
  subject do
    headers = { 'strict-transport-security' => 'max-age=31536000; includeSubDomains;' }
    stub_request(:head, 'http://example.com/')
      .to_return(status: 200, headers: headers)
    endpoint = SiteInspector::Endpoint.new('http://example.com')
    SiteInspector::Endpoint::Hsts.new(endpoint)
  end

  def stub_header(value)
    allow(subject).to receive(:header) { value }
  end

  it 'returns the headers' do
    expect(subject.send(:headers).class).to eql(SiteInspector::Endpoint::Headers)
  end

  it 'returns the HSTS header' do
    expect(subject.send(:header)).to eql('max-age=31536000; includeSubDomains;')
  end

  it 'it parses the directives' do
    expect(subject.send(:directives).count).to eql(2)
    expect(subject.send(:directives).first).to eql('max-age=31536000')
    expect(subject.send(:directives).last).to eql('includeSubDomains')
  end

  it 'parses pairs' do
    expect(subject.send(:pairs).keys).to include(:"max-age")
    expect(subject.send(:pairs)[:"max-age"]).to eql('31536000')
  end

  it 'knows if the header is valid' do
    expect(subject.valid?).to eql(true)

    allow(subject).to receive(:pairs) { ['fo o' => 'bar'] }
    expect(subject.valid?).to eql(false)

    allow(subject).to receive(:pairs) { ["fo'o" => 'bar'] }
    expect(subject.valid?).to eql(false)
  end

  it 'knows the max age' do
    expect(subject.max_age).to eql(31_536_000)
  end

  it 'knows if subdomains are included' do
    expect(subject.include_subdomains?).to eql(true)
    allow(subject).to receive(:pairs) { { foo: 'bar' } }
    expect(subject.include_subdomains?).to eql(false)
  end

  it "knows if it's preloaded" do
    expect(subject.preload?).to eql(false)
    allow(subject).to receive(:pairs) { { preload: nil } }
    expect(subject.preload?).to eql(true)
  end

  it "knows if it's enabled" do
    expect(subject.enabled?).to eql(true)

    allow(subject).to receive(:pairs) { { "max-age": 0 } }
    expect(subject.preload?).to eql(false)

    allow(subject).to receive(:pairs) { { foo: 'bar' } }
    expect(subject.preload?).to eql(false)
  end

  it "knows if it's preload ready" do
    expect(subject.preload_ready?).to eql(false)

    pairs = { "max-age": 10_886_401, preload: nil, includesubdomains: nil }
    allow(subject).to receive(:pairs) { pairs }
    expect(subject.preload_ready?).to eql(true)

    pairs = { "max-age": 10_886_401, includesubdomains: nil }
    allow(subject).to receive(:pairs) { pairs }
    expect(subject.preload_ready?).to eql(false)

    pairs = { "max-age": 10_886_401, preload: nil, includesubdomains: nil }
    allow(subject).to receive(:pairs) { pairs }
    expect(subject.preload_ready?).to eql(true)

    pairs = { "max-age": 5, preload: nil, includesubdomains: nil }
    allow(subject).to receive(:pairs) { pairs }
    expect(subject.preload_ready?).to eql(false)
  end
end
