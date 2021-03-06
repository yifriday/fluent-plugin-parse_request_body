require 'uri'
require 'cgi/util'
require 'webrick'

module Fluent::Plugin
  class ParseRequestBodyExtractor

    attr_reader :log
        
    #初始化解析器#
    def initialize(plugin, conf)
      @log = plugin.log

      if plugin.is_a?(Fluent::Plugin::Output)
        unless have_tag_option?(plugin)
          raise Fluent::ConfigError, "out_parse_request_body: At least one of remove_tag_prefix/remove_tag_suffix/add_tag_prefix/add_tag_suffix is required to be set."
        end
      end

      #从配置中读取配置选项#
      @key = plugin.key
      @only = plugin.only
      @except = plugin.except
      @discard_key = plugin.discard_key
      @add_field_prefix = plugin.add_field_prefix
      @permit_blank_key = plugin.permit_blank_key
      @array_value = plugin.array_value
      @array_value_key = plugin.array_value_key
      @replace_key = plugin.replace_key

      #初始化白名单#
      if @only
        @include_keys = @only.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end

      #初始化黑名单#
      if @except
        @exclude_keys = @except.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end

      #初始化需要被组合的key#
      if @array_value_key
        if @array_value
          @include_array_value = @array_value.split(/\s*,\s*/).inject({}) do |hash, i|
            hash[i] = true
            hash
          end
        end
      end

    end

    #解析方法#
    def add_query_params_field(record)
      return record unless record[@key]
      add_query_params(record[@key], record)
      replace_record_by_key(record) if @replace_key
      record.delete(@key) if @discard_key
      record
    end

    private

    #替换record中某一个键值#
    def replace_record_by_key(record)
      return record unless record[@replace_key]
      replace_value = record[@array_value_key]
      if replace_value
        empty_value = replace_value.select {|item| item == 0 }
        if (empty_value.size != replace_value.size)
          record[@replace_key] = replace_value
        end
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
      keyCcount = 0
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

        if @include_array_value && @include_array_value.has_key?(key) && (value.to_f != 0)
          @include_array_value[key] = value.to_f
          keyCcount += 1
        end
      end

      if @include_array_value.length == keyCcount
        record[@array_value_key] = @include_array_value.values
      end
    end
  end
end
