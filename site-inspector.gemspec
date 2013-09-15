Gem::Specification.new do |s|

  s.name                  = "site-inspector"
  s.version               = "0.0.1"
  s.summary               = ""
  s.description           = ""
  s.authors               = "Ben Balter"
  s.email                 = "ben@balter.com"
  s.homepage              = "https://github.com/benbalter/site-inspector-ruby"
  s.license               = "MIT"

  s.add_dependency("nokogiri")
  s.add_dependency("public_suffix")
  s.add_dependency("gman")
  s.add_dependency("dnsruby")

end
