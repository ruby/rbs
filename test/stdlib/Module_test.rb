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

  module RefinedModule
    refine String do
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
    assert_send_type "(Module, *Module) -> Module",
                     Module.new, :include, Module.new, Module.new
  end

  def test_prepend
    assert_send_type "(Module) -> Module",
                     Module.new, :prepend, Module.new
    assert_send_type "(Module, *Module) -> Module",
                     Module.new, :prepend, Module.new, Module.new
  end

  def test_refine
    assert_send_type "(Module) { () -> void } -> Refinement",
                     RefinedModule, :refine, Integer do nil end

    assert_visibility :private,
                      RefinedModule, :refine
  end

  def test_refinements
    assert_send_type "() -> Array[Refinement]",
                     Module.new, :refinements

    assert_send_type "() -> Array[Refinement]",
                     RefinedModule, :refinements
  end

  def test_const_source_location
    with_interned :BAR do |interned|
      assert_send_type "(interned) -> [String, Integer]",
                       Foo, :const_source_location, interned

      with_boolish.and_nil do |boolish|
        assert_send_type "(interned, boolish) -> [String, Integer]",
                         Foo, :const_source_location, interned, boolish
      end
    end

    with_interned :UNKNOWN do |interned|
      assert_send_type "(interned) -> nil",
                       Foo, :const_source_location, interned

      with_boolish.and_nil do |boolish|
        assert_send_type "(interned, boolish) -> nil",
                         Foo, :const_source_location, interned, boolish
      end
    end

    with_interned :String do |interned|
      assert_send_type "(interned) -> []",
                       Foo, :const_source_location, interned

      with_boolish.and_nil do |boolish|
        assert_send_type "(interned, boolish) -> []?",
                         Foo, :const_source_location, interned, boolish
      end
    end
  end

  def test_module_eval(method: :module_eval)
    with_string 'nil' do |code|
      assert_send_type "(string) -> untyped",
                       Foo, method, code

      with_string.and_nil do |file|
        assert_send_type "(string, string?) -> untyped",
                         Foo, method, code, file

        with_int do |lineno|
          assert_send_type "(string, string?, int) -> untyped",
                           Foo, method, code, file, lineno
        end
      end
    end

    assert_send_type '() { (Module) [self: Foo] -> Rational } -> Rational',
                      Foo, method do 1r end
  end

  def test_module_exec(method: :module_exec)
    assert_send_type '(*String) { (*String) [self: Foo] -> Integer } -> Integer',
                      Foo, method, '1', '2' do |*x| x.join.to_i end
  end

  def test_module_function
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_visibility :private,
                      mod, :module_function

    # No arguments
    assert_send_type  '() -> nil',
                      mod, :module_function

    # Single argument
    assert_send_type  '(Symbol) -> Symbol',
                      mod, :module_function, :foo

    with_string 'foo' do |foo|
      assert_send_type  '[T < _ToStr] (T) -> T',
                        mod, :module_function, foo
    end

    with_interned 'foo' do |foo|
      assert_send_type  '(interned) -> interned',
                        mod, :module_function, foo
    end

    # Multiple arguments
    assert_send_type  '(Symbol, *Symbol) -> Array[Symbol]',
                      mod, :module_function, :foo, :bar

    with_string 'foo' do |foo|
      with_string 'bar' do |bar|
        assert_send_type  '[T < _ToStr] (T, *T) -> Array[T]',
                          mod, :module_function, foo, bar
      end
    end

    with_interned 'foo' do |foo|
      with_interned 'bar' do |bar|
        assert_send_type  '(interned, *interned) -> Array[interned]',
                          mod, :module_function, foo, bar
      end
    end
  end

  def test_class_eval
    test_module_eval(method: :class_eval)
  end

  def test_class_exec
    test_module_exec(method: :class_exec)
  end

  def test_alias_method
    mod = Module.new do
      def foo
      end
    end

    with_interned :bar do |new_name|
      with_interned :foo do |old_name|
        assert_send_type  '(interned, interned) -> Symbol',
                          mod, :alias_method, new_name, old_name
      end
    end
  end

  # Helper for `private`, `public`, and `protected`, as they all function identically
  def visibility_helper(visibility)
    mod = Module.new do
      def foo; end

      def bar; end
    end

    assert_visibility :private,
                      mod, visibility
    # No arguments
    assert_send_type  '() -> nil',
                      mod, visibility

    # Single argument
    assert_send_type  '(Symbol) -> Symbol',
                      mod, visibility, :foo

    with_string 'foo' do |foo|
      assert_send_type  '[T < _ToStr] (T) -> T',
                        mod, visibility, foo
    end

    with_interned 'foo' do |foo|
      assert_send_type  '(interned) -> interned',
                        mod, visibility, foo
    end

    # Multiple arguments
    assert_send_type  '(Symbol, *Symbol) -> Array[Symbol]',
                      mod, visibility, :foo, :bar

    with_string 'foo' do |foo|
      with_string 'bar' do |bar|
        assert_send_type  '[T < _ToStr] (T, *T) -> Array[T]',
                          mod, visibility, foo, bar
      end
    end

    with_interned 'foo' do |foo|
      with_interned 'bar' do |bar|
        assert_send_type  '(interned, *interned) -> Array[interned]',
                          mod, visibility, foo, bar
      end
    end

    # With the array version
    assert_send_type  '(Array[String]) -> Array[String]',
                      mod, visibility, [:foo]
    with_string 'foo' do |foo|
      assert_send_type  '[T < _ToStr] (Array[T]) -> Array[T]',
                        mod, visibility, [foo]
    end
    with_interned 'foo' do |foo|
      with_interned 'bar' do |bar|
        assert_send_type  '(Array[interned]) -> Array[interned]',
                          mod, visibility, [foo, bar]
      end
    end
  end


  def test_private
    visibility_helper(:private)
  end

  def test_protected
    visibility_helper(:protected)
  end

  def test_public
    visibility_helper(:public)
  end


  def test_private_class_method
    mod = Module.new do
      def self.foo; end
      def self.bar; end
    end

    assert_send_type  '() -> Module',
                      mod, :private_class_method

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Module',
                        mod, :private_class_method, foo
      assert_send_type  '(Array[interned]) -> Module',
                        mod, :private_class_method, [foo]
      with_interned :bar do |bar|
        assert_send_type  '(interned, *interned) -> Module',
                          mod, :private_class_method, foo, bar
        assert_send_type  '(Array[interned]) -> Module',
                          mod, :private_class_method, [foo, bar]
      end
    end
  end
  def test_public_class_method
    mod = Module.new do
      def self.foo; end
      def self.bar; end
    end

    assert_send_type  '() -> Module',
                      mod, :public_class_method

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Module',
                        mod, :public_class_method, foo
      assert_send_type  '(Array[interned]) -> Module',
                        mod, :public_class_method, [foo]
      with_interned :bar do |bar|
        assert_send_type  '(interned, *interned) -> Module',
                          mod, :public_class_method, foo, bar
        assert_send_type  '(Array[interned]) -> Module',
                          mod, :public_class_method, [foo, bar]
      end
    end
  end

  def test_attr
    mod = Module.new

    assert_send_type  '() -> Array[Symbol]',
                       mod, :attr

    with_interned :foo do |foo|
      with_bool do |writer|
        assert_send_type  '(interned, bool) -> Array[Symbol]',
                          mod, :attr, foo, writer
      end

      assert_send_type  '(interned) -> Array[Symbol]',
                        mod, :attr, foo

      with_interned :bar do |bar|
        assert_send_type  '(*interned) -> Array[Symbol]',
                          mod, :attr, foo, bar
      end
    end
  end

  def test_attr_reader
    mod = Module.new

    assert_send_type  '() -> Array[Symbol]',
                      mod, :attr_reader

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        mod, :attr_reader, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          mod, :attr_reader, foo, bar
      end
    end
  end

  def test_attr_writer
    mod = Module.new

    assert_send_type  '() -> Array[Symbol]',
                      mod, :attr_writer

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        mod, :attr_writer, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          mod, :attr_writer, foo, bar
      end
    end
  end

  def test_attr_accessor
    mod = Module.new

    assert_send_type  '() -> Array[Symbol]',
                      mod, :attr_accessor

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        mod, :attr_accessor, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          mod, :attr_accessor, foo, bar
      end
    end
  end

  def test_ruby2_keywords
    mod = Module.new do
      def a(*x) = 3
      def b(*x) = 3
    end

    assert_visibility :private,
                      mod, :ruby2_keywords

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> nil',
                        mod, :ruby2_keywords, foo
      with_interned :bar do |bar|
        assert_send_type  '(interned, *interned) -> nil',
                          mod, :ruby2_keywords, foo, bar
      end
    end
  end

  def test_set_temporary_name
    mod = Module.new

    assert_send_type '(nil) -> Module',
                     mod, :set_temporary_name, nil

    with_string "fake_name" do |name|
      assert_send_type '(string) -> Module',
                       mod, :set_temporary_name, name
    end
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
