# frozen_string_literal: true

require File.expand_path './lib/site-inspector/version', File.dirname(__FILE__)

Gem::Specification.new do |s|
  s.name                  = 'site-inspector'
  s.version               = SiteInspector::VERSION
  s.summary               = 'A Ruby port and v2 of Site Inspector (https://github.com/benbalter/site-inspector)'
  s.description           = "Returns information about a domain's technology and capabilities"
  s.authors               = 'Ben Balter'
  s.email                 = 'ben@balter.com'
  s.homepage              = 'https://github.com/benbalter/site-inspector'
  s.license               = 'MIT'

  s.files                 = `git ls-files -z`.split("\x0")
  s.executables           = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files            = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths         = ['lib']

  s.add_dependency('cliver', '~> 0.0')
  s.add_dependency('colorator', '~> 1.1')
  s.add_dependency('dnsruby', '~> 1.0')
  s.add_dependency('dotenv', '~> 2.0')
  s.add_dependency('gman', '~> 7.0', '>= 7.0.4')
  s.add_dependency('mercenary', '~> 0.0')
  s.add_dependency('nokogiri', '~> 1.0')
  s.add_dependency('oj', '~> 3.0')
  s.add_dependency('parallel', '~> 1.0')
  s.add_dependency('public_suffix', '~> 4.0')
  s.add_dependency('sniffles', '~> 0.0')
  s.add_dependency('typhoeus', '~> 1.0')
  s.add_dependency('urlscan', '~> 0.6')
  s.add_dependency('whois', '~> 5.0')

  s.add_development_dependency('pry', '~> 0.0')
  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('rubocop', '~> 1.0')
  s.add_development_dependency('rubocop-performance', '~> 1.5')
  s.add_development_dependency('rubocop-rspec', '~> 2.0')
  s.add_development_dependency('webmock', '~> 3.0')
end
