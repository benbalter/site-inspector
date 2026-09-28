# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'
require 'fileutils'
require 'site-inspector'

WebMock.disable_net_connect!

# Specs tagged :live hit real DNS and WHOIS servers, whose answers change over
# time. Skip them unless LIVE=1 is set.
RSpec.configure do |config|
  config.filter_run_excluding :live unless ENV['LIVE']
end

def with_env(key, value)
  old_env = ENV.fetch(key, nil)
  ENV[key] = value
  yield
ensure
  ENV[key] = old_env
end

def tmpdir
  File.expand_path '../tmp', File.dirname(__FILE__)
end
