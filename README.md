# Site Inspector (Ruby Edition)

Information about a domain's technology and capabilities.

A Ruby port and v2 of Site Inspector (http://github.com/benbalter/site-inspector)

## Demo

[gov-inspector.herokuapp.com](https://gov-inspector.herokuapp.com) ([source](https://github.com/benbalter/site-inspector-demo))

## Usage

```ruby
site = SiteInspector.new "whitehouse.gov"
site.https?
#  =>  false
site.non_www?
#  =>  true
site.cms
#  =>  { :drupal  =>  {}}
```

## Methods (what's checked)

```ruby
{
  :domain                    => "cia.gov",
  :uri                       => "https://www.cia.gov",
  :government                => true,
  :live                      => true,
  :ssl                       => true,
  :enforce_https             => true,
  :non_www                   => true,
  :redirect                  => nil,
  :ip                        => "184.85.99.65",
  :hostname                  => "a184-85-99-65.deploy.static.akamaitechnologies.com",
  :ipv6                      => false,
  :dnssec                    => false,
  :cdn                       => "akamai",
  :google_apps               => false,
  :could_provider            => false,
  :server                    => nil,
  :cms                       => {},
  :analytics                 => {},
  :javascript                => { :jquery => {} },
  :advertising               => {},
  :slash_data                => false,
  :slash_developer           => false,
  :data_dot_json             => false,
  :click_jacking_protection  => false,
  :content_security_policy   => false,
  :xss_protection            => false,
  :secure_cookies            => nil,
  :strict_transport_security => false
}
```
