require 'spec_helper'

describe 'SiteInspector::DiskCache' do
  before do
    @cache = SiteInspector::DiskCache.new(tmpdir)
    FileUtils.rm_rf(tmpdir)
    Dir.mkdir(tmpdir)
  end

  it "should write a value to disk" do
    path = File.expand_path "foo", tmpdir
    expect(File.exists?(path)).to eql(false)

    @cache.set "foo", "bar"
    
    expect(File.exists?(path)).to eql(true)
    expect(File.open(path).read).to eql("I\"bar:ET")
  end

  it "should read a value from disk" do
    path = File.expand_path "foo", tmpdir
    File.write(path, "I\"bar:ET")
    expect(@cache.get("foo")).to eql("bar")
  end

  it "should calculate a file's path" do
    path = File.expand_path "foo", tmpdir
    expect(@cache.send(:path, "foo")).to eql(path)
  end
end
