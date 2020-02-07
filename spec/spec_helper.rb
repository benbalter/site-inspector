# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'
require 'fileutils'
require_relative '../lib/site-inspector'

WebMock.disable_net_connect!

def with_env(key, value)
  old_env = ENV[key]
  ENV[key] = value
  yield
  ENV[key] = old_env
end

def tmpdir
  File.expand_path '../tmp', File.dirname(__FILE__)
end
