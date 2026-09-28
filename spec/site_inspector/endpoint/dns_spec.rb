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

  context 'with a stubbed resolver' do
    let(:resolver) { described_class.resolver }
    let(:answers) do
      {
        %w[github.com A] => [Dnsruby::RR.create(type: 'A', name: 'github.com', address: '140.82.112.3')],
        %w[github.com MX] => [Dnsruby::RR.create(type: 'MX', name: 'github.com', exchange: 'aspmx.l.google.com', preference: 1)],
        %w[3.112.82.140.in-addr.arpa PTR] => [
          Dnsruby::RR.create(type: 'PTR', name: '3.112.82.140.in-addr.arpa', domainname: 'lb-140-82-112-3-iad.github.com')
        ]
      }
    end

    before do
      allow(resolver).to receive(:query) do |name, type|
        name = Dnsruby::Message.new(name, type).question.first.qname.to_s
        instance_double(Dnsruby::Message, answer: answers.fetch([name, type.to_s], []))
      end
    end

    it 'queries explicit record types instead of ANY' do
      subject.records
      described_class::RECORD_TYPES.each do |type|
        expect(resolver).to have_received(:query).with('github.com', type)
      end
      expect(resolver).not_to have_received(:query).with(anything, 'ANY')
    end

    it 'collects records across types' do
      expect(subject.records.map { |r| r.type.to_s }).to contain_exactly('A', 'MX')
      expect(subject.google_apps?).to be(true)
    end

    it 'resolves the IP from the A record' do
      expect(subject.ip).to eql('140.82.112.3')
    end

    it 'falls back to the AAAA record' do
      answers.delete(%w[github.com A])
      answers[%w[github.com AAAA]] = [Dnsruby::RR.create(type: 'AAAA', name: 'github.com', address: '2001:db8::1')]
      expect(subject.ip).to eql('2001:DB8::1')
    end

    it 'resolves the hostname with a PTR query through the same resolver' do
      expect(subject.hostname.to_s).to eql('lb-140-82-112-3-iad.github.com')
      expect(resolver).to have_received(:query).with('140.82.112.3', 'PTR')
    end

    it 'returns no hostname without an IP' do
      answers.delete(%w[github.com A])
      expect(subject.hostname).to be_nil
    end

    it 'returns no records when the resolver errors' do
      allow(resolver).to receive(:query).and_raise(Dnsruby::Refused, 'refused')
      expect(subject.records).to eql([])
    end
  end

  # NOTE: these tests make external calls; run them with LIVE=1
  context 'live tests', :live do
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

    it 'treats the whole 127.0.0.0/8 block as loopback' do
      allow(subject).to receive(:ip).and_return('127.0.1.1')
      expect(subject.localhost?).to be(true)
    end

    it 'treats the IPv6 loopback as localhost' do
      allow(subject).to receive(:ip).and_return('::1')
      expect(subject.localhost?).to be(true)
    end

    it "knows a public address isn't localhost" do
      allow(subject).to receive(:ip).and_return('140.82.112.3')
      expect(subject.localhost?).to be(false)
    end

    it "knows a missing address isn't localhost" do
      allow(subject).to receive(:ip).and_return(nil)
      expect(subject.localhost?).to be(false)
    end

    it 'returns a LocalhostError' do
      expect(subject.to_h).to eql(error: SiteInspector::Endpoint::Dns::LocalhostError)
    end
  end
end
