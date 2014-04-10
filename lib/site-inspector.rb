require 'nokogiri'
require 'open-uri'
require 'public_suffix'
require 'gman'
require 'net/http'
require "net/dns"
require 'yaml'
require 'sniffles'
require "addressable/uri"
require 'typhoeus'

class SiteInspector

  attr_reader :domain

  def initialize(domain)
    domain = domain.sub /^http\:/, ""
    domain = domain.sub /^\/+/, ""
    @uri = Addressable::URI.parse "//#{domain}"
    @domain = PublicSuffix.parse @uri.host
  end

  def inspect
    "<SiteInspector domain=\"#{domain}\">"
  end

  def uri(scheme="http")
    uri = @uri.clone
    uri.scheme = scheme
    uri
  end

  def response
    @response ||= Typhoeus::Request.get uri, followlocation: true
  end

  def doc
    @doc ||= Nokogiri::HTML response.body if response
  end

  def body
    doc.to_s
  end

  def load_data(name)
    YAML.load_file File.expand_path "./data/#{name}.yml", File.Dirname(__FILE__)
  end

  def government?
    Gman.valid? domain
  end

  def https?
    raise "not yet implemented"
  end

  def dnsec?
    raise "not yet implemented"
  end

  def non_www?
    raise "not yet implemented"
  end

  def sniff(type)
    results = Sniffles.sniff(body, type).select { |name, meta| meta[:found] == true }
    results.each { |name, result| result.delete :found} if results
    results
  end

  def cms
    sniff :cms
  end

  def analytics
    sniff :analytics
  end

  def javascript
    sniff :javascript
  end

  def advertising
    sniff :advertising
  end

end

# s = SiteInspector.new("ben.balter.com")
