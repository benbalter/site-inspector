require 'spec_helper'

describe 'SiteInspector::Cache' do
  before do
    @cache = SiteInspector::Cache.new
  end

  it "stores a cache value" do
    @cache.set "foo", "bar"
    expect(@cache.instance_variable_get("@memory")["foo"]).to eql("bar")
  end

  it "retrieves values from the cache" do
    @cache.instance_variable_set("@memory", {"foo" => "bar"})
    expect(@cache.get("foo")).to eql("bar")
  end
end
