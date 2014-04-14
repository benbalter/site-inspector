require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
gem "minitest"
require 'minitest/autorun'
require 'shoulda'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path 'fixtures/vcr_cassettes', File.dirname(__FILE__)
  c.hook_into :webmock
  c.allow_http_connections_when_no_cassette = true
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'site-inspector'
