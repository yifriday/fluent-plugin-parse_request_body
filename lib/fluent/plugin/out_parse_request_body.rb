require "fluent/plugin/output"
require "fluent/plugin/parse_request_body_extractor"

module Fluent::Plugin
  class ParseRequestBodyOutput < Fluent::Plugin::Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('parse_request_body', self)

    helpers :event_emitter

    desc "point a key whose value contains body string."
    config_param :key,    :string
    desc "point a key who will be replaced."
    config_param :replace_key,    :string, default: nil
    desc "If set, the key/value will be reformd array whose would be added to the record."
    config_param :array_value,   :string, default: nil
    desc "array_value's key in record"
    config_param :array_value_key,   :string, default: nil
    desc "If set, only the key/value whose key is included only will be added to the record."
    config_param :only,   :string, default: nil
    desc "If set, the key/value whose key is included except will NOT be added to the record."
    config_param :except, :string, default: nil
    desc "If set to true, the original key url will be discarded from the record."
    config_param :discard_key, :bool, default: false
    desc "Prefix of fields."
    config_param :add_field_prefix, :string, default: nil
    desc "If set to true, permit blank key."
    config_param :permit_blank_key, :bool, default: false

    def configure(conf)
      super
      @extractor = Fluent::Plugin::ParseRequestBodyExtractor.new(self, conf)
    end

    def multi_workers_ready?
      true
    end

    def filter_record(tag, time, record)
      record = @extractor.add_query_params_field(record)
      super(tag, time, record)
    end

    def process(tag, es)
      es.each do |time, record|
        t = tag.dup
        filter_record(t, time, record)
        router.emit(t, time, record)
      end
    end
  end
end
