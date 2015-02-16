require File.join(File.dirname(__FILE__), 'helper')

class TestSiteInspectorBin < Minitest::Test
  should "show usage information" do
    assert `bundle exec site-inspector` =~ /usage/i
  end

  should "output the hash" do
    assert `bundle exec site-inspector whitehouse.gov` =~ /"government":true/i
  end
end
