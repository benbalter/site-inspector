# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::DiskCache do
  subject { described_class.new(tmpdir) }

  before do
    FileUtils.rm_rf(tmpdir)
    Dir.mkdir(tmpdir)
  end

  it 'writes a value to disk' do
    foo = Typhoeus::Request.new('foo')

    path = File.expand_path foo.cache_key, tmpdir
    expect(File.exist?(path)).to be(false)

    subject.set foo, 'bar'

    expect(File.exist?(path)).to be(true)
    expect(File.open(path).read).to eql("I\"bar:ET")
  end

  it 'reads a value from disk' do
    foo = Typhoeus::Request.new('foo')

    path = File.expand_path foo.cache_key, tmpdir
    File.write(path, "I\"bar:ET")
    expect(subject.get(foo)).to eql('bar')
  end

  it "calculates a file's path" do
    foo = Typhoeus::Request.new('foo')

    path = File.expand_path foo.cache_key, tmpdir
    expect(subject.send(:path, foo)).to eql(path)
  end
end
