require "test_helper"

class RBS::RuntimePrototypeTest < Test::Unit::TestCase
  Runtime = RBS::Prototype::Runtime
  DefinitionBuilder = RBS::DefinitionBuilder

  include TestHelper

  module TestTargets
    module Foo
      include Enumerable

      extend Comparable
    end

    module Bar
    end

    module Baz
    end

    class Test < String
      include Foo
      extend Bar
      prepend Baz

      NAME = "Hello"

      def foo(foo, bar=1, *baz, a, b:, c: nil, **d)
      end

      alias bar foo

      private

      def a()
      end

      def self.baz(&block)
      end

      def self.b()
      end
    end
  end

  def test_1
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestTargets::*"], env: env, merge: false)

        assert_write p.decls, <<-EOF
module RBS
  class RuntimePrototypeTest < ::Test::Unit::TestCase
    module TestTargets
      module Bar
      end

      module Baz
      end

      module Foo
        include Enumerable[untyped]

        extend Comparable
      end

      class Test < ::String
        prepend RBS::RuntimePrototypeTest::TestTargets::Baz

        include RBS::RuntimePrototypeTest::TestTargets::Foo

        extend RBS::RuntimePrototypeTest::TestTargets::Bar

        def self.b: () -> untyped

        def self.baz: () { (*untyped) -> untyped } -> untyped

        alias bar foo

        def foo: (untyped foo, ?untyped bar, *untyped baz, untyped a, b: untyped, ?c: untyped, **untyped) -> untyped

        private

        def a: () -> untyped

        NAME: ::String
      end
    end
  end
end
        EOF
      end
    end
  end

  def test_merge_types
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class RBS
  class RuntimePrototypeTest < ::Test::Unit::TestCase
    class TestTargets
      class Test
        def self.baz: () -> void

        def foo: (String) -> Integer
               | (String, bool) { () -> void } -> [Symbol]

        def bar: () -> void
      end
    end
  end
end
EOF

      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestTargets::*"], env: env, merge: true)

        assert_write p.decls, <<-EOF
module RBS
  class RuntimePrototypeTest < ::Test::Unit::TestCase
    module TestTargets
      module Bar
      end

      module Baz
      end

      module Foo
        include Enumerable[untyped]

        extend Comparable
      end

      class Test < ::String
        prepend RBS::RuntimePrototypeTest::TestTargets::Baz

        include RBS::RuntimePrototypeTest::TestTargets::Foo

        extend RBS::RuntimePrototypeTest::TestTargets::Bar

        def self.b: () -> untyped

        def self.baz: () { (*untyped) -> untyped } -> untyped

        alias bar foo

        def foo: (untyped foo, ?untyped bar, *untyped baz, untyped a, b: untyped, ?c: untyped, **untyped) -> untyped

        private

        def a: () -> untyped

        NAME: ::String
      end
    end
  end
end
        EOF
      end
    end
  end

  module IncludeTests
    class SuperClass
      def foo; end
      def self.foo; end
    end

    class ChildClass < SuperClass
      def bar; end
    end
  end

  def test_include_owner
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::IncludeTests::*"],
                        env: env,
                        merge: true,
                        owners_included: ["RBS::RuntimePrototypeTest::IncludeTests::SuperClass"])

        assert_write p.decls, <<-EOF
module RBS
  class RuntimePrototypeTest < ::Test::Unit::TestCase
    module IncludeTests
      class ChildClass < ::RBS::RuntimePrototypeTest::IncludeTests::SuperClass
        def self.foo: () -> untyped

        def bar: () -> untyped

        def foo: () -> untyped
      end

      class SuperClass
        def self.foo: () -> untyped

        def foo: () -> untyped
      end
    end
  end
end
        EOF
      end
    end
  end

  module TestForAnonymous
    class C < Class.new
    end

    class C2
      include Module.new
    end

    module M
      CONST = Class.new.new
    end

    module M2
      include Module.new
    end

    module M3
      def self.name
        raise
      end
    end
  end

  def test_decls_for_anonymous_class_or_module
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForAnonymous::*"],
                        env: env, merge: false)
        silence_warnings do
          p.decls
        end
        assert(true) # nothing raised above
      end
    end
  end

  module TestForOverrideModuleName
    module M
      def self.name() 'FakeNameM' end
      def self.to_s() 'FakeToS' end
      X = 1
    end

    class C
      def self.name() 'FakeNameC' end
      def self.to_s() 'FakeToS2' end
      include M

      INSTANCE = C.new
    end


    class C2 < C
    end
  end

  def test_for_overwritten_module_name
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForOverrideModuleName::*"], env: env, merge: true)

        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              module TestForOverrideModuleName
                class C
                  include RBS::RuntimePrototypeTest::TestForOverrideModuleName::M

                  def self.name: () -> untyped

                  def self.to_s: () -> untyped

                  INSTANCE: ::RBS::RuntimePrototypeTest::TestForOverrideModuleName::C
                end

                class C2 < ::RBS::RuntimePrototypeTest::TestForOverrideModuleName::C
                end

                module M
                  def self.name: () -> untyped

                  def self.to_s: () -> untyped

                  X: ::Integer
                end
              end
            end
          end
        RBS
      end
    end
  end

  module TestForTypeParameters
    module M
      HASH = { foo: 42 }
    end

    class C < Hash
    end

    class C2
      include Enumerable
    end
  end

  def test_for_type_parameters
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForTypeParameters::*"], env: env, merge: true)

        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              module TestForTypeParameters
                class C < ::Hash[untyped, untyped]
                end

                class C2
                  include Enumerable[untyped]
                end

                module M
                  HASH: ::Hash[untyped, untyped]
                end
              end
            end
          end
        RBS
      end
    end
  end

  class TestForInitialize
    def initialize() 'foo' end
  end

  def test_for_initialize_type
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForInitialize"], env: env, merge: true)

        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class TestForInitialize
                private

                def initialize: () -> void
              end
            end
          end
        RBS
      end
    end
  end

  class TestForYield
    def m1() yield end
    def m2() yield 42 end
    def m3() yield 42; yield 42, 43 end
    eval 'def m4() yield end'
  end

  def test_for_yield
    omit "Ruby 3.4 uses Prism and needs migration" if RUBY_VERSION >= "3.4"

    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForYield"], env: env, merge: true)

        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class TestForYield
                def m1: () { () -> untyped } -> untyped

                def m2: () { (untyped) -> untyped } -> untyped

                def m3: () { (untyped, untyped) -> untyped } -> untyped

                def m4: () -> untyped
              end
            end
          end
        RBS
      end
    end
  end

  module TestForEnv
    # A = 1
    def a
      2
    end
    alias b a
    module B
    end
    include B
    extend B
    prepend B
  end

  def test_decls_structure
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestForEnv"], env: env, merge: true)
        assert_equal(p.decls.length, 1)
        p.decls.each do |decl|
          env.insert_rbs_decl(decl, context: nil, namespace: RBS::Namespace.root)
        end
        env.resolve_type_names
        assert(true) # nothing raised above
      end
    end
  end

  def test_basic_object
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["BasicObject"], env: env, merge: true)
        assert_equal(p.decls.length, 1)
        p.decls.each do |decl|
          env.insert_rbs_decl(decl, context: nil, namespace: RBS::Namespace.root)
        end
        env.resolve_type_names
        assert(true) # nothing raised above
      end
    end
  end

  def test_nameerror_message
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["NameError*"], env: env, merge: true)

        writer = RBS::Writer.new(out: StringIO.new)
        writer.write(p.decls)
        RBS::Parser.parse_signature(writer.out.string) # check syntax

        assert !writer.out.string.include?("class message")
      end
    end
  end

  class TestTypeParams
    class TestTypeParams
    end
  end

  def test_type_params
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~RBS
        module RBS
          class RuntimePrototypeTest < ::Test::Unit::TestCase
            class TestTypeParams[unchecked out Elem]
              class TestTypeParams
              end
            end
          end
        end
      RBS

      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestTypeParams"], env: env, merge: true)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class TestTypeParams[unchecked out Elem]
              end
            end
          end
        RBS

        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TestTypeParams::TestTypeParams"], env: env, merge: true)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class TestTypeParams[unchecked out Elem]
                class TestTypeParams
                end
              end
            end
          end
        RBS
      end
    end
  end

  class Constants
    module Name
      class Space
      end
    end
    A = ARGF
    B = ENV
    C = BasicObject.new
    D = Name::Space.new
    E = Class.new # skip
    F = Module.new # skip
  end

  def test_constants
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::Constants"], env: env, merge: false)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class Constants
                A: ::RBS::Unnamed::ARGFClass

                B: ::RBS::Unnamed::ENVClass

                C: ::BasicObject

                D: ::RBS::RuntimePrototypeTest::Constants::Name::Space
              end
            end
          end
        RBS
      end
    end
  end

  module AliasTargetModule
    def foo; end
  end

  class DefineMethodAlias
    define_singleton_method(:qux, AliasTargetModule.instance_method(:foo))

    define_method(:bar, AliasTargetModule.instance_method(:foo))

    define_method(:baz, AliasTargetModule.instance_method(:foo))
    private :baz
  end

  def test_define_method_alias
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::DefineMethodAlias"], env: env, merge: true)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class DefineMethodAlias
                def self.qux: () -> untyped

                def bar: () -> untyped

                private

                def baz: () -> untyped
              end
            end
          end
        RBS
      end
    end
  end

  class TodoClass
    module MixinDefined
    end
    include MixinDefined
    module MixinTodo
    end
    extend MixinTodo

    def public_defined; end
    def public_todo; end
    private def private_defined; end
    private def private_todo; end
    def self.singleton_defined; end
    def self.singleton_todo; end
    private def accessibility_mismatch; end

    CONST_DEFINED = 1
    CONST_TODO = 1
  end

  module TodoModule
    def public_defined; end
    def public_todo; end
  end

  def test_todo
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<~RBS
        module RBS
          class RuntimePrototypeTest < ::Test::Unit::TestCase
            class TodoClass
              module MixinDefined
              end
              include MixinDefined
              def public_defined: () -> void
              private def private_defined: () -> void
              def self.singleton_defined: () -> void
              def accessibility_mismatch: () -> void
              CONST_DEFINED: Integer
            end
            module TodoModule
              def public_defined: () -> void
            end
          end
        end
      RBS

      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TodoClass"], env: env, merge: false, todo: true)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class TodoClass
                extend RBS::RuntimePrototypeTest::TodoClass::MixinTodo

                def self.singleton_todo: () -> untyped

                def public_todo: () -> untyped

                private

                def accessibility_mismatch: () -> untyped

                def private_todo: () -> untyped

                CONST_TODO: ::Integer
              end
            end
          end
        RBS

        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::TodoModule"], env: env, merge: false, todo: true)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              module TodoModule
                def public_todo: () -> untyped
              end
            end
          end
        RBS
      end
    end
  end

  class StructInheritWithNil < Struct.new(:foo, :bar, :baz?, keyword_init: nil)
  end
  StructKeywordInitTrue = Struct.new(:foo, :bar, keyword_init: true)
  StructKeywordInitFalse = Struct.new(:foo, :bar, keyword_init: false)
  class StructDirectInherited < Struct
  end

  def test_struct
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::StructInheritWithNil"], env: env, merge: false)
        if Runtime::StructGenerator::CAN_CALL_KEYWORD_INIT_P
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructInheritWithNil < ::Struct[untyped]
                  def self.new: (?untyped foo, ?untyped bar, ?untyped `baz?`) -> instance
                              | (?foo: untyped, ?bar: untyped, ?baz?: untyped) -> instance

                  def self.[]: (?untyped foo, ?untyped bar, ?untyped `baz?`) -> instance
                             | (?foo: untyped, ?bar: untyped, ?baz?: untyped) -> instance

                  def self.keyword_init?: () -> nil

                  def self.members: () -> [ :foo, :bar, :baz? ]

                  def members: () -> [ :foo, :bar, :baz? ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped

                  attr_accessor baz?: untyped
                end
              end
            end
          RBS
        else
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructInheritWithNil < ::Struct[untyped]
                  def self.new: (?untyped foo, ?untyped bar, ?untyped `baz?`) -> instance
                              | (?foo: untyped, ?bar: untyped, ?baz?: untyped) -> instance

                  def self.[]: (?untyped foo, ?untyped bar, ?untyped `baz?`) -> instance
                             | (?foo: untyped, ?bar: untyped, ?baz?: untyped) -> instance

                  def self.members: () -> [ :foo, :bar, :baz? ]

                  def members: () -> [ :foo, :bar, :baz? ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped

                  attr_accessor baz?: untyped
                end
              end
            end
          RBS
        end

        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::StructKeywordInitTrue"], env: env, merge: false)
        if Runtime::StructGenerator::CAN_CALL_KEYWORD_INIT_P
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructKeywordInitTrue < ::Struct[untyped]
                  def self.new: (?foo: untyped, ?bar: untyped) -> instance

                  def self.[]: (?foo: untyped, ?bar: untyped) -> instance

                  def self.keyword_init?: () -> true

                  def self.members: () -> [ :foo, :bar ]

                  def members: () -> [ :foo, :bar ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped
                end
              end
            end
          RBS
        else
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructKeywordInitTrue < ::Struct[untyped]
                  def self.new: (?untyped foo, ?untyped bar) -> instance
                              | (?foo: untyped, ?bar: untyped) -> instance

                  def self.[]: (?untyped foo, ?untyped bar) -> instance
                             | (?foo: untyped, ?bar: untyped) -> instance

                  def self.members: () -> [ :foo, :bar ]

                  def members: () -> [ :foo, :bar ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped
                end
              end
            end
          RBS
        end

        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::StructKeywordInitFalse"], env: env, merge: false)
        if Runtime::StructGenerator::CAN_CALL_KEYWORD_INIT_P
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructKeywordInitFalse < ::Struct[untyped]
                  def self.new: (?untyped foo, ?untyped bar) -> instance

                  def self.[]: (?untyped foo, ?untyped bar) -> instance

                  def self.keyword_init?: () -> false

                  def self.members: () -> [ :foo, :bar ]

                  def members: () -> [ :foo, :bar ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped
                end
              end
            end
          RBS
        else
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class StructKeywordInitFalse < ::Struct[untyped]
                  def self.new: (?untyped foo, ?untyped bar) -> instance
                              | (?foo: untyped, ?bar: untyped) -> instance

                  def self.[]: (?untyped foo, ?untyped bar) -> instance
                             | (?foo: untyped, ?bar: untyped) -> instance

                  def self.members: () -> [ :foo, :bar ]

                  def members: () -> [ :foo, :bar ]

                  attr_accessor foo: untyped

                  attr_accessor bar: untyped
                end
              end
            end
          RBS
        end

        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::StructDirectInherited"], env: env, merge: false)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class StructDirectInherited < ::Struct[untyped]
              end
            end
          end
        RBS
      end
    end
  end

  if RUBY_VERSION >= '3.2'
    class DataInherit < Data.define(:foo, :bar, :baz?)
    end
    DataConst = Data.define(:foo, :bar)
    class DataDirectInherit < Data
    end

    def test_data
      SignatureManager.new do |manager|
        manager.build do |env|
          p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::DataInherit"], env: env, merge: false)
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class DataInherit < ::Data
                  def self.new: (untyped foo, untyped bar, untyped `baz?`) -> instance
                              | (foo: untyped, bar: untyped, baz?: untyped) -> instance

                  def self.[]: (untyped foo, untyped bar, untyped `baz?`) -> instance
                             | (foo: untyped, bar: untyped, baz?: untyped) -> instance

                  def self.members: () -> [ :foo, :bar, :baz? ]

                  def members: () -> [ :foo, :bar, :baz? ]

                  attr_reader foo: untyped

                  attr_reader bar: untyped

                  attr_reader baz?: untyped
                end
              end
            end
          RBS

          p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::DataConst"], env: env, merge: false)
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class DataConst < ::Data
                  def self.new: (untyped foo, untyped bar) -> instance
                              | (foo: untyped, bar: untyped) -> instance

                  def self.[]: (untyped foo, untyped bar) -> instance
                             | (foo: untyped, bar: untyped) -> instance

                  def self.members: () -> [ :foo, :bar ]

                  def members: () -> [ :foo, :bar ]

                  attr_reader foo: untyped

                  attr_reader bar: untyped
                end
              end
            end
          RBS

          p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::DataDirectInherit"], env: env, merge: false)
          assert_write p.decls, <<~RBS
            module RBS
              class RuntimePrototypeTest < ::Test::Unit::TestCase
                class DataDirectInherit < ::Data
                end
              end
            end
          RBS
        end
      end
    end
  end

  class Redefined
    def self.constants = raise
    def class = raise
  end

  def test_reflection
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["RBS::RuntimePrototypeTest::Redefined"], env: env, merge: false)
        assert_write p.decls, <<~RBS
          module RBS
            class RuntimePrototypeTest < ::Test::Unit::TestCase
              class Redefined
                def self.constants: () -> untyped

                def class: () -> untyped
              end
            end
          end
        RBS
      end
    end
  end
end
