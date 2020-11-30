# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::WellKnown do
  subject do
    stub_request(:head, 'http://example.com/')
      .to_return(status: 200, headers: { foo: 'bar' })
    endpoint = SiteInspector::Endpoint.new('http://example.com')
    described_class.new(endpoint)
  end
end
