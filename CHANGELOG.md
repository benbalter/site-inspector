# Changelog

## 4.0.0

First release since 3.2.0 (November 2020). It's a major version because several public APIs and output formats changed.

### Breaking changes

- **Ruby 3.2 or later is required.** The gemspec now declares `required_ruby_version >= 3.2`. 3.2.0 had no constraint. CI runs on Ruby 3.2, 3.3, and 3.4.
- **The built-in cache classes are gone.** `SiteInspector::Cache`, `SiteInspector::DiskCache`, and `SiteInspector::RailsCache` were removed. `SiteInspector.cache` now returns a `Typhoeus::Cache::Rails` backed by an ActiveSupport cache store. Setting `CACHE=<dir>` still persists responses to disk (it now uses `ActiveSupport::Cache::FileStore`). Inside Rails, `Rails.cache` is used. Otherwise responses go to an in-memory `ActiveSupport::Cache::MemoryStore`. To supply your own store, use `SiteInspector.cache = Typhoeus::Cache::Rails.new(your_active_support_store)`. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- **Check files moved** from `lib/site-inspector/checks/` to `lib/site-inspector/endpoint/`. The class names did not change (for example, `SiteInspector::Endpoint::Hsts` is still `SiteInspector::Endpoint::Hsts`). Code that required the files directly needs its path updated, for example `require 'site-inspector/checks/hsts'` becomes `require 'site-inspector/endpoint/hsts'`. `require 'site-inspector'` works as before. Core classes are now autoloaded.
- **`Endpoint#host` and `Domain#host` return `PublicSuffix::Domain` objects** instead of Strings. Call `#to_s` if you need a string. `Endpoint#host` also no longer strips a leading `www.`, so `Endpoint.new('https://www.example.com').host.to_s` is now `"www.example.com"`. `Domain#host` still strips it.
- **The library no longer loads dotenv.** `dotenv` was removed as a dependency. The `site-inspector` CLI still loads a `.env` file when the `dotenv` gem happens to be installed. Library users who relied on `.env` loading should `require 'dotenv/load'` themselves. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- **`oj` was dropped** in favor of the standard library's `JSON`. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- **Cookies are parsed with `http-cookie`.** `Cookies#all` and `Cookies#[]` now return `HTTP::Cookie` objects (use `#name`, `#value`, `#secure?`, `#httponly?`) instead of `CGI::Cookie` hashes. `Cookies#secure?` is now true only when a single cookie sets both `Secure` and `HttpOnly`. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- **Headers check API and output changed.** `Headers#to_h` is now keyed by raw header name (`'strict-transport-security'`, `'content-security-policy'`, `'x-frame-options'`, `'server'`, `'x-xss-protection'`) and also includes any other `x-` headers the site sends. It used to be keyed by `:strict_transport_security`, `:click_jacking_protection`, and so on. `click_jacking_protection` / `click_jacking_protection?` were replaced by `frame_options` / `frame_options?`.
- **The Wappalyzer check uses the local `wappalyzer` CLI** (the npm package) instead of the hosted Wappalyzer API. `WAPPALYZER_API_KEY` is no longer used, and the check is disabled unless a `wappalyzer` binary is found on the `PATH`, in `./bin`, or in `./node_modules/.bin`. Category keys in its output are now snake_case symbols (for example `:web_servers`).
- **DNS queries no longer use `ANY`.** `Dns#records` queries A, AAAA, CNAME, MX, and DNSKEY explicitly through the Dnsruby resolver, and `Dns#query` now defaults to `'A'` instead of `'ANY'`. `Dns#ip` and `Dns#hostname` (PTR) are resolved through the same resolver instead of `Resolv`. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- **The User-Agent is set with `Typhoeus::Config.user_agent`.** `SiteInspector.typhoeus_defaults` no longer includes a `:headers` key.
- **pa11y is looked up as `pa11y`** on the `PATH`, in `./bin`, or in `./node_modules/.bin`, instead of `pa11y.js` under the gem's own `node_modules`.
- **Several checks return `{}` for endpoints that are down or redirect.** This applies to content, cookies, sniffer, wappalyzer, accessibility, and well-known. The headers check returns `{}` for redirects.
- **`Domain#downgrades_https?` flags any HTTPS endpoint that redirects to HTTP**, including redirects to another host. Before, it only checked the canonical endpoint. ([#106](https://github.com/benbalter/site-inspector/pull/106))

### Added

- `SiteInspector::Endpoint::WellKnown` check reports which `/.well-known/` URIs (listed in `lib/data/well-known.yml`) exist on an endpoint.
- The content check also looks for `security.txt` (at the root or under `/.well-known/`), a `vulnerability-disclosure-policy` page, and `data.json`.
- The HSTS check reports `preload_list_status` from the hstspreload.org API. This adds an outbound request.
- `SiteInspector::Formatter` renders inspection hashes as HTML tables.
- `SiteInspector::DomainParser` parses domains with `naughty_or_nice`.
- `Domain#to_h` includes `tld`, `sld`, and `trd`. `Endpoint#to_h` includes `resolves_to`.
- `Endpoint.build(domain, https:, www:)`, `Endpoint#build_request`, and `Endpoint#join`. Endpoints compare equal when their URIs match.
- The headers check exposes custom `x-` headers.
- `SiteInspector.logger`. `VERBOSE=1` logs each request and whether it hit the cache.

### Changed

- `Domain#to_h`'s `host` is now the canonical endpoint's host.
- Domain and endpoint hosts are parsed with PublicSuffix / `naughty_or_nice`, and `www` is stripped with `PublicSuffix::Domain.new` instead of regexes.
- `proper_404s?` requires three random paths (bare, `.html`, and `.json`) to return exactly 404. Content paths are only reported when the site returns proper 404s.
- The content check follows redirects when it fetches the page body.
- HSTS handles responses with multiple `Strict-Transport-Security` headers.
- Checks within an endpoint run sequentially instead of in four threads, and `Endpoint#to_h` is memoized.
- The WHOIS and Wappalyzer checks handle timeouts instead of raising.
- The CLI emits JSON with `JSON.pretty_generate`.
- The gemspec has a new summary and metadata (`homepage_uri`, `source_code_uri`, `bug_tracker_uri`, `changelog_uri`, `rubygems_mfa_required`). ([#113](https://github.com/benbalter/site-inspector/pull/113))

### Fixed

- `Endpoint#up?` had an operator precedence bug and crashed when there was no response. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- Redirect `Location` headers are resolved per RFC 3986 with `Addressable::URI#join`, so protocol-relative, query-only, and dot-segment locations work. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- `Dns#localhost?` uses `IPAddr#loopback?`, so it detects every loopback address (all of `127.0.0.0/8` and `::1`), not just `127.0.0.1`. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- `Content#security_txt?` checks the correct `.well-known/security.txt` path. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- The Wappalyzer check no longer raises `NameError` when the CLI output isn't JSON. It raises `SiteInspector::Endpoint::Wappalyzer::WappalyzerError` with the command output instead. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- `Cliver::Dependency#version` is memoized as intended. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- A `RailsCache` autoload that pointed to a missing file was removed. ([#109](https://github.com/benbalter/site-inspector/pull/109))

### Dependencies

- Added: `activesupport`, `csv` (~> 3.0), `http-cookie` (~> 1.0), `naughty_or_nice` (~> 2.0).
- Removed: `dotenv`, `oj`.
- `gman`: `~> 7.0, >= 7.0.4` became `>= 7.0.4, < 9`, which allows gman 8. ([#109](https://github.com/benbalter/site-inspector/pull/109))
- `nokogiri`: `~> 1.0` became `~> 1.10`.
- `public_suffix`: `~> 4.0` became `>= 4, < 6`. ([#92](https://github.com/benbalter/site-inspector/pull/92))
- `sniffles`: `~> 0.0` became `~> 0.2`.
- Development: `rubocop-rspec` `~> 2.0` became `~> 3.0`.
- npm: added `wappalyzer` (now `^6.10.66`) alongside `pa11y`. ([#91](https://github.com/benbalter/site-inspector/pull/91), [#112](https://github.com/benbalter/site-inspector/pull/112))

### Contributors

[@benbalter](https://github.com/benbalter) wrote most of this release. The Copilot coding agent opened [#106](https://github.com/benbalter/site-inspector/pull/106), and Dependabot sent the dependency bumps. No outside human contributors this time.
