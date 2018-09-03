require 'uri'
require 'cgi/util'
require 'webrick'

module Fluent::Plugin
  class ParseRequestBodyExtractor

    attr_reader :log

    def initialize(plugin, conf)
      @log = plugin.log

      if plugin.is_a?(Fluent::Plugin::Output)
        unless have_tag_option?(plugin)
          raise Fluent::ConfigError, "out_parse_request_body: At least one of remove_tag_prefix/remove_tag_suffix/add_tag_prefix/add_tag_suffix is required to be set."
        end
      end

      @key = plugin.key
      @only = plugin.only
      @except = plugin.except
      @discard_key = plugin.discard_key
      @add_field_prefix = plugin.add_field_prefix
      @permit_blank_key = plugin.permit_blank_key

      if @only
        @include_keys = @only.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end

      if @except
        @exclude_keys = @except.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end
    end

    def add_query_params_field(record)
      return record unless record[@key]
      add_query_params(record[@key], record)
      record.delete(@key) if @discard_key
      record
    end

    private

    def have_tag_option?(plugin)
      plugin.remove_tag_prefix ||
        plugin.remove_tag_suffix ||
        plugin.add_tag_prefix    ||
        plugin.add_tag_suffix
    end

    def create_field_key(field_key)
      if add_field_prefix?
        "#{@add_field_prefix}#{field_key}"
      else
        field_key
      end
    end

    def add_field_prefix?
      !!@add_field_prefix
    end

    def permit_blank_key?
      @permit_blank_key
    end

    def add_query_params(body, record)
      return if body.nil?
      body.split('&').each do |pair|
        key, value = pair.split('=', 2).map { |i| CGI.unescape(i) }
        next if (key.nil? || key.empty?) && (!permit_blank_key? || value.nil? || value.empty?)
        key ||= ''
        value ||= ''

        key = create_field_key(key)
        if @only
          record[key] = value if @include_keys.has_key?(key)
        elsif @except
          record[key] = value if !@exclude_keys.has_key?(key)
        else
          record[key] = value
        end
      end
    end
  end
end