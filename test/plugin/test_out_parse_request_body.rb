require 'test_helper'
require 'fluent/plugin/out_parse_request_body'

class ParseRequestBodyOutputTest < Test::Unit::TestCase
  URL = 'http://example.com:80'
  BODY_ONLY = {
      'uid' => 123456,
      'sid' => '123456fjkjafkjadk',
      'location' => '134.234,144.333'
    }

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(
      Fluent::Plugin::ParseRequestBodyOutput
    ).configure(conf)
  end

  def test_configure
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      only           uid, sid
    ])

    assert_equal 'request_body',        d.instance.key
    assert_equal 'extracted.', d.instance.add_tag_prefix
    assert_equal 'uid, sid',   d.instance.only

    # when mandatory keys not set
    assert_raise(Fluent::ConfigError) do
      create_driver(%[
        key uid
      ])
    end
  end

  def test_filter_record
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
    ])

    record = {
      'request_body' => BODY_ONLY,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal BODY_ONLY,               record['request_body']
    assert_equal 123456,                  record['uid']
    assert_equal '123456fjkjafkjadk',     record['sid']
    assert_equal '134.234,144.333',       record['location']
  end

  def test_filter_record_with_field_prefix
    d = create_driver(%[
      key            request_body
      add_field_prefix query_
      add_tag_prefix extracted.
    ])

    record = {
      'request_body' => BODY_ONLY,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal BODY_ONLY,       record['request_body']
    assert_nil record['uid']
    assert_nil record['sid']
    assert_nil record['location']
    assert_equal 123456,     record['query_uid']
    assert_equal '123456fjkjafkjadk',     record['query_sid']
    assert_equal '134.234,144.333', record['query_location']
  end

  def test_filter_record_with_only
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      only           uid, sid
    ])

    record = { 'request_body' => BODY_ONLY }
    d.instance.filter_record('test', Time.now, record)

    assert_equal BODY_ONLY,   record['request_body']
    assert_equal 123456, record['uid']
    assert_equal '123456fjkjafkjadk', record['sid']
    assert_nil record['location']
  end

  def test_filter_record_with_except
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      except         baz, モリス
    ])

    record = { 'request_body' => BODY_ONLY }
    d.instance.filter_record('test', Time.now, record)

    assert_equal BODY_ONLY,   record['request_body']
    assert_equal 123456, record['uid']
    assert_nil record['sid']
    assert_nil record['location']
  end

  def test_filter_record_with_discard
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      discard_key true
    ])

    record = { 'request_body' => BODY_ONLY }
    d.instance.filter_record('test', Time.now, record)

    assert_nil               record['nil']
    assert_nil               record['request_body']
    assert_equal 123456,      record['uid']
    assert_equal '123456fjkjafkjadk',      record['sid']
    assert_equal '134.234,144.333', record['location']
  end

  def test_emit
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      only           uid, sid
    ])
    d.run(default_tag: "test") { d.feed('request_body' => BODY_ONLY) }
    events = d.events

    assert_equal 1, events.count
    assert_equal 'extracted.test', events[0][0]
    assert_equal BODY_ONLY,              events[0][2]['request_body']
    assert_equal 123456,            events[0][2]['uid']
    assert_equal '123456fjkjafkjadk',            events[0][2]['sid']
  end

  def test_emit_multi
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
      only           uid, sid
    ])
    d.run(default_tag: "test") do
      d.feed('request_body' => BODY_ONLY)
      d.feed('request_body' => BODY_ONLY)
      d.feed('request_body' => BODY_ONLY)
    end
    events = d.events

    assert_equal 3, events.count

    events.each do |e|
      assert_equal 'extracted.test', e[0]
      assert_equal BODY_ONLY,              e[2]['request_body']
      assert_equal 123456,            e[2]['uid']
      assert_equal '123456fjkjafkjadk',            e[2]['sid']
    end
  end

  def test_emit_without_match_key
    d = create_driver(%[
      key            no_such_key
      add_tag_prefix extracted.
      only           uid, sid
    ])
    d.run(default_tag: "test") { d.feed('request_body' => BODY_ONLY) }
    events = d.events

    assert_equal 1, events.count
    assert_equal 'extracted.test', events[0][0]
    assert_equal BODY_ONLY,              events[0][2]['request_body']
  end

  def test_emit_with_invalid_url
    d = create_driver(%[
      key            request_body
      add_tag_prefix extracted.
    ])
    d.run(default_tag: "test") { d.feed('request_body' => 'invalid url') }
    events = d.events

    assert_equal 1, events.count
    assert_equal 'extracted.test', events[0][0]
    assert_equal 'invalid url',    events[0][2]['request_body']
  end
end
