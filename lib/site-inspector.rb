
# needed for HTTP analysis
require 'open-uri'
require "addressable/uri"
require 'public_suffix'
require 'typhoeus'

require_relative 'site-inspector/cache'
require_relative 'site-inspector/disk_cache'
require_relative 'site-inspector/headers'
require_relative 'site-inspector/sniffer'
require_relative 'site-inspector/dns'
require_relative 'site-inspector/compliance'
require_relative 'site-inspector/hsts'

class SiteInspector
  class << self

    attr_writer :timeout

    def load_data(name)
      require 'yaml'
      YAML.load_file File.expand_path "./data/#{name}.yml", File.dirname(__FILE__)
    end

    def cache
      @cache ||= if ENV['CACHE']
        SiteInspector::DiskCache.new
      else
        SiteInspector::Cache.new
      end
    end

    def timeout
      @timeout || 10
    end
  end
end

Typhoeus::Config.cache = SiteInspector.cache
