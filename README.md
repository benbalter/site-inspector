# Site Inspector

A Ruby Gem to sniff information about a domain's technology and capabilities.

[![Gem Version](https://img.shields.io/gem/v/site-inspector)](https://rubygems.org/gems/site-inspector) [![CI](https://github.com/benbalter/site-inspector/actions/workflows/ci.yml/badge.svg)](https://github.com/benbalter/site-inspector/actions/workflows/ci.yml)

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
domain.canonical_endpoint.wappalyzer.to_h
#  =>  { :cms => ["Drupal"], ... }
```

### Command line usage

```
site-inspector inspect -- inspects a domain

Usage:

  site-inspector inspect <domain> [options]

Options:
        -j, --json         JSON encode the output
        -a, --all          return results for all endpoints (defaults to only the canonical endpoint)
            --accessibility  return results for the accessibility check (defaults to all checks unless one or more checks are specified)
            --content      return results for the content check (defaults to all checks unless one or more checks are specified)
            --cookies      return results for the cookies check (defaults to all checks unless one or more checks are specified)
            --dns          return results for the dns check (defaults to all checks unless one or more checks are specified)
            --headers      return results for the headers check (defaults to all checks unless one or more checks are specified)
            --hsts         return results for the hsts check (defaults to all checks unless one or more checks are specified)
            --https        return results for the https check (defaults to all checks unless one or more checks are specified)
            --wappalyzer   return results for the wappalyzer check (defaults to all checks unless one or more checks are specified)
            --wellknown    return results for the wellknown check (defaults to all checks unless one or more checks are specified)
            --whois        return results for the whois check (defaults to all checks unless one or more checks are specified)
        -h, --help         Show this message
        -v, --version      Print the name and version
        -t, --trace        Show the full backtrace when an error occurs
```

There's one `--<check>` flag per enabled check. `--accessibility` and `--wappalyzer` only appear when the `pa11y` and `wappalyzer` CLIs are installed (see below).

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

* `valid` - whether the endpoint passes the WCAG2A standard
* `results` - the issues `pa11y` reported

To test against another standard, call `section508`, `wcag2a`, `wcag2aa` or `wcag2aaa` on the check, such as `endpoint.accessibility.wcag2aa`.

#### Content

* `doctype` - The HTML doctype returned
* `generator` - the content of the `generator` meta tag, if any
* `proper_404s` - whether the endpoint returns a 404 for pages that don't exist. The path checks below only run when it does.
* `robots_txt` - whether the endpoint has a `robots.txt` file
* `sitemap_xml` - Whether the endpoint has a sitemap
* `humans_txt` - whether the endpoint has a `humans.txt` file
* `vulnerability_disclosure_policy` - whether the endpoint has a `/vulnerability-disclosure-policy` page
* `security_txt` - whether the endpoint has a `security.txt` file, at the root or in `.well-known/`
* `data_json` - whether the endpoint has a `data.json` file

#### Cookies

* `cookie?` - does the endpoint set cookies
* `secure?` - whether at least one cookie sets both the `Secure` and `HttpOnly` flags

#### DNS

* `dnssec` - is DNSSEC supported
* `ipv6` - is IPV6 supported
* `cdn` - the endpoint's CDN, if any
* `cloud_provider` - the endpoint's cloud provider, if any
* `google_apps` - whether the domain is using google apps
* `hostname` - the server hostname
* `ip` - the server IP

#### Headers

The value of each of these headers, or `false` if it isn't sent:

* `strict-transport-security` - the HSTS header
* `content-security-policy` - the endpoint's CSP
* `x-frame-options` - click-jacking protection
* `server` - the server header
* `x-xss-protection` - XSS protection

Any other `x-` headers the endpoint sends are included too.

#### HSTS

* `valid` - whether the HSTS header is valid
* `max_age` - the HSTS max age
* `include_subdomains` - whether subdomains are included
* `preload` - whether its preloaded
* `enabled` - whether HSTS is enabled
* `preload_ready` - whether HSTS could be preloaded
* `preload_list_status` - the domain's status on the [HSTS preload list](https://hstspreload.org/), such as `preloaded`, `pending` or `unknown`

#### HTTPS

* `valid` - if the HTTPS response is valid
* `return_code` - the HTTPS error, if any

#### Wappalyzer

Detects the endpoint's CMS and other technologies (analytics, JavaScript libraries, advertising, web servers, and so on) with the [`wappalyzer`](https://www.npmjs.com/package/wappalyzer) CLI. Requires `node`. The check is only enabled when a `wappalyzer` binary is found on your `PATH`, in `./bin`, or in `./node_modules/.bin` (`npm install` in this repository installs it).

Returns a hash of technology names keyed by category, such as `cms`, `analytics`, or `javascript_libraries`.

#### Well-known

Whether the endpoint serves each [well-known URI](https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml) in the IANA registry, except deprecated ones. Each key is the URI's name with `.` and `-` replaced by `_`, such as `openid_configuration`, `mta_sts_txt` or `host_meta_json`.

#### Whois

* `domain` - the fields of the domain's WHOIS record
* `ip` - the fields of the WHOIS record for the endpoint's IP address

## Adding your own check

[Checks](https://github.com/benbalter/site-inspector/tree/main/lib/site-inspector/endpoint) are special classes that are children of [`SiteInspector::Endpoint::Check`](https://github.com/benbalter/site-inspector/blob/main/lib/site-inspector/endpoint/check.rb). You can implement your own check like this:

```ruby
class SiteInspector
  class Endpoint
    class Mention < Check
      def mentions_ben?
        endpoint.content.body =~ /ben/i
      end
    end
  end
end
```

This check can then be used as follows:
```
domain.canonical_endpoint.mention.mentions_ben?
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
