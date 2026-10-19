require_relative "test_helper"
require "weakref"

class WeakRefSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "weakref"
  testing "singleton(::WeakRef)"

  def test_version
    assert_const_type "String", "WeakRef::VERSION"
  end

  def test_new
    obj = "foo"

    assert_send_type "(String) -> WeakRef",
                     WeakRef, :new, obj
  end
end

class WeakRefTest < Test::Unit::TestCase
  include TestHelper

  library "weakref"
  testing "::WeakRef"

  def setup
    @obj = "foo"
    @ref = WeakRef.new(@obj)
  end

  def test___getobj__
    assert_send_type "() -> String",
                     @ref, :__getobj__
  end

  def test___setobj__
    assert_send_type "(String) -> void",
                     @ref, :__setobj__, "bar"
  end

  def test_weakref_alive?
    assert_send_type "() -> bool",
                     @ref, :weakref_alive?
  end
end
