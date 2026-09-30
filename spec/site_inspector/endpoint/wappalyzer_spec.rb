# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Wappalyzer do
  subject(:wappalyzer) { described_class.new(endpoint) }

  let(:domain) { 'http://example.com' }
  let(:endpoint) { SiteInspector::Endpoint.new(domain) }

  it 'raises a WappalyzerError naming the command when output is not JSON' do
    status = instance_double(Process::Status, exitstatus: 1)
    allow(described_class).to receive(:run_command).and_return(['not json', status])

    expect { wappalyzer.send(:data) }.to raise_error(
      SiteInspector::Endpoint::Wappalyzer::WappalyzerError,
      %r{Command `wappalyzer http://example.com/` failed: not json}
    )
  end
end
