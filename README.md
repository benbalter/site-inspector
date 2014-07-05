# Site Inspector (Ruby Edition)

A Ruby port and v2 of Site Inspector (http://github.com/benbalter/site-inspector)

## Demo

[gov-inspector.herokuapp.com](https://gov-inspector.herokuapp.com)

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

## Server

There's a lightweight demo server included. Just run `script/server` and open `localhost:9292` in your browser.
