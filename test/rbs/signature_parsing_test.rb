require "test_helper"

class RBS::SignatureParsingTest < Minitest::Test
  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace
  Declarations = RBS::AST::Declarations
  Members = RBS::AST::Members
  MethodType = RBS::MethodType

  include TestHelper

  def test_type_alias
    Parser.parse_signature("type Steep::foo = untyped").yield_self do |decls|
      assert_equal 1, decls.size

      type_decl = decls[0]

      assert_instance_of Declarations::Alias, type_decl
      assert_equal TypeName.new(name: :foo, namespace: Namespace.parse("Steep")), type_decl.name
      assert_equal Types::Bases::Any.new(location: nil), type_decl.type
      assert_equal "type Steep::foo = untyped", type_decl.location.source
    end
  end

  def test_constant
    Parser.parse_signature("FOO: untyped").yield_self do |decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :FOO, namespace: Namespace.empty), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "FOO: untyped", const_decl.location.source
    end

    Parser.parse_signature("::BAR: untyped").yield_self do |decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :BAR, namespace: Namespace.root), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "::BAR: untyped", const_decl.location.source
    end

    Parser.parse_signature("FOO : untyped").yield_self do |decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :FOO, namespace: Namespace.empty), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "FOO : untyped", const_decl.location.source
    end

    Parser.parse_signature("::BAR : untyped").yield_self do |decls|
      assert_equal 1, decls.size

      const_decl = decls[0]

      assert_instance_of Declarations::Constant, const_decl
      assert_equal TypeName.new(name: :BAR, namespace: Namespace.root), const_decl.name
      assert_equal Types::Bases::Any.new(location: nil), const_decl.type
      assert_equal "::BAR : untyped", const_decl.location.source
    end
  end

  def test_global
    Parser.parse_signature("$FOO: untyped").yield_self do |decls|
      assert_equal 1, decls.size

      global_decl = decls[0]

      assert_instance_of Declarations::Global, global_decl
      assert_equal :"$FOO", global_decl.name
      assert_equal Types::Bases::Any.new(location: nil), global_decl.type
      assert_equal "$FOO: untyped", global_decl.location.source
    end
  end

  def test_interface
    Parser.parse_signature("interface _Each[A, B] end").yield_self do |decls|
      assert_equal 1, decls.size

      interface_decl = decls[0]

      assert_instance_of Declarations::Interface, interface_decl
      assert_equal TypeName.new(name: :_Each, namespace: Namespace.empty), interface_decl.name
      assert_equal [:A, :B], interface_decl.type_params.each.map(&:name)
      assert_equal [], interface_decl.members
      assert_equal "interface _Each[A, B] end", interface_decl.location.source
    end

    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
        assert_equal 3, def_member.types.size

        def_member.types.yield_self do |t1, t2, t3|
          assert_empty t1.type_params
          assert_nil t1.block
          assert_equal "-> Integer", t1.location.source

          assert_empty t2.type_params
          assert_equal 1, t2.type.required_positionals.size
          assert_nil t2.block
          assert_equal "(untyped) -> Integer", t2.location.source

          assert_equal [:X], t3.type_params
          assert_instance_of Types::Block, t3.block
          assert_instance_of Types::Variable, t3.block.type.required_positionals[0].type
          assert_instance_of Types::Variable, t3.block.type.return_type
          assert_equal "[X] { (A) -> X } -> Integer", t3.location.source
        end
      end

      interface_decl.members[1].yield_self do |include_member|
        assert_instance_of Members::Include, include_member
        assert_equal TypeName.new(name: :_Hash, namespace: Namespace.empty), include_member.name
        assert_equal [parse_type("Integer")], include_member.args
      end
    end

    assert_raises Parser::SemanticsError do
      Parser.parse_signature(<<~SIG)
        interface _Each[A, B]
          def self.foo: -> void
        end
      SIG
    end

    assert_raises Parser::SemanticsError do
      Parser.parse_signature(<<~SIG)
        interface _Each[A, B]
          include Object
        end
      SIG
    end
  end

  def test_module
    Parser.parse_signature("module Enumerable[A, B] end").yield_self do |decls|
      assert_equal 1, decls.size

      module_decl = decls[0]

      assert_instance_of Declarations::Module, module_decl
      assert_equal TypeName.new(name: :Enumerable, namespace: Namespace.empty), module_decl.name
      assert_equal [:A, :B], module_decl.type_params.each.map(&:name)
      assert_equal [], module_decl.self_types
      assert_equal [], module_decl.members
      assert_equal "module Enumerable[A, B] end", module_decl.location.source
    end

    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
    Parser.parse_signature(<<-RBS).yield_self do |decls|
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
    Parser.parse_signature("class Array[A] end").yield_self do |decls|
      assert_equal 1, decls.size

      decls[0].yield_self do |class_decl|
        assert_instance_of Declarations::Class, class_decl
        assert_equal TypeName.new(name: :Array, namespace: Namespace.empty), class_decl.name
        assert_equal [:A], class_decl.type_params.each.map(&:name)
        assert_nil class_decl.super_class
      end
    end

    Parser.parse_signature("class ::Array[A] < Object[A] end").yield_self do |decls|
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
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
          assert_equal 3, m.types.size

          m.types[0].yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "-> Integer", ty.location.source
            assert_nil ty.block
          end

          m.types[1].yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "?{ -> void } -> Integer", ty.location.source
            assert_instance_of Types::Block, ty.block
            refute ty.block.required
          end

          m.types[2].yield_self do |ty|
            assert_instance_of MethodType, ty
            assert_equal "[A] () { (String, ?Object, *Float, Symbol, foo: bool, ?bar: untyped, **Y) -> X } -> A", ty.location.source
            assert_instance_of Types::Block, ty.block
            assert ty.block.required
          end
        end
      end
    end
  end

  def test_incompatible_method_definition
    # `incompatible` is ignored with warning message.
    silence_warnings do
      Parser.parse_signature(<<~SIG).yield_self do |decls|
      class Foo
        incompatible def foo: () -> Integer
      end
     SIG
        assert_equal 1, decls.size

        decls[0].yield_self do |decl|
          assert_instance_of Declarations::Class, decl

          assert_instance_of Members::MethodDefinition, decl.members[0]
        end
      end
    end
  end

  def test_method_super
    assert_raises Parser::SyntaxError do
      Parser.parse_signature(<<~SIG)
      class Foo
        def foo: -> void
               | super
      end
      SIG
    end
  end

  def test_private_public
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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

  def test_alias
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
        def `\\``: -> untyped
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
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
        assert_instance_of Declarations::Alias, decl

        assert_equal "bar is okay", decl.annotations[0].string
        assert_equal "%a|bar is okay|", decl.annotations[0].location.source
      end
    end
  end

  def test_attributes
    Parser.parse_signature(<<~SIG).tap do |decls|
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
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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

  def test_prepend
    Parser.parse_signature(<<~SIG).yield_self do |decls|
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
    Parser.parse_signature(<<-EOF).yield_self do |foo_decl,bar_decl|
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
    Parser.parse_signature(<<-EOF).yield_self do |foo_decl,|
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
    Parser.parse_signature(<<-EOF).yield_self do |foo_decl,|
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
    Parser.parse_signature(<<-EOF).yield_self do |foo_decl,|
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
  def `: (Symbol | String name) -> String?

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
    Parser.parse_signature("interface _Each[A, out B, unchecked in C] end").yield_self do |decls|
      assert_equal 1, decls.size

      interface_decl = decls[0]

      assert_instance_of Declarations::Interface, interface_decl
      a, b, c = interface_decl.type_params.each.to_a

      assert_instance_of Declarations::ModuleTypeParams::TypeParam, a
      assert_equal :A, a.name
      assert_equal :invariant, a.variance
      refute a.skip_validation

      assert_instance_of Declarations::ModuleTypeParams::TypeParam, b
      assert_equal :B, b.name
      assert_equal :covariant, b.variance
      refute b.skip_validation

      assert_instance_of Declarations::ModuleTypeParams::TypeParam, c
      assert_equal :C, c.name
      assert_equal :contravariant, c.variance
      assert c.skip_validation
    end
  end

  def test_mame
    Parser.parse_signature(<<EOF).yield_self do |decls|
# h –
class Exception < Object
end
EOF

      assert_equal "class Exception < Object", decls[0].location.source.lines[0].chomp
    end
  end

  def test_decl_in_module
    Parser.parse_signature(<<EOF).yield_self do |decls|
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
      assert_instance_of Declarations::Alias, mod.members[1]
      assert_instance_of Members::MethodDefinition, mod.members[2]
      assert_instance_of Declarations::Class, mod.members[3]
      assert_instance_of Declarations::Module, mod.members[4]
      assert_instance_of Declarations::Interface, mod.members[5]

      assert_equal 1, mod.each_member.count
      assert_equal 5, mod.each_decl.count
    end
  end

  def test_overload_def
    Parser.parse_signature(<<EOF).yield_self do |decls|
module Steep
  def to_s: (Integer) -> String | ...
  def to_i: () -> Integer
end
EOF
      decls[0].members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_operator member, :overload?
      end

      decls[0].members[1].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        refute_operator member, :overload?
      end
    end
  end

  def test_overload_def_deprecated
    silence_warnings do
      Parser.parse_signature(<<EOF).yield_self do |decls|
module Steep
  overload def to_s: (Integer) -> String
end
EOF
        decls[0].members[0].tap do |member|
          assert_instance_of Members::MethodDefinition, member
          assert_operator member, :overload?
        end
      end
    end
  end

  def test_generics_type_parameter
    Parser.parse_signature(<<EOF).yield_self do |decls|
module A[T]
  module B
    def foo: () -> void
  end

  def bar: () -> T
end
EOF
      decls[0].members[1].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        assert_instance_of Types::Variable, member.types[0].type.return_type
      end
    end
  end

  def test_proc
    Parser.parse_signature(<<EOF).tap do |decls|
module A
  def bar: () -> ^->Integer
end
EOF

      decls[0].members[0].tap do |member|
        assert_instance_of Members::MethodDefinition, member
        member.types[0].type.return_type.tap do |return_type|
          assert_instance_of Types::Proc, return_type
          assert_instance_of Types::ClassInstance, return_type.type.return_type
        end
      end
    end
  end

  def test_syntax_error_on_eof
    ex = assert_raises Parser::SyntaxError do
      Parser.parse_signature(<<~SIG)
      class Foo
      SIG
    end
    loc = ex.error_value.location
    assert_equal 1, loc.start_line
    assert_equal 9, loc.start_column
  end

  def test_empty
    Parser.parse_signature("").tap do |decls|
      assert_empty decls
    end
  end
end
