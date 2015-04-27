require 'spec_helper'

describe SiteInspector::Endpoint::Sniffer do

  subject do
    url = Addressable::URI.parse("https://example.com")
    response = Typhoeus::Response.new(:return_code => :ok)
    response.request = Typhoeus::Request.new(url)
    SiteInspector::Endpoint::Sniffer.new(response)
  end

end
