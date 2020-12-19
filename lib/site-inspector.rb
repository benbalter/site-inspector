# frozen_string_literal: true

require 'open-uri'
require 'addressable/uri'
require 'public_suffix'
require 'typhoeus'
require 'parallel'
require 'cliver'
require 'whois'
require 'cgi'
require 'resolv'
require 'dotenv/load'
require 'naughty_or_nice'
require_relative 'cliver/dependency_ext'

class SiteInspector
  autoload :Cache, 'site-inspector/cache'
  autoload :DiskCache, 'site-inspector/disk_cache'
  autoload :Formatter, 'site-inspector/formatter'
  autoload :RailsCache, 'site-inspector/rails_cache'
  autoload :Domain, 'site-inspector/domain'
  autoload :DomainParser, 'site-inspector/domain_parser'
  autoload :Endpoint, 'site-inspector/endpoint'
  autoload :VERSION, 'site-inspector/version'

  class << self
    attr_writer :timeout, :cache, :typhoeus_options

    def cache
      @cache ||= if ENV['CACHE']
                   SiteInspector::DiskCache.new
                 elsif Object.const_defined?('Rails')
                   SiteInspector::RailsCache.new
                 else
                   SiteInspector::Cache.new
                 end
    end

    def timeout
      @timeout || 10
    end

    def inspect(domain)
      Domain.new(domain)
    end

    def typhoeus_defaults
      defaults = {
        followlocation: false,
        timeout: SiteInspector.timeout,
        accept_encoding: 'gzip',
        method: :head,
        headers: {
          'User-Agent' => "Mozilla/5.0 (compatible; SiteInspector/#{SiteInspector::VERSION}; +https://github.com/benbalter/site-inspector)"
        }
      }
      defaults.merge! @typhoeus_options if @typhoeus_options
      defaults
    end

    # Returns a thread-safe, memoized hydra instance
    def hydra
      Typhoeus::Hydra.hydra
    end
  end
end

if ENV['DEBUG']
  Ethon.logger = Logger.new($stdout)
  Ethon.logger.level = Logger::DEBUG
  Typhoeus::Config.verbose = true
end

Typhoeus::Config.cache = SiteInspector.cache
