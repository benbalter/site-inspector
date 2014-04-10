require 'nokogiri'
require 'open-uri'
require 'public_suffix'
require 'gman'
require 'net/http'
require "net/dns"
require 'net/dns/resolver'
require 'yaml'
require 'sniffles'
require "addressable/uri"
require 'typhoeus'
require File.expand_path './site-inspector/cache',   File.dirname(__FILE__)
require File.expand_path './site-inspector/sniffer', File.dirname(__FILE__)
require File.expand_path './site-inspector/dns',     File.dirname(__FILE__)

class SiteInspector

  attr_reader :domain

  def initialize(domain)
    domain = domain.sub /^http\:/, ""
    domain = domain.sub /^\/+/, ""
    domain = domain.sub /^www\./, ""
    @uri = Addressable::URI.parse "//#{domain}"
    @domain = PublicSuffix.parse @uri.host
    Typhoeus::Config.cache = SiteInspectorCache.new
  end

  def inspect
    "<SiteInspector domain=\"#{domain}\">"
  end

  def uri(scheme="http",www=false)
    uri = @uri.clone
    uri.host = "www.#{uri.host}" if www
    uri.scheme = scheme
    uri
  end

  def request(scheme="http", www=false)
    response = Typhoeus::Request.get(uri(scheme, false), followlocation: true)
    response if response.success?
  end

  def response
    @response ||= begin
      if response = request("http", false)
        @non_www = true
        response
      elsif response = request("http", true)
        @non_www = false
        response
      else
        false
      end
    end
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
    Gman.valid? domain.to_s
  end

  def https?
    !!request(scheme="https", !non_www?)
  end

  def enforce_https?
    https? && Addressable::URI.parse(request("http", !non_www?).effective_url).scheme == "https"
  end

  def non_www?
    response && @non_www
  end
end
