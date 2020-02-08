# frozen_string_literal: true

require 'spec_helper'

describe SiteInspector::Endpoint::Content do
  subject do
    body = <<-BODY
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
      <html>
        <body>
          <h1>Some page</h1>
        </body>
      </html>
    BODY

    stub_request(:get, 'http://example.com/')
      .to_return(status: 200, body: body)
    stub_request(:head, 'http://example.com/')
      .to_return(status: 200)
    endpoint = SiteInspector::Endpoint.new('http://example.com')
    described_class.new(endpoint)
  end

  it 'returns the doc' do
    expect(subject.document.class).to eql(Nokogiri::HTML::Document)
    expect(subject.document.css('h1').text).to eql('Some page')
  end

  it 'returns the body' do
    expect(subject.body).to match('<h1>Some page</h1>')
  end

  it 'returns the doctype' do
    expect(subject.doctype).to eql('-//W3C//DTD XHTML 1.0 Transitional//EN')
  end

  it 'knows when robots.txt exists' do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/robots.txt')
      .to_return(status: 200)
    expect(subject.robots_txt?).to be(true)
  end

  it "knows when robots.txt doesn't exist" do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/robots.txt')
      .to_return(status: 404)
    expect(subject.robots_txt?).to be(false)
  end

  it 'knows when sitemap.xml exists' do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/sitemap.xml')
      .to_return(status: 200)
    expect(subject.sitemap_xml?).to be(true)
  end

  it 'knows when sitemap.xml exists' do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/sitemap.xml')
      .to_return(status: 404)
    expect(subject.sitemap_xml?).to be(false)
  end

  it 'knows when humans.txt exists' do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/humans.txt')
      .to_return(status: 200)
    expect(subject.humans_txt?).to be(true)
  end

  it "knows when humans.txt doesn't exist" do
    stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 404)

    stub_request(:head, 'http://example.com/humans.txt')
      .to_return(status: 200)
    expect(subject.humans_txt?).to be(true)
  end

  context '404s' do
    it 'knows when an endpoint returns a proper 404' do
      stub_request(:head, %r{http\://example.com/.*})
        .to_return(status: 404)
      expect(subject.proper_404s?).to be(true)
    end

    it "knows when an endpoint doesn't return a proper 404" do
      stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i)
        .to_return(status: 200)
      expect(subject.proper_404s?).to be(false)
    end

    it 'generates a random path' do
      path = subject.send(:random_path)
      expect(path).to match(/[a-z0-9]{32}/i)
      expect(subject.send(:random_path)).to eql(path)
    end

    it "doesn't say something exists when there are no 404s" do
      stub_request(:head, %r{http\://example.com/[a-z0-9]{32}}i).to_return(status: 200)
      stub_request(:head, 'http://example.com/humans.txt').to_return(status: 200)
      expect(subject.humans_txt?).to be(nil)
    end
  end
end
