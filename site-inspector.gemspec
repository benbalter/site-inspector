require File.expand_path "./lib/site-inspector/version", File.dirname(__FILE__)

Gem::Specification.new do |s|

  s.name                  = "site-inspector"
  s.version               = SiteInspector::VERSION
  s.summary               = "A Ruby port and v2 of Site Inspector (https://github.com/benbalter/site-inspector)"
  s.description           = "Returns information about a domain's technology and capabilities"
  s.authors               = "Ben Balter"
  s.email                 = "ben@balter.com"
  s.homepage              = "https://github.com/benbalter/site-inspector"
  s.license               = "MIT"

  s.files                 = `git ls-files -z`.split("\x0")
  s.executables           = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files            = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths         = ["lib"]

  s.add_dependency("nokogiri", "~> 1.6")
  s.add_dependency("public_suffix", "~> 1.4")
  s.add_dependency("gman", "~> 4.1")
  s.add_dependency("dnsruby", "~> 1.56")
  s.add_dependency("sniffles", "~> 0.2")
  s.add_dependency("typhoeus", "~> 0.7")
  s.add_dependency("oj", "~> 2.11")
  s.add_dependency("mercenary", "~> 0.3")
  s.add_dependency("colorator", "~> 0.1")
  s.add_dependency("cliver", "~> 0.3")
  s.add_development_dependency("pry", "~> 0.10")
  s.add_development_dependency( "rake", "~> 10.4" )
  s.add_development_dependency( "rspec", "~> 3.2")
  s.add_development_dependency( "bundler", "~> 1.6" )
  s.add_development_dependency( "webmock", "~> 1.2" )
end
