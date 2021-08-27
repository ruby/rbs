require_relative "test_helper"
require "forwardable"

class ForwardableTest < Test::Unit::TestCase
  include TypeAssertions

  library "forwardable"
  testing "::Forwardable"

  class Foo
    extend Forwardable
  end

  def test_instance_delegate
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     Foo, :instance_delegate, foo: :bar
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     Foo, :instance_delegate, foo1: :bar, foo2: :bar
    assert_send_type "(::Hash[::Array[::Symbol], ::Symbol]) -> void",
                     Foo, :instance_delegate, [:foo1, :foo2] => :bar
    assert_send_type "(::Hash[(::Symbol | ::Array[::Symbol]), ::Symbol]) -> void",
                     Foo, :instance_delegate, foo1: :bar, [:foo2, :foo3] => :baz
  end

  def test_delegate
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     Foo, :delegate, foo: :bar
  end

  def test_def_instance_delegators
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, :foo, :bar
    assert_send_type "(::Symbol, ::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, :foo, :bar, :baz
    assert_send_type "(::String, ::Symbol) -> void",
                     Foo, :def_instance_delegators, "foo", :bar
    assert_send_type "(::String, ::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, "foo", :bar, :baz
  end

  def test_def_delegators
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     Foo, :def_delegators, :foo, :bar
    assert_send_type "(::String, ::Symbol) -> void",
                     Foo, :def_delegators, "foo", :bar
  end

  def test_def_instance_delegator
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, :foo, :bar
    assert_send_type "(::Symbol, ::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, :foo, :bar, :baz
    assert_send_type "(::String, ::Symbol) -> void",
                     Foo, :def_instance_delegators, "foo", :bar
    assert_send_type "(::String, ::Symbol, ::Symbol) -> void",
                     Foo, :def_instance_delegators, "foo", :bar, :baz
  end

  def test_def_delegator
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     Foo, :def_delegator, :foo, :bar
    assert_send_type "(::String, ::Symbol) -> void",
                     Foo, :def_delegator, "foo", :bar
  end
end

class SingleForwardableTest < Test::Unit::TestCase
  include TypeAssertions

  library "forwardable"
  testing "::SingleForwardable"

  def setup
    @tested = Object.new
    @tested.extend SingleForwardable
  end

  def test_single_delegate
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     @tested, :single_delegate, foo: :bar
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     @tested, :single_delegate, foo1: :bar, foo2: :bar
    assert_send_type "(::Hash[::Array[::Symbol], ::Symbol]) -> void",
                     @tested, :single_delegate, [:foo1, :foo2] => :bar
    assert_send_type "(::Hash[(::Symbol | ::Array[::Symbol]), ::Symbol]) -> void",
                     @tested, :single_delegate, foo1: :bar, [:foo2, :foo3] => :baz
  end

  def test_delegate
    assert_send_type "(::Hash[::Symbol, ::Symbol]) -> void",
                     @tested, :delegate, foo: :bar
  end

  def test_def_single_delegators
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegators, :foo, :bar
    assert_send_type "(::Symbol, ::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegators, :foo, :bar, :baz
    assert_send_type "(::String, ::Symbol) -> void",
                     @tested, :def_single_delegators, "foo", :bar
    assert_send_type "(::String, ::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegators, "foo", :bar, :baz
  end

  def test_def_delegators
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     @tested, :def_delegators, :foo, :bar
    assert_send_type "(::String, ::Symbol) -> void",
                     @tested, :def_delegators, "foo", :bar
  end

  def test_def_single_delegator
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegator, :foo, :bar
    assert_send_type "(::Symbol, ::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegator, :foo, :bar, :baz
    assert_send_type "(::String, ::Symbol) -> void",
                     @tested, :def_single_delegator, "foo", :bar
    assert_send_type "(::String, ::Symbol, ::Symbol) -> void",
                     @tested, :def_single_delegator, "foo", :bar, :baz
  end

  def test_def_delegator
    assert_send_type "(::Symbol, ::Symbol) -> void",
                     @tested, :def_delegator, :foo, :bar
    assert_send_type "(::String, ::Symbol) -> void",
                     @tested, :def_delegator, "foo", :bar
  end
end
