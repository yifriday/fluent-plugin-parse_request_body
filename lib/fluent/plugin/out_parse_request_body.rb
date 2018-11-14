require "fluent/plugin/output"
require "fluent/plugin/parse_request_body_extractor"

module Fluent::Plugin
  class ParseRequestBodyOutput < Fluent::Plugin::Output
    include Fluent::HandleTagNameMixin

    #注册output名称#
    Fluent::Plugin.register_output('parse_request_body', self)

    helpers :event_emitter

    #request body在record中所对应的key#
    desc "point a key whose value contains body string."
    config_param :key,    :string
    #需要使用array_value替换数据的key#
    desc "point a key who will be replaced."
    config_param :replace_key,    :string, default: nil
    #需要被组合在一起的数据名称#
    desc "If set, the key/value will be reformd array whose would be added to the record."
    config_param :array_value,   :string, default: nil
    #最终组合数据在record中的key#
    desc "array_value's key in record"
    config_param :array_value_key,   :string, default: nil
    #request body解析数据白名单#
    desc "If set, only the key/value whose key is included only will be added to the record."
    config_param :only,   :string, default: nil
    #request body解析数据黑名单#
    desc "If set, the key/value whose key is included except will NOT be added to the record."
    config_param :except, :string, default: nil
    #是否只保留最终解析出来的数据，而删除request body原数据#
    desc "If set to true, the original key url will be discarded from the record."
    config_param :discard_key, :bool, default: false
    #给解析出的数据key添加前缀#
    desc "Prefix of fields."
    config_param :add_field_prefix, :string, default: nil
    #是否允许解析空key#
    desc "If set to true, permit blank key."
    config_param :permit_blank_key, :bool, default: false

    #初始化解析器#
    def configure(conf)
      super
      @extractor = Fluent::Plugin::ParseRequestBodyExtractor.new(self, conf)
    end

    def multi_workers_ready?
      true
    end

    #执行解析工作#
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
