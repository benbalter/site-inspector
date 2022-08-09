# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'
require 'fileutils'
require 'site-inspector'

WebMock.disable_net_connect!

def with_env(key, value)
  old_env = ENV.fetch(key, nil)
  ENV[key] = value
  yield
  ENV[key] = old_env
end

def tmpdir
  File.expand_path '../tmp', File.dirname(__FILE__)
end
