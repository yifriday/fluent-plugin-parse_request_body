require 'test_helper'
require 'fluent/plugin/filter_parse_request_body'

class ParseRequestBodyFilterTest < Test::Unit::TestCase
  URL = 'http://example.com:80'
  BODY_ONLY = {
      'uid' => 123456,
      'sid' => '123456fjkjafkjadk',
      'location' => '134.234,144.333'
    }

  def setup
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(
      Fluent::Plugin::ParseRequestBodyFilter
    ).configure(conf)
  end

  def filter(config, messages)
    d = create_driver(config)
    d.run(default_tag: "test") {
      messages.each {|message|
        d.feed(@time, message)
      }
    }
    d.filtered_records
  end

  def test_configure
    d = create_driver(%[
      key            request_body
      only           uid, sid
    ])

    assert_equal 'request_body',        d.instance.key
    assert_equal 'uid, sid',   d.instance.only
  end

  def test_filter
    config = %[
      key            request_body
    ]

    record = {
      'request_body' => BODY_ONLY,
    }
    expected = {
      'request_body' => BODY_ONLY,
      'location' => '134.234,144.333'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_field_prefix
    config = %[
      key            request_body
      add_field_prefix query_
    ]

    record = {
      'request_body' => BODY_ONLY,
    }
    expected = {
      'request_body' => BODY_ONLY,
      'query_uid' => 123456,
      'query_sid' => '123456fjkjafkjadk',
      'query_location' => '134.234,144.333'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_only
    config = %[
      key            request_body
      only           uid, sid
    ]

    record = { 'request_body' => BODY_ONLY }
    expected = {
      'request_body' => BODY_ONLY,
      'uid' => 123456,
      'sid' => '123456fjkjafkjadk',
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_except
    config = %[
      key            request_body
      except         uid
    ]

    record = { 'request_body' => BODY_ONLY }
    expected = {
      'sid' => '123456fjkjafkjadk',
      'location' => '134.234,144.333',
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_discard
    config = %[
      key            url
      discard_key true
    ]

    record = { 'request_body' => BODY_ONLY }
    expected = {
      'uid' => 123456,
      'sid' => '123456fjkjafkjadk',
      'location' => '134.234,144.333'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_multi_records
    config = %[
      key            request_body
      only           uid, sid
    ]
    records = [
      { 'request_body' => BODY_ONLY },
      { 'request_body' => BODY_ONLY },
      { 'request_body' => BODY_ONLY }
    ]
    expected = [
      { 'request_body' => BODY_ONLY, 'uid' => 123456, 'sid' => '123456fjkjafkjadk' },
      { 'request_body' => BODY_ONLY, 'uid' => 123456, 'sid' => '123456fjkjafkjadk' },
      { 'request_body' => BODY_ONLY, 'uid' => 123456, 'sid' => '123456fjkjafkjadk' }
    ]
    filtered = filter(config, records)
    assert_equal(expected, filtered)
  end

  def test_emit_without_match_key
    config = %[
      key            no_such_key
      only           uid, sid
    ]
    record = { 'request_body' => BODY_ONLY }
    filtered = filter(config, [record])
    assert_equal(record, filtered[0])
  end

  def test_emit_with_invalid_url
    config = %[
      key            request_body
    ]
    record = { 'request_body' => BODY_ONLY }
    filtered = filter(config, [record])
    assert_equal([record], filtered)
  end
end
