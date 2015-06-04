require 'spec_helper'

describe SiteInspector::Endpoint::Accessibility do

  subject do
    stub_request(:get, "https://example.com/").
      to_return(:status => 200 )
    endpoint = SiteInspector::Endpoint.new("https://example.com")
    
    # allow(endpoint.response).to receive(:return_code) { :ok }
    
    SiteInspector::Endpoint::Accessibility.new(endpoint)
  end

  # it "knows the scheme" do
  #   expect(subject.send(:scheme)).to eql("https")
  # end

end
