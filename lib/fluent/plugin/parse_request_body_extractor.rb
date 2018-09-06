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
      @array_value = plugin.array_value
      @array_value_key = plugin.array_value_key
      @replace_key = plugin.replace_key

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

      if @array_value_key
        if @array_value
          @include_array_value = @array_value.split(/\s*,\s*/).inject({}) do |hash, i|
            hash[i] = true
            hash
          end
        end
      end

    end

    def add_query_params_field(record)
      return record unless record[@key]
      add_query_params(record[@key], record)
      replace_record_by_key(record) if @replace_key
      record.delete(@key) if @discard_key
      record
    end

    private

    def replace_record_by_key(record)
      return record unless record[@replace_key]
      replace_value = record[@array_value_key]
      if replace_value && replace_value.to_i
        record[@replace_key] = replace_value
      end
    end

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
      placeholder = []
      body.split('&').each do |pair|
        key, value = pair.split('=', 2).map { |i| CGI.unescape(i) }
        next if (key.nil? || key.empty?) && (!permit_blank_key? || value.nil? || value.empty?)
        key ||= ''
        value ||= ''

        new_key = create_field_key(key)
        if @only
          record[new_key] = value if @include_keys.has_key?(key)
        elsif @except
          record[new_key] = value if !@exclude_keys.has_key?(key)
        else
          record[new_key] = value
        end

        if @include_array_value
          placeholder[placeholder.size] = value.to_f if @include_array_value.has_key?(key)
        end
      end

      unless placeholder.empty?
        record[@array_value_key] = placeholder
      end
    end
  end
end
