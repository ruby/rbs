require_relative "test_helper"

class ModuleSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Module)"

  def test_used_modules
    assert_send_type "() -> Array[Module]",
                     Module, :used_modules
  end

  def test_used_refinements
    assert_send_type(
      "() -> Array[Refinement]",
      Module, :used_refinements
    )
  end
end

class ModuleInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Module"

  module Foo
    BAR = 1
  end

  def test_refine
    assert_send_type "(Module) { () -> void } -> Refinement",
                     Foo, :refine, String do nil end
  end

  def test_refinements
    assert_send_type(
      "() -> Array[Refinement]",
      Foo, :refinements
    )
  end

  def test_const_source_location
    assert_send_type "(Symbol) -> [String, Integer]",
                     Foo, :const_source_location, :BAR
    assert_send_type "(Symbol) -> nil",
                     Foo, :const_source_location, :UNKNOWN
    assert_send_type "(String) -> [String, Integer]",
                     Foo, :const_source_location, "BAR"
    assert_send_type "(String) -> nil",
                     Foo, :const_source_location, "UNKNOWN"
    assert_send_type "(Symbol, true) -> [String, Integer]",
                     Foo, :const_source_location, :BAR, true
    assert_send_type "(String, nil) -> [String, Integer]",
                     Foo, :const_source_location, "BAR", nil
    assert_send_type "(Symbol) -> [ ]",
                     Foo, :const_source_location, :String
    assert_send_type "(String) -> [ ]",
                     Foo, :const_source_location, "String"
    assert_send_type "(Symbol, true) -> [ ]",
                     Foo, :const_source_location, :String, true
    assert_send_type "(String, nil) -> nil",
                     Foo, :const_source_location, "String", nil
  end

  def test_module_eval
    assert_send_type "(String) -> nil",
                     Foo, :module_eval, 'nil'
    assert_send_type "(String, String) -> nil",
                     Foo, :module_eval, 'nil', __FILE__
    assert_send_type "(String, String, Integer) -> nil",
                     Foo, :module_eval, 'nil', __FILE__, 42

    assert_send_type "() { (Module) -> nil } -> nil",
                     Foo, :module_eval do nil end
  end

  def test_module_function
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_send_type(
      "() -> nil",
      mod, :module_function
    )
    assert_send_type(
      "(Symbol) -> Symbol",
      mod, :module_function, :foo
    )
    assert_send_type(
      "(String) -> String",
      mod, :module_function, "foo"
    )
    assert_send_type(
      "(ToStr) -> ToStr",
      mod, :module_function, ToStr.new("foo")
    )

    assert_send_type(
      "(Symbol, String) -> Array[Symbol | String]",
      mod, :module_function, :foo, "bar"
    )
  end

  def test_class_eval
    assert_send_type "(String) -> nil",
                     Foo, :class_eval, 'nil'
    assert_send_type "(String, String) -> nil",
                     Foo, :class_eval, 'nil', __FILE__
    assert_send_type "(String, String, Integer) -> nil",
                     Foo, :class_eval, 'nil', __FILE__, 42

    assert_send_type "() { (Module) -> nil } -> nil",
                     Foo, :class_eval do nil end
  end

  def test_alias_method
    mod = Module.new do
      def foo
      end
    end

    omit_if(mod.alias_method(:bar, :foo).equal?(mod))
    assert_send_type '(::Symbol new_name, ::Symbol old_name) -> ::Symbol',
                     mod, :alias_method, :bar2, :foo
    assert_send_type '(::String new_name, ::String old_name) -> ::Symbol',
                     mod, :alias_method, 'bar3', 'foo'
  end

  def test_private
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_send_type(
      "() -> nil",
      mod, :private
    )
    assert_send_type(
      "(Symbol) -> Symbol",
      mod, :private, :foo
    )
    assert_send_type(
      "(String) -> String",
      mod, :private, "foo"
    )
    assert_send_type(
      "(ToStr) -> ToStr",
      mod, :private, ToStr.new("foo")
    )

    assert_send_type(
      "(Symbol, String) -> Array[interned]",
      mod, :private, :foo, "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> Array[Symbol | String]",
      mod, :private, [:foo, "bar"]
    )
  end

  def test_private_class_method
    mod = Module.new do
      def self.foo; end
      def self.bar; end
    end

    assert_send_type(
      "(Symbol) -> self",
      mod, :private_class_method, :foo
    )

    assert_send_type(
      "(Symbol, Symbol) -> self",
      mod, :private_class_method, :foo, :bar
    )

    assert_send_type(
      "(String) -> self",
      mod, :private_class_method, "foo"
    )

    assert_send_type(
      "(String, String) -> self",
      mod, :private_class_method, "foo", "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> self",
      mod, :private_class_method, [:foo, "bar"]
    )
  end

  def test_protected
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_send_type(
      "() -> nil",
      mod, :protected
    )
    assert_send_type(
      "(Symbol) -> Symbol",
      mod, :protected, :foo
    )
    assert_send_type(
      "(String) -> String",
      mod, :protected, "foo"
    )
    assert_send_type(
      "(ToStr) -> ToStr",
      mod, :protected, ToStr.new("foo")
    )

    assert_send_type(
      "(Symbol, String) -> Array[Symbol | String]",
      mod, :protected, :foo, "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> Array[Symbol | String]",
      mod, :protected, [:foo, "bar"]
    )
  end

  def test_public
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_send_type(
      "() -> nil",
      mod, :public
    )
    assert_send_type(
      "(Symbol) -> Symbol",
      mod, :public, :foo
    )
    assert_send_type(
      "(String) -> String",
      mod, :public, "foo"
    )
    assert_send_type(
      "(ToStr) -> ToStr",
      mod, :public, ToStr.new("foo")
    )

    assert_send_type(
      "(Symbol, String) -> Array[interned]",
      mod, :public, :foo, "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> Array[Symbol | String]",
      mod, :public, [:foo, "bar"]
    )
  end

  def test_public_class_method
    mod = Module.new do
      def self.foo; end
      def self.bar; end
    end

    assert_send_type(
      "(Symbol) -> self",
      mod, :public_class_method, :foo
    )

    assert_send_type(
      "(Symbol, Symbol) -> self",
      mod, :public_class_method, :foo, :bar
    )

    assert_send_type(
      "(String) -> self",
      mod, :public_class_method, "foo"
    )

    assert_send_type(
      "(String, String) -> self",
      mod, :public_class_method, "foo", "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> self",
      mod, :public_class_method, [:foo, "bar"]
    )
  end

  def test_attr
    if RUBY_VERSION >= '3.0'
      mod = Module.new
      assert_send_type(
        "(*interned arg0) -> Array[Symbol]",
        mod, :attr, :foo
      )
    end
  end

  def test_attr_reader
    if RUBY_VERSION >= '3.0'
      mod = Module.new

      assert_send_type(
        "(Symbol) -> Array[Symbol]",
        mod, :attr_reader, :foo
      )

      assert_send_type(
        "(Symbol, Symbol) -> Array[Symbol]",
        mod, :attr_reader, :foo, :bar
      )

      assert_send_type(
        "(String) -> Array[Symbol]",
        mod, :attr_reader, "foo"
      )

      assert_send_type(
        "(String, String) -> Array[Symbol]",
        mod, :attr_reader, "foo", "bar"
      )

      assert_send_type(
        "(Symbol, String) -> Array[Symbol]",
        mod, :attr_reader, :foo, "bar"
      )
    end
  end

  def test_attr_writer
    if RUBY_VERSION >= '3.0'
      mod = Module.new

      assert_send_type(
        "(Symbol) -> Array[Symbol]",
        mod, :attr_writer, :foo
      )

      assert_send_type(
        "(Symbol, Symbol) -> Array[Symbol]",
        mod, :attr_writer, :foo, :bar
      )

      assert_send_type(
        "(String) -> Array[Symbol]",
        mod, :attr_writer, "foo"
      )

      assert_send_type(
        "(String, String) -> Array[Symbol]",
        mod, :attr_writer, "foo", "bar"
      )

      assert_send_type(
        "(Symbol, String) -> Array[Symbol]",
        mod, :attr_writer, :foo, "bar"
      )
    end
  end

  def test_attr_accessor
    if RUBY_VERSION >= '3.0'
      mod = Module.new

      assert_send_type(
        "(Symbol) -> Array[Symbol]",
        mod, :attr_accessor, :foo
      )

      assert_send_type(
        "(Symbol, Symbol) -> Array[Symbol]",
        mod, :attr_accessor, :foo, :bar
      )

      assert_send_type(
        "(String) -> Array[Symbol]",
        mod, :attr_accessor, "foo"
      )

      assert_send_type(
        "(String, String) -> Array[Symbol]",
        mod, :attr_accessor, "foo", "bar"
      )

      assert_send_type(
        "(Symbol, String) -> Array[Symbol]",
        mod, :attr_accessor, :foo, "bar"
      )
    end
  end

  def test_set_temporary_name
    mod = Module.new

    with_string "fake_name" do |name|
      assert_send_type(
        "(::string) -> ::Module",
        mod, :set_temporary_name, name
      )
    end

    assert_send_type(
      "(nil) -> Module",
      mod, :set_temporary_name, nil
    )
  end
end
