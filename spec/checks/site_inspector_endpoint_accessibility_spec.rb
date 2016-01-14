require 'spec_helper'

describe SiteInspector::Endpoint::Accessibility do

  subject do
    endpoint = SiteInspector::Endpoint.new("http://example.com")
    SiteInspector::Endpoint::Accessibility.new(endpoint)
  end

  it "retrieve's pa11y's version" do
    pending("Pa11y not installed") unless SiteInspector::Endpoint::Accessibility.pa11y?
    expect(subject.class.pa11y_version).to match(/\d\.\d\.\d/)
  end

  it "responds to valid standards" do
    expect(subject.respond_to?(:section508)).to eql(true)
  end

  it "knows the level" do
    expect(subject.level).to eql(:error)
  end

  it "allows the user to set the level" do
    subject.level = :warning
    expect(subject.level).to eql(:warning)
  end

  it "errors on invalid levels" do
    expect{subject.level="foo"}.to raise_error(ArgumentError)
  end

  it "knows the standard" do
    expect(subject.standard).to eql(:section508)
  end

  it "allows the user to set the standard" do
    subject.standard = :wcag2a
    expect(subject.standard).to eql(:wcag2a)
  end

  it "errors on invalid standards" do
    expect{subject.standard=:foo}.to raise_error(ArgumentError)
  end

  context "with pa11y installed" do

    before do
      stub_request(:head, "http://example.com/").to_return(:status => 200 )
    end

  end

  context "with pa11y stub'd" do

    before do
      output = '[{"code":"Section508.L.NoContentAnchor","context":"<a href=\"foo\"></a>","message":"Anchor element found with a valid href attribute, but no link content has been supplied.","selector":"html > body > a","type":"error","typeCode":1}]'
      allow(subject).to receive(:run_command) { [output, 2] }
    end

    it "knows if a site is valid" do
      with_env "SKIP_PA11Y_CHECK", "true" do
        expect(subject.valid?).to eql(false)
      end
    end

    it "counts the errors" do
      with_env "SKIP_PA11Y_CHECK", "true" do
        expect(subject.errors).to eql(1)
      end
    end

    it "runs the check" do
      with_env "SKIP_PA11Y_CHECK", "true" do
        expect(subject.check[:valid]).to eql(false)
        expect(subject.check[:results].first["code"]).to eql("Section508.L.NoContentAnchor")
      end
    end

    it "runs a named check" do
      with_env "SKIP_PA11Y_CHECK", "true" do
        expect(subject.check[:valid]).to eql(false)
        expect(subject.check[:results].first["code"]).to eql("Section508.L.NoContentAnchor")
      end
    end
  end
end
