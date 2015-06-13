require 'spec_helper'

describe SiteInspector::Endpoint::Accessibility do

  before do
    stub_request(:get, "http://example.com/").to_return(:status => 200 )
  end

  subject do
    endpoint = SiteInspector::Endpoint.new("http://example.com")
    SiteInspector::Endpoint::Accessibility.new(endpoint)
  end

  it "retrieve's pa11y's version" do
    expect(subject.pa11y_version).to match(/\d\.\d\.\d/)
  end

  it "responds to valid standards" do
    expect(subject.respond_to?(:section508)).to eql(true)
  end

  it "knows the level" do
    expect(subject.level).to eql("error")
  end

  it "allows the user to set the level" do
    subject.level = "warning"
    expect(subject.level).to eql("warning")
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
    it "knows if pa11y is installed" do
      expect(subject.pa11y?).to eql(true)
    end

    it "knows if a site is valid" do
      expect(subject.valid?).to eql(true)
    end

    it "runs the check" do
      expected = {
        valid: true,
        results: []
      }
      expect(subject.check).to eql(expected)
    end

    it "runs a named check" do
      expected = {
        valid: true,
        results: []
      }
      expect(subject.section508).to eql(expected)
    end
  end

  context "without pa11y installed" do
    before do
      allow(subject).to receive(:pa11y_version) { nil }
    end

    it "knows when pa11y insn't installed" do
      expect(subject.pa11y?).to eql(false)
    end

    it "fails loudly withouy pa11y" do
      expect{subject.check}.to raise_error("pa11y not found. To install: [sudo] npm install -g pa11y")
    end
  end
end
