require_relative "test_helper"
require_relative 'Module_test_helper'

class ModuleSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Module)"

  def test_used_modules
    assert_send_type "() -> Array[Module]",
                     Module, :used_modules

    assert_type 'Array[Module]',
                ModuleTestHelperRefinement::USED_MODULES
  end

  def test_used_refinements
    assert_send_type "() -> Array[Refinement]",
                     Module, :used_refinements

    assert_type 'Array[Refinement]',
                ModuleTestHelperRefinement::USED_REFINEMENTS
  end

  def test_constants
    assert_send_type '() -> Array[Symbol]',
                     Module, :constants

    with_boolish do |inherit|
      assert_send_type '(boolish) -> Array[Symbol]',
                       Module, :constants, inherit
    end
  end

  def test_nesting
    assert_send_type '() -> Array[Module]',
                     Module, :nesting
  end
end

class ModuleInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Module"

  module Foo
    BAR = 1

    def foo(meth, *args, &block)
    end
  end

  def test_op_lt
    with Object, Float, Hash do |mod|
      assert_send_type  '(Module) -> bool?',
                        Numeric, :<, mod
    end
  end

  def test_op_le
    with Object, Float, Hash do |mod|
      assert_send_type  '(Module) -> bool?',
                        Numeric, :<=, mod
    end
  end

  def test_op_gt
    with Object, Float, Hash do |mod|
      assert_send_type  '(Module) -> bool?',
                        Numeric, :>, mod
    end
  end

  def test_op_ge
    with Object, Float, Hash do |mod|
      assert_send_type  '(Module) -> bool?',
                        Numeric, :>=, mod
    end
  end

  def test_op_cmp
    with Object, Float, Numeric, Hash do |mod|
      assert_send_type  '(untyped) -> (-1 | 0 | 1)?',
                        Numeric, :<=>, mod
    end

    with_untyped do |untyped|
      next if Module === untyped
      assert_send_type  '(untyped) -> nil',
                        Numeric, :<=>, untyped
    end
  end

  def test_op_eq
    with_untyped.and Numeric, Module do |untyped|
      assert_send_type  '(untyped) -> bool',
                        Numeric, :==, untyped
    end
  end

  def test_op_eqq
    with_untyped.and Numeric, Module do |untyped|
      assert_send_type  '(untyped) -> bool',
                        Numeric, :===, untyped
    end
  end

  def test_include
    assert_send_type "(Module) -> Module",
                     Module.new, :include, Module.new
    assert_send_type "(Module, Module) -> Module",
                     Module.new, :include, Module.new, Module.new
  end

  def test_prepend
    assert_send_type "(Module) -> Module",
                     Module.new, :prepend, Module.new
    assert_send_type "(Module, Module) -> Module",
                     Module.new, :prepend, Module.new, Module.new
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

  def test_class_exec
    assert_send_type '(*String) { (*String) [self: Foo] -> Integer } -> Integer',
                      Foo, :class_exec, '1', '2' do |*x| x.join.to_i end
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
      "(Symbol) -> Module",
      mod, :private_class_method, :foo
    )

    assert_send_type(
      "(Symbol, Symbol) -> Module",
      mod, :private_class_method, :foo, :bar
    )

    assert_send_type(
      "(String) -> Module",
      mod, :private_class_method, "foo"
    )

    assert_send_type(
      "(String, String) -> Module",
      mod, :private_class_method, "foo", "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> Module",
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
      "(Symbol) -> Module",
      mod, :public_class_method, :foo
    )

    assert_send_type(
      "(Symbol, Symbol) -> Module",
      mod, :public_class_method, :foo, :bar
    )

    assert_send_type(
      "(String) -> Module",
      mod, :public_class_method, "foo"
    )

    assert_send_type(
      "(String, String) -> Module",
      mod, :public_class_method, "foo", "bar"
    )

    assert_send_type(
      "(Array[Symbol | String]) -> Module",
      mod, :public_class_method, [:foo, "bar"]
    )
  end

  def test_attr
    mod = Module.new
    assert_send_type(
      "(*interned arg0) -> Array[Symbol]",
      mod, :attr, :foo
    )
  end

  def test_attr_reader
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

  def test_attr_writer
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

  def test_attr_accessor
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

  def test_ruby2_keywords
    assert_send_type(
      "(Symbol) -> nil",
      Foo, :ruby2_keywords, :foo
    )
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

  def test_to_s(method: :to_s)
    omit 'todo'
  end

  def test_inspect
    test_to_s(method: :inspcet)
  end

  def test_ancestors
    omit 'todo'
  end

  def test_autoload
    omit 'todo'
  end

  def test_autoload
    omit 'todo'
  end

  def test_class_variable_defined
    omit 'todo'
  end

  def test_class_variable_get
    omit 'todo'
  end

  def test_class_variable_set
    omit 'todo'
  end

  def test_class_variables
    omit 'todo'
  end

  def test_const_defined
    omit 'todo'
  end

  def test_const_get
    omit 'todo'
  end

  def test_const_missing
    omit 'todo'
  end

  def test_const_set
    omit 'todo'
  end

  def test_define_method
    omit 'todo'
  end

  def test_deprecate_constant
    omit 'todo'
  end

  def test_freeze
    omit 'todo'
  end

  def test_included_modules
    omit 'todo'
  end

  def test_initialize
    omit 'todo'
  end

  def test_initialize_clone
    omit 'todo'
  end

  def test_instance_method
    omit 'todo'
  end

  def test_instance_methods
    omit 'todo'
  end

  def test_method_defined
    omit 'todo'
  end

  def test_module_exec
    omit 'todo'
  end

  def test_name
    omit 'todo'
  end

  def test_private_constant
    omit 'todo'
  end

  def test_private_instance_methods
    omit 'todo'
  end

  def test_private_method_defined
    omit 'todo'
  end

  def test_protected_instance_methods
    omit 'todo'
  end

  def test_protected_method_defined
    omit 'todo'
  end

  def test_public_constant
    omit 'todo'
  end

  def test_public_instance_method
    omit 'todo'
  end

  def test_public_instance_methods
    omit 'todo'
  end

  def test_public_method_defined
    omit 'todo'
  end

  def test_remove_class_variable
    omit 'todo'
  end

  def test_remove_method
    omit 'todo'
  end

  def test_singleton_class
    omit 'todo'
  end

  def test_undef_method
    omit 'todo'
  end

  def test_undefined_instance_methods
    omit 'todo'
  end

  def test_append_features
    omit 'todo' # private
  end

  def test_const_added
    omit 'todo' # private
  end

  def test_extend_object
    omit 'todo' # private
  end

  def test_extended
    omit 'todo' # private
  end

  def test_included
    omit 'todo' # private
  end

  def test_method_added
    omit 'todo' # private
  end

  def test_method_removed
    omit 'todo' # private
  end

  def test_method_undefined
    omit 'todo' # private
  end

  def test_prepend_features
    omit 'todo' # private
  end

  def test_prepended
    omit 'todo' # private
  end

  def test_remove_const
    omit 'todo' # private
  end

  def test_using
    omit 'todo' # private
  end
end
