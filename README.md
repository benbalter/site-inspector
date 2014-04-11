# Site Inspector (Ruby Eddition)

A Ruby port and v2 of Site Inspector (http://github.com/benbalter/site-inspector)

## Usage

```ruby
site = SiteInspector.new "whitehouse.gov"
site.https?
# => false
site.non_www?
# => true
site.cms
# => { :drupal => {}}
```

## Methods (what's checked)

*comming soon*
