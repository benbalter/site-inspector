# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Wappalyzer do
  subject { described_class.new(endpoint) }

  let(:domain) { 'http://example.com' }
  let(:endpoint) { SiteInspector::Endpoint.new(domain) }
end
