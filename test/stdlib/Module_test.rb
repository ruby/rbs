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
  def classlevel_visibility_helper(visibility)
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
    classlevel_visibility_helper(:private)
  end

  def test_protected
    classlevel_visibility_helper(:protected)
  end

  def test_public
    classlevel_visibility_helper(:public)
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
    assert_send_type  '() -> Array[Symbol]',
                       Module.new, :attr

    with_interned :foo do |foo|
      with_bool do |writer|
        # attr with bool arguments yields a warning normally
        disable_verbose do
          assert_send_type  '(interned, bool) -> Array[Symbol]',
                            Module.new, :attr, foo, writer
        end
      end

      assert_send_type  '(interned) -> Array[Symbol]',
                        Module.new, :attr, foo

      with_interned :bar do |bar|
        assert_send_type  '(*interned) -> Array[Symbol]',
                          Module.new, :attr, foo, bar
      end
    end
  end

  def test_attr_reader
    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :attr_reader

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        Module.new, :attr_reader, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          Module.new, :attr_reader, foo, bar
      end
    end
  end

  def test_attr_writer
    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :attr_writer

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        Module.new, :attr_writer, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          Module.new, :attr_writer, foo, bar
      end
    end
  end

  def test_attr_accessor
    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :attr_accessor

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Array[Symbol]',
                        Module.new, :attr_accessor, foo

      with_interned :bar do |bar|
        assert_send_type  '(interned, interned) -> Array[Symbol]',
                          Module.new, :attr_accessor, foo, bar
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
    assert_send_type '(nil) -> Module',
                     Module.new, :set_temporary_name, nil

    with_string "fake_name" do |name|
      assert_send_type '(string) -> Module',
                       Module.new, :set_temporary_name, name
    end
  end

  def test_to_s(method: :to_s)
    assert_send_type  '() -> String',
                      Module.new, method
  end

  def test_inspect
    test_to_s(method: :inspect)
  end

  def test_ancestors
    assert_send_type  '() -> Array[Module]',
                      Module.new, :ancestors
    assert_send_type  '() -> Array[Module]',
                      Module, :ancestors
  end

  def test_autoload
    omit 'todo'
  end

  def test_autoload?
    omit 'todo'
  end

  def test_class_variable_defined?
    mod = Module.new

    with_interned :@@module_test_class_variable_defined do |cvar|
      assert_send_type "(interned) -> bool",
                       mod, :class_variable_defined?, cvar
    end

    mod.class_variable_set :@@module_test_class_variable_defined, 12
    with_interned :@@module_test_class_variable_defined do |cvar|
      assert_send_type "(interned) -> bool",
                       mod, :class_variable_defined?, cvar
    end
  end

  def test_class_variable_get
    mod = Module.new

    # If it's not set it raises an exception
    mod.class_variable_set :@@module_test_class_variable_get, 12

    with_interned :@@module_test_class_variable_get do |cvar|
      assert_send_type "(interned) -> untyped",
                       mod, :class_variable_get, cvar
    end
  end

  def test_class_variable_set
    mod = Module.new

    with_interned :@@module_test_class_variable_set do |cvar|
      with_untyped do |value|
        assert_send_type "[T] (interned, T) -> T",
                         mod, :class_variable_set, cvar, value
      end
    end
  end

  def test_class_variables
    mod = Module.new do
      include Module.new {
        class_variable_set :@@module_test_class_variables_1, 12
      }

      class_variable_set :@@module_test_class_variables_2, 34
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :class_variables
    assert_send_type  '() -> Array[Symbol]',
                      mod, :class_variables

    with_boolish do |inherit|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        Module.new, :class_variables, inherit
      assert_send_type  '(boolish) -> Array[Symbol]',
                        mod, :class_variables, inherit
    end
  end

  def test_const_defined?
    mod = Module.new

    # Before defining the constant
    with_interned :ModuleTestConstDefined do |name|
      assert_send_type '(interned) -> bool',
                       mod, :const_defined?, name

      with_boolish do |inherit|
        assert_send_type '(interned, boolish) -> bool',
                         mod, :const_defined?, name, inherit
      end
    end

    mod.const_set :ModuleTestConstDefined, 123

    # After defining the constant
    with_interned :ModuleTestConstDefined do |name|
      assert_send_type '(interned) -> bool',
                       mod, :const_defined?, name

      with_boolish do |inherit|
        assert_send_type '(interned, boolish) -> bool',
                         mod, :const_defined?, name, inherit
      end
    end
  end

  def test_const_get
    mod = Module.new

    # Define the constant first to avoid NameError paths
    mod.const_set :ModuleTestConstGet, 123

    with_interned :ModuleTestConstGet do |name|
      assert_send_type '(interned) -> untyped',
                       mod, :const_get, name

      with_boolish do |inherit|
        assert_send_type '(interned, boolish) -> untyped',
                         mod, :const_get, name, inherit
      end
    end
  end

  def test_const_missing
    omit 'todo'
  end

  def test_const_set
    with_interned :ModuleTestConstSet do |name|
      with_untyped do |value|
        assert_send_type '[T] (interned, T) -> T',
                         Module.new, :const_set, name, value
      end
    end
  end

  def test_define_method
    omit 'todo'
  end

  def constant_visibility_helper(method)
    mod = Module.new do
      const_set :Foo, 3
      const_set :Bar, 4
    end

    # No arguments yields a warning with `-w`
    disable_verbose do
      assert_send_type  '() -> Module',
                        mod, method
    end

    with_interned :Foo do |foo|
      assert_send_type  '(interned) -> Module',
                        mod, method, foo

      with_interned :Bar do |bar|
        assert_send_type  '(interned, *interned) -> Module',
                          mod, method, foo, bar
      end
    end
  end

  def test_deprecate_constant
    constant_visibility_helper(:deprecate_constant)
  end

  def test_freeze
    assert_send_type  '() -> Module',
                      Module.new, :freeze
  end

  def test_included_modules
    assert_send_type  '() -> Array[Module]',
                      Module.new, :included_modules
    assert_send_type  '() -> Array[Module]',
                      Module.new{ include Module.new }, :included_modules
  end

  def test_initialize
    omit 'todo'
  end

  def test_initialize_clone
    omit 'todo'
  end

  def test_instance_method
    mod = Module.new do
      def foo = 3
      private def bar = 4
    end

    with_interned :foo do |name|
      assert_send_type '(interned) -> UnboundMethod',
                       mod, :instance_method, name
    end

    with_interned :bar do |name|
      assert_send_type '(interned) -> UnboundMethod',
                       mod, :instance_method, name
    end
  end

  def test_instance_methods
    mod = Module.new do
      include Module.new {
        public def foo1 = 1
        private def foo2 = 1
        protected def foo3 = 1
      }
      public def bar1 = 1
      private def bar2 = 1
      protected def bar3 = 1
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :instance_methods
    assert_send_type  '() -> Array[Symbol]',
                      mod, :instance_methods

    with_boolish do |include_super|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        mod, :instance_methods, include_super
    end
  end

  def test_method_defined?
    mod = Module.new do
      include Module.new { def bar = 1 }
      def foo = 2
    end

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> bool',
                        mod, :method_defined?, foo
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :method_defined?, foo, inherit
      end
    end

    with_interned :bar do |bar|
      assert_send_type  '(interned) -> bool',
                        mod, :method_defined?, bar
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :method_defined?, bar, inherit
      end
    end

    with_interned :baz do |baz|
      assert_send_type  '(interned) -> bool',
                        mod, :method_defined?, baz
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :method_defined?, baz, inherit
      end
    end
  end

  def test_name
    assert_send_type  '() -> nil',
                      Module.new, :name

    assert_send_type  '() -> String',
                      Comparable, :name
  end

  def test_private_constant
    constant_visibility_helper(:private_constant)
  end

  def test_private_instance_methods
    mod = Module.new do
      include Module.new {
        private def bar = 4
      }

      private def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :private_instance_methods
    assert_send_type  '() -> Array[Symbol]',
                      mod, :private_instance_methods

    with_boolish do |include_super|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        mod, :private_instance_methods, include_super
    end
  end

  def test_private_method_defined?
    mod = Module.new do
      include Module.new { private def bar = 1 }
      private def foo = 2
      public def baz = 3
    end

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> bool',
                        mod, :private_method_defined?, foo
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :private_method_defined?, foo, inherit
      end
    end

    with_interned :bar do |bar|
      assert_send_type  '(interned) -> bool',
                        mod, :private_method_defined?, bar
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :private_method_defined?, bar, inherit
      end
    end

    with_interned :baz do |baz|
      assert_send_type  '(interned) -> bool',
                        mod, :private_method_defined?, baz
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :private_method_defined?, baz, inherit
      end
    end

    with_interned :quux do |quux|
      assert_send_type  '(interned) -> bool',
                        mod, :private_method_defined?, quux
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :private_method_defined?, quux, inherit
      end
    end
  end

  def test_protected_instance_methods
    mod = Module.new do
      include Module.new {
        protected def bar = 4
      }

      protected def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :protected_instance_methods
    assert_send_type  '() -> Array[Symbol]',
                      mod, :protected_instance_methods

    with_boolish do |include_super|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        mod, :protected_instance_methods, include_super
    end
  end

  def test_protected_method_defined?
    mod = Module.new do
      include Module.new { protected def bar = 1 }
      protected def foo = 2
      public def baz = 3
    end

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> bool',
                        mod, :protected_method_defined?, foo
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :protected_method_defined?, foo, inherit
      end
    end

    with_interned :bar do |bar|
      assert_send_type  '(interned) -> bool',
                        mod, :protected_method_defined?, bar
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :protected_method_defined?, bar, inherit
      end
    end

    with_interned :baz do |baz|
      assert_send_type  '(interned) -> bool',
                        mod, :protected_method_defined?, baz
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :protected_method_defined?, baz, inherit
      end
    end

    with_interned :quux do |quux|
      assert_send_type  '(interned) -> bool',
                        mod, :protected_method_defined?, quux
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :protected_method_defined?, quux, inherit
      end
    end
  end

  def test_public_constant
    constant_visibility_helper(:public_constant)
  end

  def test_public_instance_method
    mod = Module.new do
      def foo = 3
    end

    with_interned :foo do |name|
      assert_send_type '(interned) -> UnboundMethod',
                       mod, :instance_method, name
    end
  end

  def test_public_instance_methods
    mod = Module.new do
      include Module.new {
        def bar = 4
      }

      def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :public_instance_methods
    assert_send_type  '() -> Array[Symbol]',
                      mod, :public_instance_methods

    with_boolish do |include_super|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        mod, :public_instance_methods, include_super
    end
  end

  def test_public_method_defined?
    mod = Module.new do
      include Module.new { public def bar = 1 }
      public def foo = 2
      private def baz = 3
    end

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> bool',
                        mod, :public_method_defined?, foo
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :public_method_defined?, foo, inherit
      end
    end

    with_interned :bar do |bar|
      assert_send_type  '(interned) -> bool',
                        mod, :public_method_defined?, bar
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :public_method_defined?, bar, inherit
      end
    end

    with_interned :baz do |baz|
      assert_send_type  '(interned) -> bool',
                        mod, :public_method_defined?, baz
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :public_method_defined?, baz, inherit
      end
    end

    with_interned :quux do |quux|
      assert_send_type  '(interned) -> bool',
                        mod, :public_method_defined?, quux
      with_boolish do |inherit|
        assert_send_type  '(interned, boolish) -> bool',
                          mod, :public_method_defined?, quux, inherit
      end
    end
  end

  def test_remove_class_variable
    with_interned :@@module_test_remove_class_variable do |cvar|
      mod = Module.new do
        class_variable_set(:@@module_test_remove_class_variable, 123)
      end

      assert_send_type  '(interned) -> untyped',
                        mod, :remove_class_variable, cvar
    end
  end

  def test_remove_method
    assert_send_type  '() -> Module',
                      Module.new, :remove_method

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Module',
                        Module.new { def foo = 3 }, :remove_method, foo
      with_interned :bar do |bar|
        assert_send_type  '(*interned) -> Module',
                          Module.new { def foo = 3; def bar = 4 }, :remove_method, foo, bar
      end
    end
  end

  def test_singleton_class?
    assert_send_type  '() -> bool',
                      Module, :singleton_class?
    assert_send_type  '() -> bool',
                      Module.singleton_class, :singleton_class?
  end

  def test_undef_method
    assert_send_type  '() -> Module',
                      Module.new, :undef_method

    with_interned :foo do |foo|
      assert_send_type  '(interned) -> Module',
                        Module.new { def foo = 3 }, :undef_method, foo
      with_interned :bar do |bar|
        assert_send_type  '(*interned) -> Module',
                          Module.new { def foo = 3; def bar = 4 }, :undef_method, foo, bar
      end
    end
  end

  def test_undefined_instance_methods
    mod = Module.new do
      def foo = 4
      undef foo
    end

    assert_send_type  '() -> Array[Symbol]',
                      Module.new, :undefined_instance_methods
    assert_send_type  '() -> Array[Symbol]',
                      mod, :undefined_instance_methods
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
