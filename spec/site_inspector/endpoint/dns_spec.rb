# frozen_string_literal: true

require 'spec_helper'
require 'dnsruby'

describe SiteInspector::Endpoint::Dns do
  subject do
    stub_request(:head, 'http://github.com/').to_return(status: 200)
    endpoint = SiteInspector::Endpoint.new('http://github.com')
    described_class.new(endpoint)
  end

  it 'inits the resolver' do
    expect(described_class.resolver.class).to eql(Dnsruby::Resolver)
  end

  # NOTE: these tests makes external calls
  context 'live tests' do
    it 'runs the query' do
      expect(subject.query).not_to be_empty
    end

    context 'resolv' do
      it 'returns the IP' do
        expect(subject.ip).to include('140.82.')
      end

      it 'returns the hostname' do
        expect(subject.hostname.sld).to eql('github')
      end
    end
  end

  context 'stubbed tests' do
    before do
      record = Dnsruby::RR.create type: 'A', address: '1.2.3.4', name: 'test'
      allow(subject).to receive(:records) { [record] }
      allow(subject).to receive(:query).and_return([])
    end

    it 'returns the records' do
      expect(subject.records.count).to be(1)
      expect(subject.records.first.class).to eql(Dnsruby::RR::IN::A)
    end

    it 'knows if a record exists' do
      expect(subject.has_record?('A')).to be(true)
      expect(subject.has_record?('CNAME')).to be(false)
    end

    it 'knows if a domain supports dnssec' do
      expect(subject.dnssec?).to be(false)

      # via https://github.com/alexdalitz/dnsruby/blob/master/test/tc_dnskey.rb
      input = 'example.com. 86400 IN DNSKEY 256 3 5 ( AQPSKmynfzW4kyBv015MUG2DeIQ3' \
              'Cbl+BBZH4b/0PY1kxkmvHjcZc8no' \
              'kfzj31GajIQKY+5CptLr3buXA10h' \
              'WqTkF7H6RfoRqXQeogmMHfpftf6z' \
              'Mv1LyBUgia7za6ZEzOJBOztyvhjL' \
              '742iU/TpPSEDhm2SNKLijfUppn1U' \
              'aNvv4w==  )'

      record = Dnsruby::RR.create input
      allow(subject).to receive(:records) { [record] }

      expect(subject.dnssec?).to be(true)
    end

    it 'knows if a domain supports ipv6' do
      expect(subject.ipv6?).to be(false)

      input = {
        type: 'AAAA',
        name: 'test',
        address: '102:304:506:708:90a:b0c:d0e:ff10'
      }
      record = Dnsruby::RR.create input
      allow(subject).to receive(:records) { [record] }

      expect(subject.ipv6?).to be(true)
    end

    it "knows it's not a localhost address" do
      expect(subject.localhost?).to be(false)
    end

    context 'hostname detection' do
      it 'lists cnames' do
        records = []

        records.push Dnsruby::RR.create(
          type: 'CNAME',
          domainname: 'example.com',
          name: 'example'
        )

        records.push Dnsruby::RR.create(
          type: 'CNAME',
          domainname: 'github.com',
          name: 'github'
        )

        allow(subject).to receive(:records) { records }

        expect(subject.cnames.count).to be(2)
        expect(subject.cnames.first.sld).to eql('example')
      end

      it "knows when a domain doesn't have a cdn" do
        expect(subject.cdn?).to be(false)
      end

      it 'detects CDNs' do
        records = [Dnsruby::RR.create(
          type: 'CNAME',
          domainname: 'foo.cloudfront.net',
          name: 'example'
        )]
        allow(subject).to receive(:records) { records }

        expect(subject.send(:detect_by_hostname, 'cdn')).to be(:cloudfront)
        expect(subject.cdn).to be(:cloudfront)
        expect(subject.cdn?).to be(true)
      end

      it 'builds that path to a data file' do
        path = subject.send(:data_path, 'foo')
        expected = File.expand_path '../../../lib/data/foo.yml', File.dirname(__FILE__)
        expect(path).to eql(expected)
      end

      it 'loads data files' do
        data = subject.send(:load_data, 'cdn')
        expect(data.keys).to include('cloudfront')
      end

      it "knows when a domain isn't cloud" do
        expect(subject.cloud?).to be(false)
      end

      it 'detects cloud providers' do
        records = [Dnsruby::RR.create(
          type: 'CNAME',
          domainname: 'foo.herokuapp.com',
          name: 'example'
        )]
        allow(subject).to receive(:records) { records }

        expect(subject.send(:detect_by_hostname, 'cloud')).to be(:heroku)
        expect(subject.cloud_provider).to be(:heroku)
        expect(subject.cloud?).to be(true)
      end

      it "knows when a domain doesn't have google apps" do
        expect(subject.google_apps?).to be(false)
      end

      it 'knows when a domain is using google apps' do
        records = [Dnsruby::RR.create(
          type: 'MX',
          exchange: 'mx1.google.com',
          name: 'example',
          preference: 10
        )]
        allow(subject).to receive(:records) { records }
        expect(subject.google_apps?).to be(true)
      end
    end
  end

  context 'localhost' do
    before do
      allow(subject).to receive(:ip).and_return('127.0.0.1')
    end

    it "knows it's a localhost address" do
      expect(subject.localhost?).to be(true)
    end

    it 'returns a LocalhostError' do
      expect(subject.to_h).to eql(error: SiteInspector::Endpoint::Dns::LocalhostError)
    end
  end
end
