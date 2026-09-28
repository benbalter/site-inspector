# frozen_string_literal: true

require 'spec_helper'

describe Cliver::Dependency do
  subject(:dependency) { described_class.new('foo') }

  before do
    allow(dependency).to receive_messages(path: '/usr/bin/foo', installed_versions: [['/usr/bin/foo', '1.2.3']])
  end

  it 'returns the version of the detected executable' do
    expect(dependency.version).to eql('1.2.3')
    expect(dependency.major_version).to eql('1')
  end

  it 'memoizes the version' do
    2.times { dependency.version }
    expect(dependency).to have_received(:installed_versions).once
  end
end
