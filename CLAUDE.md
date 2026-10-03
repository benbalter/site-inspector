# CLAUDE.md

Site Inspector is a Ruby gem and CLI that reports on a domain's technology and capabilities (HTTPS, HSTS, DNS, headers, accessibility and more).

## Commands

- [`script/bootstrap`](script/bootstrap) runs `bundle install` and `npm install`. The npm packages provide the optional `pa11y` and `wappalyzer` CLIs.
- [`script/cibuild`](script/cibuild) runs the specs, RuboCop and a gem build. It's what CI runs, so run it before committing.

## Generated files

[`lib/data/well-known.yml`](lib/data/well-known.yml) is regenerated from the IANA registry by [`script/update-well-known`](script/update-well-known). Rerun the script rather than editing the file by hand.

## Releasing

[`script/release`](script/release) builds the gem, runs `gem push` to RubyGems, then tags `vX.Y.Z` and pushes the default branch and the tag. It asks for no confirmation, so running it publishes immediately.

Releases happen only after the owner explicitly approves them. Agents may open a PR that bumps [`lib/site-inspector/version.rb`](lib/site-inspector/version.rb) and adds a section to [`CHANGELOG.md`](CHANGELOG.md), but must never run `script/release`, `gem push` or `npm publish`, push a tag, or create a GitHub Release. [`package.json`](package.json) exists only to install the CLIs above; this project isn't published to npm.
