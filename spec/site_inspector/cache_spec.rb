# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Cache do
  it 'stores a cache value' do
    subject.set 'foo', 'bar'
    expect(subject.instance_variable_get(:@memory)['foo']).to eql('bar')
  end

  it 'retrieves values from the cache' do
    subject.instance_variable_set(:@memory, 'foo' => 'bar')
    expect(subject.get('foo')).to eql('bar')
  end
end
