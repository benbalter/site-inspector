require 'spec_helper'

describe SiteInspector do

  before do
    SiteInspector.instance_variable_set("@cache", nil)
    SiteInspector.instance_variable_set("@timeout", nil)
  end

  it "defaults to ephemeral cache" do
    with_env "CACHE", nil do
      expect(SiteInspector.cache.class).to be(SiteInspector::Cache)
    end
  end

  it "uses disk cache when requested" do
    with_env "CACHE", "/tmp" do
      expect(SiteInspector.cache.class).to be(SiteInspector::DiskCache)
    end
  end

  it "returns the default timeout" do
    expect(SiteInspector.timeout).to eql(10)
  end

  it "honors custom timeouts" do
    SiteInspector.timeout = 20
    expect(SiteInspector.timeout).to eql(20)
  end

  it "returns a domain when inspecting" do
    expect(SiteInspector.inspect("example.com").class).to be(SiteInspector::Domain)
  end

  it "returns the typhoeus defaults" do
    expected = {
      :accept_encoding => "gzip",
      :followlocation => false,
      :timeout => 10,
      :headers => {
        "User-Agent" => "Mozilla/5.0 (compatible; SiteInspector/#{SiteInspector::VERSION}; +https://github.com/benbalter/site-inspector)"
      }
    }
    expect(SiteInspector.typhoeus_defaults).to eql(expected)
  end
end
