# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'nokogiri'

class SiteInspector
  module Formatter
    ACRONYMS = %w[
      acme cdn cms crm dns dnssec dnt hsts http https id ip ipv6 json paas pki sld ssl tld tls trd txt ui uri url whois www xml xss
    ].freeze

    def format_table(hash)
      build_fragment do |f|
        f.table(class: 'table table-striped') do
          hash.each do |key, value|
            f << format_key_value(key, value)
          end
        end
      end
    end

    def format_key(string)
      capitalize_acronyms(string.to_s.gsub(/^x-/, '').tr('-', ' ').humanize)
    end

    def format_value(value)
      case value
      when Hash
        format_hash(value)
      when Array
        format_array(value)
      else
        format_string(value)
      end
    end

    def format_key_value(key, value, check = nil)
      c = class_for_value(value)

      build_fragment do |f|
        f.tr do
          f.th { f.text format_key(key) }
          f.td(c) do
            uri = check&.uri_for(key)

            if value == true && uri
              f.a({ href: uri }.merge(c)) { f << format_value(value) }
            else
              f << format_value(value)
            end
          end
        end
      end
    end

    private

    def class_for_value(value)
      if value.instance_of?(TrueClass)
        { class: 'text-success' }
      elsif value.instance_of?(FalseClass)
        { class: 'text-danger' }
      else
        {}
      end
    end

    def build_fragment(&block)
      fragment = Nokogiri::HTML::DocumentFragment.parse ''
      Nokogiri::HTML::Builder.with(fragment, &block)
      fragment.to_s
    end

    def capitalize_acronyms(string)
      string.gsub(/\b(#{ACRONYMS.join("|")})\b/i) do
        Regexp.last_match(1).to_s.upcase
      end
    end

    def format_string(value)
      value = CGI.escapeHTML(value.to_s)

      if %r{^https?:/}.match?(value)
        value = build_fragment do |f|
          f.a(href: value) { f.text value }
        end
      end

      value
    end

    def format_hash(hash)
      build_fragment do |f|
        f.ul do
          hash.each do |key, value|
            f.li do
              f.span(class: 'font-weight-bold') { f.text format_key(key) }
              f.text ': '
              f << format_value(value)
            end
          end
        end
      end
    end

    def format_array(array)
      return format_value(array[0]) if array.length == 1

      build_fragment do |f|
        f.ol do
          array.each do |el|
            f.li { f << format_value(el) }
          end
        end
      end
    end
  end
end
