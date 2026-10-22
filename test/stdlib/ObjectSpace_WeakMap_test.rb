require_relative "test_helper"
require 'objspace'

class ObjectSpace_WeakMapTest < Test::Unit::TestCase
  include TestHelper

  testing "::ObjectSpace::WeakMap[::String, ::Object]"

  def test_aref
    k1 = "foo"
    v1 = Object.new
    map = ObjectSpace::WeakMap.new()

    map[k1] = v1

    assert_send_type(
      "(::String) -> ::Object",
      map, :[], k1
    )

    assert_send_type(
      "(::String) -> nil",
      map, :[], "bar"
    )
  end

  def test_aref_update
    k1 = "foo"
    k2 = "bar"
    v1 = Object.new
    map = ObjectSpace::WeakMap.new()

    assert_send_type(
      "(::String, ::Object) -> ::Object",
      map, :[]=, k1, v1
    )

    assert_send_type(
      "(::String, nil) -> nil",
      map, :[]=, k2, nil
    )
  end

  def test_delete
    map = ObjectSpace::WeakMap.new()

    k1 = "foo"
    k2 = "bar"
    v1 = Object.new

    map[k1] = v1
    map[k2] = v1

    assert_send_type(
      "(::String) -> ::Object",
      map, :delete, "foo"
    )
    assert_send_type(
      "(::String) -> nil",
      map, :delete, "foo"
    )

    assert_send_type(
      "(::String) { (::String) -> nil } -> ::Object",
      map, :delete, "bar", &proc { nil }
    )
    assert_send_type(
      "(::String) { (::String) -> ::String } -> ::Object",
      map, :delete, "bar", &proc { "Hello" }
    )
  end

  def test_inspect
    map = ObjectSpace::WeakMap.new()

    map["foo"] = 123

    assert_send_type(
      "() -> ::String",
      map, :inspect
    )
  end

  def test_key?
    map = ObjectSpace::WeakMap.new()

    map["foo"] = 123

    assert_send_type(
      "(::String) -> bool",
      map, :key?, "foo"
    )
  end
end
