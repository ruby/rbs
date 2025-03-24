require "test_helper"

class RBS::SignatureParsingTest < Test::Unit::TestCase
  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  AST = RBS::AST
  Declarations = RBS::AST::Declarations
  Members = RBS::AST::Members
  MethodType = RBS::MethodType
  Location = RBS::Location

  include TestHelper

  def test_type_alias
    Parser.parse_signature("type Steep::foo = untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      type_decl = decls[0]

      assert_instance_of Declarations::TypeAlias, type_decl
      assert_equal TypeName.new(name: :foo, namespace: Namespace.parse("Steep")), type_decl.name
      assert_equal [], type_decl.type_params.each.map(&:name)
      assert_equal Types::Bases::Any.new(location: nil), type_decl.type
      assert_equal "type Steep::foo = untyped", type_decl.location.source
    end

    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~RBS)
        type Foo = untyped
      RBS
    end
  end

  def test_type_alias_generic
    Parser.parse_signature(<<RBS).yield_self do |_, _, decls|
type optional[A] = A?
RBS
      assert_equal 1, decls.size

      type_decl = decls[0]

      assert_instance_of Declarations::TypeAlias, type_decl
      assert_equal RBS::TypeName.parse("optional"), type_decl.name
      assert_equal [:A], type_decl.type_params.each.map(&:name)
      assert_equal parse_type("A?", variables: [:A]), type_decl.type
      assert_equal "[A]", type_decl.location[:type_params].source
    end

    Parser.parse_signature(<<RBS).tap do |_, _, decls|
class Foo[A]
  type bar = B
end
RBS
      decls[0].members[0].tap do |type_decl|
        assert_instance_of Declarations::TypeAlias, type_decl
        assert_equal RBS::TypeName.parse("bar"), type_decl.name
        assert_equal [], type_decl.type_params.each.map(&:name)
        assert_instance_of Types::ClassInstance, type_decl.type
        assert_nil type_decl.location[:type_params]
      end
    end
  end

  def test_type_alias_generic_variance
    Parser.parse_signature(<<RBS).yield_self do |_, _, decls|
type x[T] = ^(T) -> void

type y[unchecked out T] = ^(T) -> void
RBS
      assert_equal 2, decls.size

      decls[0].tap do |type_decl|
        assert_instance_of Declarations::TypeAlias, type_decl

        type_decl.type_params[0].tap do |param|
          assert_equal :T, param.name
          assert_equal :invariant, param.variance
          refute_predicate param, :unchecked?
        end
      end

      decls[1].tap do |type_decl|
        assert_instance_of Declarations::TypeAlias, type_decl

        type_decl.type_params[0].tap do |param|
          assert_equal :T, param.name
          assert_equal :covariant, param.variance
          assert_predicate param, :unchecked?
        end
      end
    end
  end

  def test_constant
    Parser.parse_signature("FOO: untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :FOO, namespace: Namespace.empty), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "FOO: untyped", const_decl.location.source
    end

    Parser.parse_signature("::BAR: untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :BAR, namespace: Namespace.root), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "::BAR: untyped", const_decl.location.source
    end

    Parser.parse_signature("FOO : untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :FOO, namespace: Namespace.empty), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "FOO : untyped", const_decl.location.source
    end

    Parser.parse_signature("::BAR : untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :BAR, namespace: Namespace.root), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "::BAR : untyped", const_decl.location.source
    end
  end

  def test_global
    Parser.parse_signature("$FOO: untyped").tap do |_, _, decls|
      assert_equal 1, decls.size

      global_decl = decls[0]

      assert_instance_of Declarations::Global, global_decl
      assert_equal :"$FOO", global_decl.name
      assert_equal Types::Bases::Any.new(location: nil), global_decl.type
      assert_equal "$FOO: untyped", global_decl.location.source
    end
  end

  def test_interface
    Parser.parse_signature("interface _Each[A, B] end").tap do |_, _, decls|
      assert_equal 1, decls.size

      interface_decl = decls[0]

      assert_instance_of Declarations::Interface, interface_decl
      assert_equal TypeName.new(name: :_Each, namespace: Namespace.empty), interface_decl.name
      assert_equal [:A, :B], interface_decl.type_params.each.map(&:name)
      assert_equal [], interface_decl.members
      assert_equal "interface _Each[A, B] end", interface_decl.location.source
    end

    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      interface _Each[A, B]
        #
        # Yield all elements included in `self`.
        #
        def count: -> Integer
                 | (untyped) -> Integer
                 | [X] { (A) -> X } -> Integer

        include _Hash[Integer]
      end
      SIG

      assert_equal 1, decls.size

      interface_decl = decls[0]

      assert_instance_of Declarations::Interface, interface_decl
      assert_equal TypeName.new(name: :_Each, namespace: Namespace.empty), interface_decl.name
      assert_equal [:A, :B], interface_decl.type_params.each.map(&:name)

      assert_equal 2, interface_decl.members.size
      interface_decl.members[0].yield_self do |def_member|
        assert_instance_of Members::MethodDefinition, def_member
        assert_equal :count, def_member.name
        assert_equal 3, def_member.overloads.size

        def_member.overloads.yield_self do |o1, o2, o3|
          assert_empty o1.annotations
          assert_empty o1.method_type.type_params
          assert_nil o1.method_type.block
          assert_equal "-> Integer", o1.method_type.location.source

          assert_empty o2.method_type.type_params
          assert_equal 1, o2.method_type.type.required_positionals.size
          assert_nil o2.method_type.block
          assert_equal "(untyped) -> Integer", o2.method_type.location.source

          assert_equal(
            [AST::TypeParam.new(name: :X, variance: :invariant, upper_bound: nil, location: nil)],
            o3.method_type.type_params
          )
          assert_instance_of Types::Block, o3.method_type.block
          assert_instance_of Types::Variable, o3.method_type.block.type.required_positionals[0].type
          assert_instance_of Types::Variable, o3.method_type.block.type.return_type
          assert_equal "[X] { (A) -> X } -> Integer", o3.method_type.location.source
        end
      end

      interface_decl.members[1].yield_self do |include_member|
        assert_instance_of Members::Include, include_member
        assert_equal TypeName.new(name: :_Hash, namespace: Namespace.empty), include_member.name
        assert_equal [parse_type("Integer")], include_member.args
      end
    end

    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
        interface _Each[A, B]
          def self.foo: -> void
        end
      SIG
    end

    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
        interface _Each[A, B]
          include Object
        end
      SIG
    end
  end

  def test_module
    Parser.parse_signature("module Enumerable[A, B] end").tap do |_, _, decls|
      assert_equal 1, decls.size

      module_decl = decls[0]

      assert_instance_of Declarations::Module, module_decl
      assert_equal TypeName.new(name: :Enumerable, namespace: Namespace.empty), module_decl.name
      assert_equal [:A, :B], module_decl.type_params.each.map(&:name)
      assert_equal [], module_decl.self_types
      assert_equal [], module_decl.members
      assert_equal "module Enumerable[A, B] end", module_decl.location.source
    end

    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      module Enumerable[A, B] : _Each
        @foo: String
        self.@bar: Integer
        @@baz: Array[Integer]

        def one: -> void
        def self.two: -> untyped
        def self?.three: -> bool

        include X
        include _X

        extend Y
        extend _Y

        attr_reader a: Integer
        attr_reader a(@A): String
        attr_reader a(): bool

        attr_writer b: Integer
        attr_writer b(@B): String
        attr_writer b(): bool

        attr_accessor c: Integer
        attr_accessor c(@C): String
        attr_accessor c(): bool
      end
      SIG

      assert_equal 1, decls.size

      module_decl = decls[0]

      assert_instance_of Declarations::Module, module_decl

      assert_equal 19, module_decl.members.size

      module_decl.members[0].yield_self do |m|
        assert_instance_of Members::InstanceVariable, m
        assert_equal :@foo, m.name
        assert_equal parse_type("String"), m.type
      end

      module_decl.members[1].yield_self do |m|
        assert_instance_of Members::ClassInstanceVariable, m
        assert_equal :@bar, m.name
        assert_equal parse_type("Integer"), m.type
      end

      module_decl.members[2].yield_self do |m|
        assert_instance_of Members::ClassVariable, m
        assert_equal :@@baz, m.name
        assert_equal parse_type("Array[Integer]"), m.type
      end

      module_decl.members[3].yield_self do |m|
        assert_instance_of Members::MethodDefinition, m
        assert_equal :instance, m.kind
        assert_equal "def one: -> void", m.location.source
      end

      module_decl.members[4].yield_self do |m|
        assert_instance_of Members::MethodDefinition, m
        assert_equal :singleton, m.kind
        assert_equal "def self.two: -> untyped", m.location.source
      end

      module_decl.members[5].yield_self do |m|
        assert_instance_of Members::MethodDefinition, m
        assert_equal :singleton_instance, m.kind
        assert_equal "def self?.three: -> bool", m.location.source
      end

      module_decl.members[6].yield_self do |m|
        assert_instance_of Members::Include, m
        assert_equal TypeName.new(name: :X, namespace: Namespace.empty), m.name
        assert_equal [], m.args
        assert_equal "include X", m.location.source
      end

      module_decl.members[7].yield_self do |m|
        assert_instance_of Members::Include, m
        assert_equal TypeName.new(name: :_X, namespace: Namespace.empty), m.name
        assert_equal [], m.args
        assert_equal "include _X", m.location.source
      end

      module_decl.members[8].yield_self do |m|
        assert_equal "extend Y", m.location.source
        assert_instance_of Members::Extend, m
        assert_equal TypeName.new(name: :Y, namespace: Namespace.empty), m.name
        assert_equal [], m.args
      end

      module_decl.members[9].yield_self do |m|
        assert_equal "extend _Y", m.location.source
        assert_instance_of Members::Extend, m
        assert_equal TypeName.new(name: :_Y, namespace: Namespace.empty), m.name
        assert_equal [], m.args
      end

      module_decl.members[10].yield_self do |m|
        assert_equal "attr_reader a: Integer", m.location.source
        assert_instance_of Members::AttrReader, m
        assert_equal :a, m.name
        assert_nil m.ivar_name
        assert_equal parse_type("Integer"), m.type
      end

      module_decl.members[11].yield_self do |m|
        assert_equal "attr_reader a(@A): String", m.location.source
        assert_instance_of Members::AttrReader, m
        assert_equal :a, m.name
        assert_equal :@A, m.ivar_name
        assert_equal parse_type("String"), m.type
      end

      module_decl.members[12].yield_self do |m|
        assert_equal "attr_reader a(): bool", m.location.source
        assert_instance_of Members::AttrReader, m
        assert_equal :a, m.name
        assert_equal false, m.ivar_name
        assert_equal parse_type("bool"), m.type
      end

      module_decl.members[13].yield_self do |m|
        assert_equal "attr_writer b: Integer", m.location.source
        assert_instance_of Members::AttrWriter, m
        assert_equal :b, m.name
        assert_nil m.ivar_name
        assert_equal parse_type("Integer"), m.type
      end

      module_decl.members[14].yield_self do |m|
        assert_equal "attr_writer b(@B): String", m.location.source
        assert_instance_of Members::AttrWriter, m
        assert_equal :b, m.name
        assert_equal :@B, m.ivar_name
        assert_equal parse_type("String"), m.type
      end

      module_decl.members[15].yield_self do |m|
        assert_equal "attr_writer b(): bool", m.location.source
        assert_instance_of Members::AttrWriter, m
        assert_equal :b, m.name
        assert_equal false, m.ivar_name
        assert_equal parse_type("bool"), m.type
      end

      module_decl.members[16].yield_self do |m|
        assert_equal "attr_accessor c: Integer", m.location.source
        assert_instance_of Members::AttrAccessor, m
        assert_equal :c, m.name
        assert_nil m.ivar_name
        assert_equal parse_type("Integer"), m.type
      end

      module_decl.members[17].yield_self do |m|
        assert_equal "attr_accessor c(@C): String", m.location.source
        assert_instance_of Members::AttrAccessor, m
        assert_equal :c, m.name
        assert_equal :@C, m.ivar_name
        assert_equal parse_type("String"), m.type
      end

      module_decl.members[18].yield_self do |m|
        assert_equal "attr_accessor c(): bool", m.location.source
        assert_instance_of Members::AttrAccessor, m
        assert_equal :c, m.name
        assert_equal false, m.ivar_name
        assert_equal parse_type("bool"), m.type
      end
    end
  end

  def test_module_selfs
    Parser.parse_signature(<<-RBS).tap do |_, _, decls|
module Enumerable[A, B] : _Each, Object
end
    RBS
      assert_equal 1, decls.size

      module_decl = decls[0]

      assert_instance_of Declarations::Module, module_decl
      assert_equal TypeName.new(name: :Enumerable, namespace: Namespace.empty), module_decl.name
      assert_equal [:A, :B], module_decl.type_params.each.map(&:name)
      assert_equal [
                     Declarations::Module::Self.new(name: type_name("_Each"), args: [], location: nil),
                     Declarations::Module::Self.new(name: type_name("Object"), args: [], location: nil)
                   ], module_decl.self_types
      assert_equal [], module_decl.members
      assert_equal "module Enumerable[A, B] : _Each, Object\nend", module_decl.location.source
    end
  end

  def test_class
    Parser.parse_signature("class Array[A] end").tap do |_, _, decls|
      assert_equal 1, decls.size

      decls[0].yield_self do |class_decl|
        assert_instance_of Declarations::Class, class_decl
        assert_equal TypeName.new(name: :Array, namespace: Namespace.empty), class_decl.name
        assert_equal [:A], class_decl.type_params.each.map(&:name)
        assert_nil class_decl.super_class
      end
    end

    Parser.parse_signature("class ::Array[A] < Object[A] end").tap do |_, _, decls|
      assert_equal 1, decls.size

      decls[0].yield_self do |class_decl|
        assert_instance_of Declarations::Class, class_decl
        assert_equal TypeName.new(name: :Array, namespace: Namespace.root), class_decl.name
        assert_equal [:A], class_decl.type_params.each.map(&:name)

        assert_instance_of Declarations::Class::Super, class_decl.super_class
        assert_equal TypeName.new(name: :Object, namespace: Namespace.empty), class_decl.super_class.name
        assert_equal [parse_type("A", variables: [:A])], class_decl.super_class.args
      end
    end
  end

  def test_method_definition
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo[X, Y]
        def foo: -> Integer
               | ?{ -> void } -> Integer
               | [A] () { (String, ?Object, *Float, Symbol, foo: bool, ?bar: untyped, **Y) -> X } -> A
      end
    SIG
      assert_equal 1, decls.size

      decls[0].yield_self do |decl|
        assert_instance_of Declarations::Class, decl

        assert_instance_of Members::MethodDefinition, decl.members[0]
        decl.members[0].yield_self do |m|
          assert_equal 3, m.overloads.size

          m.overloads[0].method_type.yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "-> Integer", ty.location.source
            assert_nil ty.block
          end

          m.overloads[1].method_type.yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "?{ -> void } -> Integer", ty.location.source
            assert_instance_of Types::Block, ty.block
            refute ty.block.required
          end

          m.overloads[2].method_type.yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "[A] () { (String, ?Object, *Float, Symbol, foo: bool, ?bar: untyped, **Y) -> X } -> A", ty.location.source
            assert_instance_of Types::Block, ty.block
            assert ty.block.required
          end
        end
      end
    end
  end

  def test_method_super
    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
      class Foo
        def foo: -> void
               | super
      end
      SIG
    end
  end

  def test_private_public
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo
        public
        private
      end
    SIG

      decls[0].yield_self do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal 2, decl.members.size

        decl.members[0].yield_self do |m|
          assert_instance_of Members::Public, m
        end

        decl.members[1].yield_self do |m|
          assert_instance_of Members::Private, m
        end
      end
    end
  end

  def test_private_public_def
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo
        public def foo: () -> void
        private def bar: () -> void
        def baz: () -> void
      end
    SIG

      decls[0].tap do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal 3, decl.members.size

        decl.members[0].tap do |m|
          assert_instance_of Members::MethodDefinition, m
          assert_equal :foo, m.name
          assert_equal :public, m.visibility
        end

        decl.members[1].tap do |m|
          assert_instance_of Members::MethodDefinition, m
          assert_equal :bar, m.name
          assert_equal :private, m.visibility
        end

        decl.members[2].tap do |m|
          assert_instance_of Members::MethodDefinition, m
          assert_equal :baz, m.name
          assert_nil m.visibility
        end
      end
    end
  end

  def test_private_public_def_error
    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
      class Foo
        public def self?.foo: () -> void
      end
    SIG
    end
  end

  def test_private_public_attr
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo
        public attr_reader foo: String
        private attr_reader bar: String
        attr_reader baz: String
      end
    SIG

      decls[0].tap do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal 3, decl.members.size

        decl.members[0].tap do |m|
          assert_instance_of Members::AttrReader, m
          assert_equal :foo, m.name
          assert_equal :public, m.visibility
        end

        decl.members[1].tap do |m|
          assert_instance_of Members::AttrReader, m
          assert_equal :bar, m.name
          assert_equal :private, m.visibility
        end

        decl.members[2].tap do |m|
          assert_instance_of Members::AttrReader, m
          assert_equal :baz, m.name
          assert_nil m.visibility
        end
      end
    end
  end

  def test_private_public_modifier_error
    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
      class Foo
        public alias foo bar
      end
    SIG
    end
  end

  def test_private_public_modifier
    Parser.parse_signature(<<~SIG)
      class Foo
        public

        private

        public    # comment can follow
      end
    SIG
  end

  def test_alias
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo
        def foo: -> String
        alias bar foo
        alias self.bar self.foo
      end
    SIG

      decls[0].yield_self do |decl|
        assert_equal 3, decl.members.size

        decl.members[1].yield_self do |m|
          assert_instance_of Members::Alias, m
          assert_equal :bar, m.new_name
          assert_equal :foo, m.old_name
          assert_equal :instance, m.kind
          assert_equal "alias bar foo", m.location.source
        end

        decl.members[2].yield_self do |m|
          assert_instance_of Members::Alias, m
          assert_equal :bar, m.new_name
          assert_equal :foo, m.old_name
          assert_equal :singleton, m.kind
          assert_equal "alias self.bar self.foo", m.location.source
        end
      end
    end
  end

  def test_method_names
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      interface _Foo
        def class: -> String
        def void: -> String
        def nil?: -> String
        def true: -> untyped
        def false: -> untyped
        def any: -> String
        def top: -> String
        def bot: -> String
        def `instance`: -> String
        def `self?`: -> String
        def bool: -> String
        def singleton: -> String
        def type: -> String
        def module: -> String
        def private: -> String
        def public: -> untyped
        def interface: -> untyped
        def super: -> untyped
        def alias: -> untyped
        def in: -> untyped
        def out: -> untyped
        def &: (untyped) -> untyped
        def ^: (untyped) -> untyped
        def *: (untyped) -> untyped
        def ==: (untyped) -> untyped
        def <: (untyped) -> untyped
        def <=: (untyped) -> untyped
        def >: (untyped) -> untyped
        def >=: (untyped) -> untyped
        def end: -> untyped
        def include: -> untyped
        def extend: -> untyped
        def attr_reader: -> untyped
        def attr_accessor: -> untyped
        def attr_writer: -> untyped
        def `: -> untyped
        def def!: -> untyped
        def !: -> untyped
        def _foo?: -> untyped
        def _foo!: -> untyped
      end
    SIG
      expected_names = [
        :class,
        :void,
        :nil?,
        :true,
        :false,
        :any,
        :top,
        :bot,
        :instance,
        :self?,
        :bool,
        :singleton,
        :type,
        :module,
        :private,
        :public,
        :interface,
        :super,
        :alias,
        :in,
        :out,
        :&,
        :^,
        :*,
        :==,
        :<,
        :<=,
        :>,
        :>=,
        :end,
        :include,
        :extend,
        :attr_reader,
        :attr_accessor,
        :attr_writer,
        :`,
        :def!,
        :!,
        :_foo?,
        :_foo!,
      ]

      assert_equal expected_names, decls[0].members.map(&:name)
    end
  end

  def test_annotation_on_declaration
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      %a(foo)
      %a[hello world]
      class Hello end

      %a{Lorem Ipsum}
      module Foo end

      %a< undocumented >
      interface _Foo end

      %a|bar is okay|
      type string = String
    SIG

      decls[0].yield_self do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal "foo", decl.annotations[0].string
        assert_equal "%a(foo)", decl.annotations[0].location.source

        assert_equal "hello world", decl.annotations[1].string
        assert_equal "%a[hello world]", decl.annotations[1].location.source
      end

      decls[1].yield_self do |decl|
        assert_instance_of Declarations::Module, decl

        assert_equal "Lorem Ipsum", decl.annotations[0].string
        assert_equal "%a{Lorem Ipsum}", decl.annotations[0].location.source
      end

      decls[2].yield_self do |decl|
        assert_instance_of Declarations::Interface, decl

        assert_equal "undocumented", decl.annotations[0].string
        assert_equal "%a< undocumented >", decl.annotations[0].location.source
      end

      decls[3].yield_self do |decl|
        assert_instance_of Declarations::TypeAlias, decl

        assert_equal "bar is okay", decl.annotations[0].string
        assert_equal "%a|bar is okay|", decl.annotations[0].location.source
      end
    end
  end

  def test_attributes
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Hello
        attr_reader a: Integer
        attr_writer b(@B): String
        attr_accessor c(): bool

        attr_reader self.x: Integer
        attr_writer self.y(@Y): String
        attr_accessor self.z(): bool
      end
    SIG

      decls[0].tap do |module_decl|
        module_decl.members[0].tap do |m|
          assert_equal "attr_reader a: Integer", m.location.source
          assert_instance_of Members::AttrReader, m
          assert_equal :a, m.name
          assert_nil m.ivar_name
          assert_equal :instance, m.kind
          assert_equal parse_type("Integer"), m.type
        end

        module_decl.members[1].tap do |m|
          assert_equal "attr_writer b(@B): String", m.location.source
          assert_instance_of Members::AttrWriter, m
          assert_equal :b, m.name
          assert_equal :@B, m.ivar_name
          assert_equal :instance, m.kind
          assert_equal parse_type("String"), m.type
        end

        module_decl.members[2].tap do |m|
          assert_equal "attr_accessor c(): bool", m.location.source
          assert_instance_of Members::AttrAccessor, m
          assert_equal :c, m.name
          assert_equal false, m.ivar_name
          assert_equal :instance, m.kind
          assert_equal parse_type("bool"), m.type
        end

        module_decl.members[3].tap do |m|
          assert_equal "attr_reader self.x: Integer", m.location.source
          assert_instance_of Members::AttrReader, m
          assert_equal :x, m.name
          assert_nil m.ivar_name
          assert_equal :singleton, m.kind
          assert_equal parse_type("Integer"), m.type
        end

        module_decl.members[4].tap do |m|
          assert_equal "attr_writer self.y(@Y): String", m.location.source
          assert_instance_of Members::AttrWriter, m
          assert_equal :y, m.name
          assert_equal :@Y, m.ivar_name
          assert_equal :singleton, m.kind
          assert_equal parse_type("String"), m.type
        end

        module_decl.members[5].tap do |m|
          assert_equal "attr_accessor self.z(): bool", m.location.source
          assert_instance_of Members::AttrAccessor, m
          assert_equal :z, m.name
          assert_equal false, m.ivar_name
          assert_equal :singleton, m.kind
          assert_equal parse_type("bool"), m.type
        end
      end
    end
  end

  def test_annotations_on_members
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Hello
        %a{noreturn}
        def foo: () -> untyped

        %a[incompatible]
        include Foo

        %a{prepend}
        extend Foo

        %a{dynamic}
        attr_reader foo: Bar

        %a{constructor}
        alias to_str to_s
      end
    SIG

      decls[0].members[0].yield_self do |m|
        assert_instance_of Members::MethodDefinition, m
        assert_equal ["noreturn"], m.annotations.map(&:string)
      end

      decls[0].members[1].yield_self do |m|
        assert_instance_of Members::Include, m
        assert_equal ["incompatible"], m.annotations.map(&:string)
      end

      decls[0].members[2].yield_self do |m|
        assert_instance_of Members::Extend, m
        assert_equal ["prepend"], m.annotations.map(&:string)
      end

      decls[0].members[3].yield_self do |m|
        assert_instance_of Members::AttrReader, m
        assert_equal ["dynamic"], m.annotations.map(&:string)
      end

      decls[0].members[4].yield_self do |m|
        assert_instance_of Members::Alias, m
        assert_equal ["constructor"], m.annotations.map(&:string)
      end
    end
  end

  def test_annotations_on_overload
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Hello
        def foo: %a{noreturn} () -> void
               | %a{implicitly-returns-nil} %a{primitive:is_a?} (Class) -> bool
      end
    SIG

      decls[0].members[0].yield_self do |m|
        assert_instance_of Members::MethodDefinition, m

        assert_equal ["noreturn"], m.overloads[0].annotations.map(&:string)
        assert_equal ["implicitly-returns-nil", "primitive:is_a?"], m.overloads[1].annotations.map(&:string)

        assert_equal "() -> void", m.overloads[0].method_type.location.source
        assert_equal "(Class) -> bool", m.overloads[1].method_type.location.source
      end
    end
  end

  def test_prepend
    Parser.parse_signature(<<~SIG).tap do |_, _, decls|
      class Foo
        prepend Foo
      end
    SIG

      decls[0].members[0].yield_self do |m|
        assert_instance_of Members::Prepend, m
        assert_equal TypeName.new(name: :Foo, namespace: Namespace.empty), m.name
        assert_equal [], m.args
        assert_equal "prepend Foo", m.location.source
      end
    end
  end

  def assert_valid_signature
    Parser.parse_signature yield
  end

  def test_parsings
    assert_valid_signature do
      <<-EOS
module Foo: _Bar
end
      EOS
    end

    assert_valid_signature do
      <<-EOS
class A
  def =~: (untyped) -> bool
  def ===: (untyped) -> bool
end
      EOS
    end

    assert_valid_signature do
      <<-EOS
class X
  def foo: (type: untyped, class: untyped, module: untyped, if: untyped, include: untyped, yield: untyped, def: untyped, self: untyped, instance: untyped, any: untyped, void: void) -> untyped
  def bar: (untyped `type`, void: untyped `void`) -> untyped
end
      EOS
    end
  end

  def test_class_comment
    Parser.parse_signature(<<-EOF).yield_self do |_, _, (foo_decl,bar_decl)|
# This is a class.
# Foo Bar Baz.
class Foo
end

# This is not comment of class.

# This is another class.
module Bar
end
EOF

      assert_instance_of Declarations::Class, foo_decl

      assert_equal <<EOF, foo_decl.comment.string
This is a class.
Foo Bar Baz.
EOF

      assert_instance_of Declarations::Module, bar_decl
      assert_equal <<EOF, bar_decl.comment.string
This is another class.
EOF
    end
  end

  def test_member_comment
    Parser.parse_signature(<<-EOF).yield_self do |_, _, (foo_decl)|
# This is a class.
# Foo Bar Baz.
class Foo
  # This is a method.
  def hello: () -> void

  # This is include
  include Enumerable[Integer]

  # `@size` is the size of Foo.
  @size: Integer
end
    EOF

      assert_instance_of Declarations::Class, foo_decl

      assert_equal <<EOF, foo_decl.comment.string
This is a class.
Foo Bar Baz.
EOF

      foo_decl.members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_equal <<EOF, member.comment.string
This is a method.
EOF
      end

      foo_decl.members[1].tap do |member|
        assert_instance_of Members::Include, member
        assert_equal <<EOF, member.comment.string
This is include
EOF
      end

      foo_decl.members[2].tap do |member|
        assert_instance_of Members::InstanceVariable, member
        assert_equal <<EOF, member.comment.string
`@size` is the size of Foo.
EOF
      end
    end
  end

  def test_code_comment
    Parser.parse_signature(<<-EOF).yield_self do |_, _, (foo_decl)|
# Passes each element of the collection to the given block. The method
# returns `true` if the block never returns `false` or `nil` . If the
# block is not given, Ruby adds an implicit block of `{ |obj| obj }` which
# will cause [all?](Enumerable.downloaded.ruby_doc#method-i-all-3F) to
# return `true` when none of the collection members are `false` or `nil` .
#
# If instead a pattern is supplied, the method returns whether `pattern
# === element` for every collection member.
#
#     %w[ant bear cat].all? { |word| word.length >= 3 } #=> true
#     %w[ant bear cat].all? { |word| word.length >= 4 } #=> false
#     %w[ant bear cat].all?(/t/)                        #=> false
#     [1, 2i, 3.14].all?(Numeric)                       #=> true
#     [nil, true, 99].all?                              #=> false
#     [].all?                                           #=> true
class Foo
end
    EOF

      assert_instance_of Declarations::Class, foo_decl
      assert_equal <<-EOF, foo_decl.comment.string
Passes each element of the collection to the given block. The method
returns `true` if the block never returns `false` or `nil` . If the
block is not given, Ruby adds an implicit block of `{ |obj| obj }` which
will cause [all?](Enumerable.downloaded.ruby_doc#method-i-all-3F) to
return `true` when none of the collection members are `false` or `nil` .

If instead a pattern is supplied, the method returns whether `pattern
=== element` for every collection member.

    %w[ant bear cat].all? { |word| word.length >= 3 } #=> true
    %w[ant bear cat].all? { |word| word.length >= 4 } #=> false
    %w[ant bear cat].all?(/t/)                        #=> false
    [1, 2i, 3.14].all?(Numeric)                       #=> true
    [nil, true, 99].all?                              #=> false
    [].all?                                           #=> true
EOF
    end
  end

  def test_comment_without_leading_space
    Parser.parse_signature(<<-EOF).yield_self do |_, _, (foo_decl)|
#This is a class.
class Foo
  #This is a method.
  def bar: () -> void

  #def baz: () -> void
end
EOF

      assert_instance_of Declarations::Class, foo_decl

      assert_equal <<EOF, foo_decl.comment.string
This is a class.
EOF

      foo_decl.members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_equal <<EOF, member.comment.string
This is a method.
EOF
      end
    end
  end

  def test_parsing_quoted_method_name
    Parser.parse_signature(<<-EOF).yield_self do |foo_decl,|
module Kernel
  def `: (interned name) -> String?

  # Returns a `Binding` object, describing the variable and method bindings
  # at the point of call. This object can be used when calling `eval` to
  # execute the evaluated command in this environment. See also the
  # description of class `Binding` .
  #
  # ```ruby
  # def get_binding(param)
  #   binding
  # end
  # b = get_binding("hello")
  # eval("param", b)   #=> "hello"
  # ```
  def binding: () -> Binding
end
    EOF
    end
  end

  def test_module_type_param_variance
    Parser.parse_signature("interface _Each[A, out B, unchecked in C] end").tap do |_, _, decls|
      assert_equal 1, decls.size

      interface_decl = decls[0]

      assert_instance_of Declarations::Interface, interface_decl
      a, b, c = interface_decl.type_params.each.to_a

      assert_instance_of AST::TypeParam, a
      assert_equal :A, a.name
      assert_equal :invariant, a.variance
      refute a.unchecked?

      assert_instance_of AST::TypeParam, b
      assert_equal :B, b.name
      assert_equal :covariant, b.variance
      refute b.unchecked?

      assert_instance_of AST::TypeParam, c
      assert_equal :C, c.name
      assert_equal :contravariant, c.variance
      assert c.unchecked?
    end
  end

  def test_mame
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
# h –
class Exception < Object
end
EOF

      assert_equal "class Exception < Object", decls[0].location.source.lines[0].chomp
    end
  end

  def test_decl_in_module
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
module Steep
  VERSION: String
  type t = AST::Types::Base | AST::Types::Proc

  def self.logger: () -> Logger

  class Foo end
  module Bar end
  interface _Baz end
end
EOF

      mod = decls[0]

      assert_instance_of Declarations::Module, mod

      assert_equal 6, mod.members.size

      assert_instance_of Declarations::Constant, mod.members[0]
      assert_instance_of Declarations::TypeAlias, mod.members[1]
      assert_instance_of Members::MethodDefinition, mod.members[2]
      assert_instance_of Declarations::Class, mod.members[3]
      assert_instance_of Declarations::Module, mod.members[4]
      assert_instance_of Declarations::Interface, mod.members[5]

      assert_equal 1, mod.each_member.count
      assert_equal 5, mod.each_decl.count
    end
  end

  def test_overload_def
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
module Steep
  def to_s: (Integer) -> String | ...
  def to_i: () -> Integer
end
EOF
      decls[0].members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_predicate member, :overloading?
      end

      decls[0].members[1].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        refute_predicate member, :overloading?
      end
    end
  end

  def test_generics_type_parameter
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
module A[T]
  module B
    def foo: () -> void
  end

  def bar: () -> T
end
EOF
      decls[0].members[1].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_instance_of Types::Variable, member.overloads[0].method_type.type.return_type
      end
    end
  end

  def test_proc
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
module A
  def bar: () -> ^->Integer
end
EOF

      decls[0].members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        member.overloads[0].method_type.type.return_type.tap do |return_type|
          assert_instance_of Types::Proc, return_type
          assert_instance_of Types::ClassInstance, return_type.type.return_type
        end
      end
    end
  end

  def test_syntax_error_on_eof
    ex = assert_raises RBS::ParsingError do
      Parser.parse_signature(<<~SIG)
      class Foo
      SIG
    end
    loc = ex.location
    assert_equal 2, loc.start_line
    assert_equal 0, loc.start_column
  end

  def test_empty
    Parser.parse_signature("").tap do |_, _, decls|
      assert_empty decls
    end
  end

  def test_module_self_syntax
    Parser.parse_signature(<<EOF).tap do |_, _, decls|
module Foo: Object
end

module ::Bar: Object
end

module Baz::Baz: Object
end
EOF
      decls[0].tap do |decl|
        assert_equal RBS::TypeName.parse("Foo"), decl.name
      end

      decls[1].tap do |decl|
        assert_equal RBS::TypeName.parse("::Bar"), decl.name
      end

      decls[2].tap do |decl|
        assert_equal RBS::TypeName.parse("Baz::Baz"), decl.name
      end
    end
  end

  def test_method_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
module A
  def foo: () -> void

  def self?.bar: () -> void
               | ...
end
    EOF
      decls[0].members[0].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "def", foo.location[:keyword].source
        assert_equal "foo", foo.location[:name].source
        assert_nil foo.location[:kind]
        assert_nil foo.location[:overloading]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "def", foo.location[:keyword].source
        assert_equal "bar", foo.location[:name].source
        assert_equal "self?.", foo.location[:kind].source
        assert_equal "...", foo.location[:overloading].source
      end
    end
  end

  def test_var_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
module A
  @foo: Integer
  self.@bar: String

  @@baz: bool
end
    EOF
      decls[0].members[0].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "@foo", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:kind]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "@bar", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "self.", foo.location[:kind].source
      end

      decls[0].members[2].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "@@baz", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:kind]
      end
    end
  end

  def test_attribute_location
    Parser.parse_signature(<<-RBS).tap do |_, _, decls|
module A
  attr_reader reader1: String
  attr_reader reader2 : String
  attr_reader reader3 () : String
  attr_reader reader4 (@reader) : String
  attr_reader self.reader5: String
  attr_reader self.reader6 : String
end
    RBS

      decls[0].members[0].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader1", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader2", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[2].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader3", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "()", foo.location[:ivar].source
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[3].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader4", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "(@reader)", foo.location[:ivar].source
        assert_equal "@reader", foo.location[:ivar_name].source
        assert_nil foo.location[:kind]
      end

      decls[0].members[4].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader5", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end

      decls[0].members[5].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_reader", foo.location[:keyword].source
        assert_equal "reader6", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end
    end

    Parser.parse_signature(<<-RBS).tap do |_, _, decls|
module A
  attr_writer attr1: String
  attr_writer attr2 : String
  attr_writer attr3 () : String
  attr_writer attr4 (@attr0) : String
  attr_writer self.attr5: String
  attr_writer self.attr6 : String
end
    RBS

      decls[0].members[0].tap do |attr|
        assert_instance_of Location, attr.location

        assert_equal "attr_writer", attr.location[:keyword].source
        assert_equal "attr1", attr.location[:name].source
        assert_equal ":", attr.location[:colon].source
        assert_nil attr.location[:ivar]
        assert_nil attr.location[:ivar_name]
        assert_nil attr.location[:kind]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_writer", foo.location[:keyword].source
        assert_equal "attr2", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[2].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_writer", foo.location[:keyword].source
        assert_equal "attr3", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "()", foo.location[:ivar].source
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[3].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_writer", foo.location[:keyword].source
        assert_equal "attr4", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "(@attr0)", foo.location[:ivar].source
        assert_equal "@attr0", foo.location[:ivar_name].source
        assert_nil foo.location[:kind]
      end

      decls[0].members[4].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_writer", foo.location[:keyword].source
        assert_equal "attr5", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end

      decls[0].members[5].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_writer", foo.location[:keyword].source
        assert_equal "attr6", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end
    end

    Parser.parse_signature(<<-RBS).tap do |_, _, decls|
module A
  attr_accessor attr1: String
  attr_accessor attr2 : String
  attr_accessor attr3 () : String
  attr_accessor attr4 (@attr0) : String
  attr_accessor self.attr5: String
  attr_accessor self.attr6 : String
end
    RBS

      decls[0].members[0].tap do |attr|
        assert_instance_of Location, attr.location

        assert_equal "attr_accessor", attr.location[:keyword].source
        assert_equal "attr1", attr.location[:name].source
        assert_equal ":", attr.location[:colon].source
        assert_nil attr.location[:ivar]
        assert_nil attr.location[:ivar_name]
        assert_nil attr.location[:kind]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_accessor", foo.location[:keyword].source
        assert_equal "attr2", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[2].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_accessor", foo.location[:keyword].source
        assert_equal "attr3", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "()", foo.location[:ivar].source
        assert_nil foo.location[:ivar_name]
        assert_nil foo.location[:kind]
      end

      decls[0].members[3].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_accessor", foo.location[:keyword].source
        assert_equal "attr4", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_equal "(@attr0)", foo.location[:ivar].source
        assert_equal "@attr0", foo.location[:ivar_name].source
        assert_nil foo.location[:kind]
      end

      decls[0].members[4].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_accessor", foo.location[:keyword].source
        assert_equal "attr5", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end

      decls[0].members[5].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "attr_accessor", foo.location[:keyword].source
        assert_equal "attr6", foo.location[:name].source
        assert_equal ":", foo.location[:colon].source
        assert_nil foo.location[:ivar]
        assert_nil foo.location[:ivar_name]
        assert_equal "self.", foo.location[:kind].source
      end
    end
  end

  def test_alias_location
    Parser.parse_signature(<<-RBS).tap do |_, _, decls|
module A
  alias foo bar
  alias self.foo self.bar
end
    RBS

      decls[0].members[0].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "alias", foo.location[:keyword].source
        assert_equal "foo", foo.location[:new_name].source
        assert_equal "bar", foo.location[:old_name].source
        assert_nil foo.location[:new_kind]
        assert_nil foo.location[:old_kind]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "alias", foo.location[:keyword].source
        assert_equal "foo", foo.location[:new_name].source
        assert_equal "bar", foo.location[:old_name].source
        assert_equal "self.", foo.location[:new_kind].source
        assert_equal "self.", foo.location[:old_kind].source
      end
    end
  end

  def test_mixin_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
module A
  include _Foo
  include _Bar[String]

  extend Foo
  extend Bar[String]

  prepend Foo
  prepend Bar[String]
end
    EOF
      decls[0].members[0].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "include", foo.location[:keyword].source
        assert_equal "_Foo", foo.location[:name].source
        assert_nil foo.location[:args]
      end

      decls[0].members[1].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "include", foo.location[:keyword].source
        assert_equal "_Bar", foo.location[:name].source
        assert_equal "[String]", foo.location[:args].source
      end

      decls[0].members[2].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "extend", foo.location[:keyword].source
        assert_equal "Foo", foo.location[:name].source
        assert_nil foo.location[:args]
      end

      decls[0].members[3].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "extend", foo.location[:keyword].source
        assert_equal "Bar", foo.location[:name].source
        assert_equal "[String]", foo.location[:args].source
      end

      decls[0].members[4].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "prepend", foo.location[:keyword].source
        assert_equal "Foo", foo.location[:name].source
        assert_nil foo.location[:args]
      end

      decls[0].members[5].tap do |foo|
        assert_instance_of Location, foo.location

        assert_equal "prepend", foo.location[:keyword].source
        assert_equal "Bar", foo.location[:name].source
        assert_equal "[String]", foo.location[:args].source
      end
    end
  end

  def test_interface_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
interface _A
end

interface _B[X, unchecked in Y]
end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "interface", decl.location[:keyword].source
        assert_equal "_A", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_nil decl.location[:type_params]
      end

      decls[1].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "interface", decl.location[:keyword].source
        assert_equal "_B", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_equal "[X, unchecked in Y]", decl.location[:type_params].source

        decl.type_params[0].tap do |param|
          assert_instance_of Location, param.location

          assert_equal "X", param.location[:name].source
          assert_nil param.location[:variance]
          assert_nil param.location[:unchecked]
        end

        decl.type_params[1].tap do |param|
          assert_instance_of Location, param.location

          assert_equal "Y", param.location[:name].source
          assert_equal "in", param.location[:variance].source
          assert_equal "unchecked", param.location[:unchecked].source
        end
      end
    end
  end

  def test_module_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
module A
end

module B[X] : Foo[X], Bar
end

module C: BasicObject end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "module", decl.location[:keyword].source
        assert_equal "A", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_nil decl.location[:type_params]
        assert_nil decl.location[:colon]
        assert_nil decl.location[:self_types]
      end

      decls[1].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "module", decl.location[:keyword].source
        assert_equal "B", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_equal "[X]", decl.location[:type_params].source
        assert_equal ":", decl.location[:colon].source
        assert_equal "Foo[X], Bar", decl.location[:self_types].source
      end

      decls[2].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "module", decl.location[:keyword].source
        assert_equal "C", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_nil decl.location[:type_params]
        assert_equal ":", decl.location[:colon].source
        assert_equal "BasicObject", decl.location[:self_types].source
      end
    end
  end

  def test_class_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
class A
end

class B[X] < Foo[X]
end

class C < Bar
end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "class", decl.location[:keyword].source
        assert_equal "A", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_nil decl.location[:type_params]
        assert_nil decl.location[:lt]
      end

      decls[1].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "class", decl.location[:keyword].source
        assert_equal "B", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_equal "[X]", decl.location[:type_params].source
        assert_equal "<", decl.location[:lt].source

        assert_equal "Foo", decl.super_class.location[:name].source
        assert_equal "[X]", decl.super_class.location[:args].source
        assert_equal [4, 13], decl.super_class.location.start_loc
        assert_equal [4, 19], decl.super_class.location.end_loc
      end

      decls[2].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "class", decl.location[:keyword].source
        assert_equal "C", decl.location[:name].source
        assert_equal "end", decl.location[:end].source
        assert_nil decl.location[:type_params]
        assert_equal "<", decl.location[:lt].source

        assert_equal "Bar", decl.super_class.location[:name].source
        assert_nil decl.super_class.location[:args]
        assert_equal [7, 10], decl.super_class.location.start_loc
        assert_equal [7, 13], decl.super_class.location.end_loc
      end
    end
  end

  def test_constant_global_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
X: String
A::B : String
$B: Integer
    EOF
      decls[0].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "X", decl.location[:name].source
        assert_equal ":", decl.location[:colon].source
      end

      decls[1].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "A::B", decl.location[:name].source
        assert_equal ":", decl.location[:colon].source
      end

      decls[2].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "$B", decl.location[:name].source
        assert_equal ":", decl.location[:colon].source
      end
    end
  end

  def test_type_alias_location
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
type foo = Integer
    EOF
      decls[0].tap do |decl|
        assert_instance_of Location, decl.location

        assert_equal "type", decl.location[:keyword].source
        assert_equal "foo", decl.location[:name].source
        assert_equal "=", decl.location[:eq].source
      end
    end
  end

  def test_interface_name
    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<-RBS)
interface _foo end
      RBS
    end
  end

  def test_lident_param_name
    Parser.parse_signature(<<-RBS)
class Hello
def hello: (String _name) -> void
end
    RBS
  end

  def test_underscore_alias_name
    Parser.parse_signature(<<-RBS)
class Hello
  alias _foo _bar
end
    RBS
  end

  def test_underscore_type_name
    assert_raises RBS::ParsingError do
      Parser.parse_signature(<<-RBS)
type _foo = Integer
      RBS
    end
  end

  def test_underscore_qualified_name
    assert_raises RBS::ParsingError do
      pp Parser.parse_signature(<<-RBS)
type x = Foo::_bar
      RBS
    end
  end

  def test_singleton_member_type_variables
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
class Foo[A]
  @foo: A

  @@foo: A

  self.@foo: A

  def foo: -> A

  def self.foo2: -> A

  def self?.foo3: -> A

  attr_accessor self.foo4: A

  attr_reader self.foo5: A

  attr_writer self.foo6: A

  include M[A]

  extend M[A]

  prepend M[A]
end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Declarations::Class, decl

        assert_instance_of Types::Variable, decl.members[0].type
        assert_instance_of Types::ClassInstance, decl.members[1].type
        assert_instance_of Types::ClassInstance, decl.members[2].type

        assert_instance_of Types::Variable, decl.members[3].overloads[0].method_type.type.return_type
        assert_instance_of Types::ClassInstance, decl.members[4].overloads[0].method_type.type.return_type
        assert_instance_of Types::ClassInstance, decl.members[5].overloads[0].method_type.type.return_type

        assert_instance_of Types::ClassInstance, decl.members[6].type
        assert_instance_of Types::ClassInstance, decl.members[7].type
        assert_instance_of Types::ClassInstance, decl.members[8].type

        assert_instance_of Types::Variable, decl.members[9].args[0]
        assert_instance_of Types::ClassInstance, decl.members[10].args[0]
        assert_instance_of Types::Variable, decl.members[11].args[0]
      end
    end
  end

  def test_generics_bound
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
class Foo[X < _Each[Y]?, Y]
  def foo: [X < Array[Y]] (X) -> X
end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal 2, decl.type_params.size
        decl.type_params[0].tap do |param|
          assert_equal :X, param.name
          assert_equal :invariant, param.variance
          refute_predicate param, :unchecked?
          assert_nil param.upper_bound
          assert_equal parse_type("_Each[Y]?", variables: [:Y]), param.upper_bound_type
        end

        decl.type_params[1].tap do |param|
          assert_equal :Y, param.name
          assert_equal :invariant, param.variance
          refute_predicate param, :unchecked?
          assert_nil param.upper_bound_type
        end

        decl.members[0].tap do |member|
          member.overloads[0].method_type.type_params[0].tap do |param|
            assert_equal :X, param.name
            assert_equal :invariant, param.variance
            refute_predicate param, :unchecked?
            assert_equal parse_type("Array[Y]", variables: [:Y]), param.upper_bound
            assert_equal parse_type("Array[Y]", variables: [:Y]), param.upper_bound_type
          end
        end
      end
    end
  end

  def test_generics_default
    Parser.parse_signature(<<-EOF).tap do |_, _, decls|
class Foo[X < _Each[String]? = Array[String]]
end
    EOF
      decls[0].tap do |decl|
        assert_instance_of Declarations::Class, decl

        assert_equal 1, decl.type_params.size
        decl.type_params[0].tap do |param|
          assert_equal :X, param.name
          assert_equal :invariant, param.variance
          refute_predicate param, :unchecked?
          assert_nil param.upper_bound
          assert_equal 29...44, param.location[:default].range
          assert_equal parse_type("_Each[String]?"), param.upper_bound_type
          assert_equal parse_type("Array[String]"), param.default_type
        end
      end
    end

    assert_raises do
      Parser.parse_signature(<<~EOF)
        class Foo[X = untyped, Y]
        end
      EOF
    end.tap do |error|
      assert_match(/required type parameter is not allowed after optional type parameter/, error.message)
    end
  end

  def test_module_alias_decl
    Parser.parse_signature(<<~EOF).tap do |_, _, decls|
        module RBS::Kernel = Kernel
      EOF

      decls[0].tap do |decl|
        assert_instance_of Declarations::ModuleAlias, decl

        assert_equal RBS::TypeName.parse("RBS::Kernel"), decl.new_name
        assert_equal RBS::TypeName.parse("Kernel"), decl.old_name
        assert_equal "module", decl.location[:keyword].source
        assert_equal "RBS::Kernel", decl.location[:new_name].source
        assert_equal "=", decl.location[:eq].source
        assert_equal "Kernel", decl.location[:old_name].source
      end
    end
  end

  def test_class_alias_decl
    Parser.parse_signature(<<~EOF).tap do |_, _, decls|
        class RBS::Object = Object
      EOF

      decls[0].tap do |decl|
        assert_instance_of Declarations::ClassAlias, decl

        assert_equal RBS::TypeName.parse("RBS::Object"), decl.new_name
        assert_equal RBS::TypeName.parse("Object"), decl.old_name
        assert_equal "class", decl.location[:keyword].source
        assert_equal "RBS::Object", decl.location[:new_name].source
        assert_equal "=", decl.location[:eq].source
        assert_equal "Object", decl.location[:old_name].source
      end
    end
  end

  def test_use_directive
    Parser.parse_signature(<<~RBS).tap do |_, dirs, _|
      use RBS::Namespace as NS
      use RBS::TypeName, RBS::AST::Declarations::*

      module Baz
      end

      class Foo
      end
    RBS

      assert_equal 2, dirs.size

      dirs[0].tap do |use|
        assert_equal 1, use.clauses.size

        use.clauses[0].tap do |clause|
          assert_equal RBS::TypeName.parse("RBS::Namespace"), clause.type_name
          assert_equal :NS, clause.new_name
          assert_equal "RBS::Namespace as NS", clause.location.source
          assert_equal "RBS::Namespace", clause.location[:type_name].source
          assert_equal "as", clause.location[:keyword].source
          assert_equal "NS", clause.location[:new_name].source
        end
      end

      dirs[1].tap do |use|
        assert_equal 2, use.clauses.size

        use.clauses[0].tap do |clause|
          assert_equal RBS::TypeName.parse("RBS::TypeName"), clause.type_name
          assert_nil clause.new_name
          assert_equal "RBS::TypeName", clause.location[:type_name].source
          assert_nil clause.location[:keyword]
          assert_nil clause.location[:new_name]
        end

        use.clauses[1].tap do |clause|
          assert_equal RBS::Namespace.parse("RBS::AST::Declarations::"), clause.namespace
          assert_equal "RBS::AST::Declarations::", clause.location[:namespace].source
          assert_equal "*", clause.location[:star].source
        end
      end
    end
  end

  def test_use_directive_error
    assert_raises do
      Parser.parse_signature(<<~RBS)
        module Baz
        end

        use RBS::Namespace as NS
      RBS
    end
  end

  def test_resolved_directive
    Parser.parse_signature(<<~RBS).tap do |_, dirs, _|
        # resolve-type-names: false

        module Baz
        end
      RBS

      assert_equal 1, dirs.size
      dirs[0].tap do
        assert_instance_of RBS::AST::Directives::ResolveTypeNames, _1
        assert_false _1.value
        assert_equal "resolve-type-names: false", _1.location.source
        assert_equal "resolve-type-names", _1.location[:keyword].source
        assert_equal ":", _1.location[:colon].source
        assert_equal "false", _1.location[:value].source
      end
    end

    Parser.parse_signature(<<~RBS).tap do |_, dirs, _|
        #resolve-type-names : true

        module Baz
        end
      RBS

      assert_equal 1, dirs.size
      dirs[0].tap do
        assert_instance_of RBS::AST::Directives::ResolveTypeNames, _1
        assert_true _1.value
        assert_equal "resolve-type-names : true", _1.location.source
        assert_equal "resolve-type-names", _1.location[:keyword].source
        assert_equal ":", _1.location[:colon].source
        assert_equal "true", _1.location[:value].source
      end
    end

    Parser.parse_signature(<<~RBS).tap do |_, dirs, _|
        # This is a comment
        # resolve-type-names: false

        module Baz
        end
      RBS

      assert_empty dirs
    end
  end

  def test_class_module_alias__annotation
    Parser.parse_signature(<<~RBS).tap do |_, _, decls|
        %a{module}
        module Foo = Kernel

        %a{class} class Bar = Object
      RBS

      assert_equal 2, decls.size
      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::ModuleAlias, decl
        assert_equal ["module"], decl.annotations.map(&:string)
      end
      decls[1].tap do |decl|
        assert_instance_of RBS::AST::Declarations::ClassAlias, decl
        assert_equal ["class"], decl.annotations.map(&:string)
      end
    end
  end

  def test_global__annotation
    Parser.parse_signature(<<~RBS).tap do |_, _, decls|
        %a{annotation}
        $FOO: String
      RBS

      assert_equal 1, decls.size
      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Global, decl
        assert_equal ["annotation"], decl.annotations.map(&:string)
      end
    end
  end

  def test_constant__annotation
    Parser.parse_signature(<<~RBS).tap do |_, _, decls|
        %a{annotation}
        FOO: String
      RBS

      assert_equal 1, decls.size
      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Constant, decl
        assert_equal ["annotation"], decl.annotations.map(&:string)
      end
    end
  end

  def test__method_type__untyped_function_and_block
    assert_raises(RBS::ParsingError) do
      Parser.parse_signature(<<~RBS).tap do |_, _, decls|
          class Foo
            def foo: (?) { () -> void } -> void
          end
        RBS
      end
    end
  end
end
