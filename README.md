# Site Inspector

A Ruby Gem to sniff information about a domain's technology and capabilities.

[![Gem Version](https://badge.fury.io/rb/site-inspector.svg)](http://badge.fury.io/rb/site-inspector) [![Build Status](https://travis-ci.org/benbalter/site-inspector-ruby.svg)](https://travis-ci.org/benbalter/site-inspector-ruby)

## Demo

[site-inspector.herokuapp.com](https://site-inspector.herokuapp.com) ([source](https://github.com/benbalter/site-inspector-demo))

## Concepts

Site Inspector involves three primary concepts:

* **Domain** - A domain has a host defined by it's TLD + SLD. A domain might be `example.com`. Domain's have certain domain-wide properties like whether it supports non-www requests, or if it enforces HTTPS.

* **Endpoint** - Each domain has four endpoints based on whether you make your request with HTTPS or not, and whether you prefix the host with `www.` or not. So the domain `example.com` may have endpoints at `https://example.com`, `https://www.example.com`, `http://example.com`, and `https://www.example.com`. There may theoretically be a different server responding to each endpoint, so endpoints have certain endpoint-specific properties, like whether it responds or not, or whether it redirects. Each domain has one canonical (primary) endpoint.

* **Checks** - A check is a set of tests performed on an endpoint. A check might look at what headers are returned, what CMS is used, or whether there is a valid HTTPS certificate. There are some built in checks, listed below, or you can define your own. While they're endpoint specific, checks often filter up and inform some of the domain-wide logic (such as if the domain supports HTTPS).

## Usage

### Ruby

```ruby
domain = SiteInspector.inspect "whitehouse.gov"
domain.https?
#  =>  true
domain.www?
#  =>  true
domain.canonical_endpoint.to_s
#  => "https://www.whitehouse.gov"
domain.canonical_endpoint.sniffer.cms
#  =>  { :drupal  =>  {}}
```

### Command line usage

```
site-inspector inspect -- inspects a domain

Usage:

  site-inspector inspect <domain> [options]

Options:
        -j, --json         JSON encode the output
        -a, --all          return results for all endpoints (defaults to only the canonical endpoint)
            --sniffer      return results for the sniffer check (defaults to all checks unless one or more checks are specified)
            --https        return results for the https check (defaults to all checks unless one or more checks are specified)
            --hsts         return results for the hsts check (defaults to all checks unless one or more checks are specified)
            --headers      return results for the headers check (defaults to all checks unless one or more checks are specified)
            --dns          return results for the dns check (defaults to all checks unless one or more checks are specified)
            --content      return results for the content check (defaults to all checks unless one or more checks are specified)
        -h, --help         Show this message
        -v, --version      Print the name and version
        -t, --trace        Show the full backtrace when an error occurs
```

## What's checked

### Domain

* `canonical_endpoint` - The domain's primary endpoint
* `government` - whether the domain is a government domain
* `up` - whether any endpoint responds
* `www` - whether either `www` endpoint responds
* `root` - whether you can access the domain with `www.`
* `https` - whether HTTPS is supported
* `enforces_https` - whether non-htttps endpoints are either down or redirects to https
* `downgrades_https` - whether the canonical endpoint redirects to an http endpoint
* `canonically_www` - whether non-www requests are redirected to www (or all non-www endpoints are down)
* `canonically_https` - whether non-https request are redirected to https (or all http endpoints are down)
* `redirect` - whether the domain redirects to an external domain
* `hsts` - does the canonical endpoint have HSTS enabled
* `hsts_subdomains` - are subdomains included in the HSTS list?
* `hsts_preload_ready` - can this domain be added to the HSTS preload list?

### Endpoint

* `up` - whether the endpoint responds or not
* `timed_out` - whether the endpoint times out
* `redirect` - whether the endpoint redirects
* `external_redirect` - whether the endpoint redirects to another domain

### Checks

Each endpoint also returns the following checks:

#### Accessibility

Uses the `pa11y` CLI to run automated accessibility tests. Requires `node`. To install `pally`: `[sudo] npm install -g pa11y`.

* `section508` - Tests against the Section508 standard
* `wcag2a` - Tests against the WCAG2A standard
* `wcag2aa` - Tests against the WCAG2AA standard
* `wcag2aaa` - Tests against the WCAG2AAA standard

#### Content

* `doctype` - The HTML doctype returned
* `sitemap_xml` - Whether the endpoint has a sitemap
* `robots_txt` - whether the endpoint has a `robots.txt` file

#### DNS

* `dnssec` - is DNSSEC supported
* `ipv6` - is IPV6 supported
* `cdn` - the endpoint's CDN, if any
* `cloud_provider` - the endpoint's cloud provider, if any
* `google_apps` - whether the domain is using google apps
* `hostname` - the server hostname
* `ip` - the server IP

#### Headers

* `cookies` - does the domain use cookies
* `strict_transport_security` - whether STS is enabled
* `content_security_policy` - the endpoint's CSP
* `click_jacking_protection` - whether an `x-frame-options` header is sent
* `xss_protection` - whether an `x-xss-protection` header is sent
* `server` - the server header
* `secure_cookies` - whether the cookies are secure, or not

#### HSTS

* `valid` - whether the HSTS header is valid
* `max_age` - the HSTS max age
* `include_subdomains` - whether subdomains are included
* `preload` - whether its preloaded
* `enabled` - whether HSTS is enabled
* `preload_ready` - whether HSTS could be preloaded

#### HTTPS

* `valid` - if the HTTPS response is valid
* `return_code` - the HTTPS error, if any

#### Sniffer

* `cms` - the CMS used, if any
* `analytics` - the analytics providers used, if any
* `javascript` - the javascript libraries used, if any
* `advertising` - the advertising providers used, if any

## Adding your own check

[Checks](https://github.com/benbalter/site-inspector-ruby/tree/master/lib/site-inspector/checks) are special classes that are children of [`SiteInspector::Endpoint::Check`](https://github.com/benbalter/site-inspector-ruby/blob/master/lib/site-inspector/checks/check.rb). You can implement your own check like this:

```ruby
class SiteInspector
  class Endpoint
    class Mention
      def mentions_ben?
        endpoint.content.body =~ /ben/i
      end
    end
  end
end
```

Checks can call the `endpoint` object, which, contains the request, response, and other checks. Custom checks are automatically exposed as endpoint methods.

## Contributing

### Bootstrapping locally

1. Clone down the repo
2. `script/bootstrap`

### Running tests

`script/cibuild`

### Development console

`script/console`

### How to contribute

1. Fork the project
2. Create a new, descriptively named feature branch
3. Make your changes
4. Submit a pull request
