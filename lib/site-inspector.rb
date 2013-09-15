require 'nokogiri'
require 'open-uri'
require 'public_suffix'
require 'gman'
require 'net/http'
require "dnsruby"
require 'yaml'

class SiteInspector

  def initialize(domain)
    self.domain= domain
  end

  def domain=(domain)
    @domain = PublicSuffix.parse domain
  end
  attr_reader :domain

  def uri(protocal=nil)
    protocal ||= "http"
    "#{protocal}://#{@domain.to_s}"
  end

  def doc
    @doc = Nokogiri::HTML open self.uri if @doc.nil?
    @doc
  end

  def body
    self.doc.to_s
  end

  def load_data(name)
    YAML.load_file "#{File.dirname(__FILE__)}/data/#{name}.yml"
  end

  def government?
    Gman.valid? @domain.to_s
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

  def scripts_regex
    self.load_data "scripts"
  end

  def scripts
    scripts = []
    self.doc.css("script").each do |script_tag|
      self.scripts_regex.each do |script,regex|
        if script_tag.attribute("src") =~ /#{regex}/i
          scripts.push script
        elsif script_tag.content =~ /#{regex}/i
          scripts.push script
        end
      end
    end
    scripts
  end

  def generator
    generator = self.doc.css("meta[name='generator']")
    return if generator.empty?
    generator.first.attribute("content").to_s
  end

  def generators_regex
    self.load_data "generators"
  end

  def body_regex
    self.load_data "cms"
  end

  def find_by_generator
    found = nil
    return unless self.generator
    self.generators_regex.each do |generator, regex|
      break found = generator if self.generator =~ /#{regex}/i
    end
    found
  end

  def find_by_body_regex
    found = nil
    self.body_regex.each do |generator, regex|
      break found = generator if self.body =~ /#{regex}/i
    end
    found
  end

  def cms
    found = self.find_by_generator
    return found if found

    found = self.find_by_body_regex
    return found if found
  end

end

# s = SiteInspector.new("ben.balter.com")
