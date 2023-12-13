require_relative "test_helper"
require 'objspace'

class ObjectSpace_WeakKeyMapTest < Test::Unit::TestCase
  include TestHelper

  testing "::ObjectSpace::WeakKeyMap[::String, ::Integer]"

  def test_aref
    map = ObjectSpace::WeakKeyMap.new()

    map["foo"] = 123

    assert_send_type(
      "(::String) -> ::Integer",
      map, :[], "foo"
    )

    assert_send_type(
      "(::String) -> nil",
      map, :[], "bar"
    )
  end

  def test_aref_update
    map = ObjectSpace::WeakKeyMap.new()

    assert_send_type(
      "(::String, ::Integer) -> ::Integer",
      map, :[]=, "foo", 123
    )

    assert_send_type(
      "(::String, nil) -> nil",
      map, :[]=, "bar", nil
    )
  end

  def test_clear
    map = ObjectSpace::WeakKeyMap.new()

    assert_send_type(
      "() -> ::ObjectSpace::WeakKeyMap",
      map, :clear
    )
  end

  def test_delete
    map = ObjectSpace::WeakKeyMap.new()

    map["foo"] = 123
    map["bar"] = 123

    assert_send_type(
      "(::String) -> ::Integer",
      map, :delete, "foo"
    )
    assert_send_type(
      "(::String) -> nil",
      map, :delete, "foo"
    )

    assert_send_type(
      "(::String) { (::String) -> nil } -> ::Integer",
      map, :delete, "bar", &proc { nil }
    )
    assert_send_type(
      "(::String) { (::String) -> ::String } -> ::String",
      map, :delete, "bar", &proc { "Hello" }
    )
  end

  def test_getkey
    map = ObjectSpace::WeakKeyMap.new()

    map["foo"] = 123

    assert_send_type(
      "(::Integer) -> ::String",
      map, :getkey, 123
    )
    assert_send_type(
      "(::String) -> nil",
      map, :getkey, "abc"
    )
  end

  def test_inspect
    map = ObjectSpace::WeakKeyMap.new()

    map["foo"] = 123

    assert_send_type(
      "() -> ::String",
      map, :inspect
    )
  end

  def test_key?
    map = ObjectSpace::WeakKeyMap.new()

    map["foo"] = 123

    assert_send_type(
      "(::String) -> bool",
      map, :key?, "foo"
    )
  end
end
