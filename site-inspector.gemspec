Gem::Specification.new do |s|

  s.name                  = "site-inspector"
  s.version               = "1.0.1"
  s.summary               = "A Ruby port and v2 of Site Inspector (http://github.com/benbalter/site-inspector)"
  s.description           = "Returns information about a domain's technology and capabilities"
  s.authors               = "Ben Balter"
  s.email                 = "ben@balter.com"
  s.homepage              = "https://github.com/benbalter/site-inspector-ruby"
  s.license               = "MIT"
  s.executable            = "site-inspector"
  s.files = [
    "lib/site-inspector.rb",
    "lib/data/cdn.yml",
    "lib/data/cloud.yml",
    "lib/site-inspector/cache.rb",
    "lib/site-inspector/compliance.rb",
    "lib/site-inspector/dns.rb",
    "lib/site-inspector/headers.rb",
    "lib/site-inspector/sniffer.rb",
    "LICENSE"
  ]
  s.add_dependency("nokogiri", "~> 1.6")
  s.add_dependency("public_suffix", "~> 1.4")
  s.add_dependency("gman", "~> 4.1")
  s.add_dependency("dnsruby", "~> 1.56")
  s.add_dependency("sniffles", "~> 0.2")
  s.add_dependency("typhoeus", "~> 0.6")
  s.add_dependency("oj", "~> 2.11")
  s.add_development_dependency("pry", "~> 0.10")
  s.add_development_dependency( "rake", "~> 10.4" )
  s.add_development_dependency( "shoulda", "~> 3.5" )
  s.add_development_dependency( "rdoc", "~> 4.1" )
  s.add_development_dependency( "bundler", "~> 1.6" )
  s.add_development_dependency( "rerun", "~> 0.10" )
  s.add_development_dependency( "vcr", "~> 2.9" )
  s.add_development_dependency( "webmock", "~> 1.2" )
  s.add_development_dependency( "guard-rake", "~> 1.0")
end
