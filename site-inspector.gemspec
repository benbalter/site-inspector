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
  s.add_dependency("net-dns")
  s.add_dependency("sniffles")
  s.add_dependency("typhoeus")
  s.add_development_dependency("pry")
  s.add_development_dependency( "rake" )
  s.add_development_dependency( "shoulda" )
  s.add_development_dependency( "rdoc" )
  s.add_development_dependency( "bundler" )
  s.add_development_dependency( "rerun" )
end
