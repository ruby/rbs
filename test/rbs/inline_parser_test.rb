require "test_helper"

class RBS::InlineParserTest < Test::Unit::TestCase
  def parse_ruby(source)
    [
      RBS::Buffer.new(name: Pathname("test.rb"), content: source),
      Prism.parse(source)
    ]
  end

  def test_parse
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        def foo = 123
      end

      module Bar
        def self.bar = 123
      end

      class <<self
      end

      FOO = 123
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    pp ret
  end

  def test_parse__class_decl__super
    buffer, result = parse_ruby(<<~RUBY)
      class Foo < Object
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    pp ret.declarations[0]
  end

  def assert_any!(collection, &block)
    assert_block(build_message("No item passed the block", "?", collection)) do
      collection.each do |item|
        yield item
        return
      rescue Test::Unit::AssertionFailedError
        # skip
      end

      false
    end
  end

  def test_parse__class_decl__diagnostics__name
    buffer, result = parse_ruby(<<~RUBY)
      class (true && Object)::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "(true && Object)::Foo", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__class_decl__diagnostics__super
    buffer, result = parse_ruby(<<~RUBY)
      class Foo < c::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "c::Foo", _1.location.source
    end

    assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, ret.declarations[0]
  end

  def test_parse__class_decl__diagnostics__in_singleton
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          class Bar
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::DeclarationInsideSingletonClass, _1
      assert_equal "Bar", _1.location.source
      assert_equal "Class definition inside singleton class definition is ignored", _1.message
    end
  end

  def test_parse__singleton_class_decl__diagnostics__top_level
    buffer, result = parse_ruby(<<~RUBY)
      class <<self
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "<<self", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__singleton_class_decl__diagnostics__no_self
    buffer, result = parse_ruby(<<~RUBY)
      class <<Object
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "Object", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__singleton_class_decl__diagnostics__nested
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          class <<self
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "<<self", _1.location.source
    end

    assert_equal 1, ret.declarations.size
  end

  def test_parse__singleton_class_decl__possible_members
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          def foo = 123

          alias bar foo

          public

          private
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_empty ret.diagnostics

    assert_equal 1, ret.declarations.size
    ret.declarations[0].tap do |klass|
      klass.members[0].tap do |sclass|
        assert_instance_of RBS::AST::Ruby::Declarations::SingletonClassDecl, sclass

        assert_equal 4, sclass.members.size
      end
    end
  end

  def test_error__singleton_class_decl__singleton_def
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          def self.foo = 123
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::UnexpectedSingletonClassMemberError, _1
      assert_equal "def self.foo = 123", _1.location.source
    end

    ret.declarations[0].tap do |klass|
      klass.members[0].tap do |sclass|
        assert_instance_of RBS::AST::Ruby::Declarations::SingletonClassDecl, sclass
        assert_empty sclass.members
      end
    end
  end

  def test_error__singleton_class_decl__mixin
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          include Bar
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::UnexpectedSingletonClassMemberError, _1
      assert_equal "include Bar", _1.location.source
    end

    ret.declarations[0].tap do |klass|
      klass.members[0].tap do |sclass|
        assert_instance_of RBS::AST::Ruby::Declarations::SingletonClassDecl, sclass
        assert_empty sclass.members
      end
    end
  end

  def test_error__singleton_class_decl__ivar_annotation
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          # @rbs @foo: String
          # @rbs! @bar: String
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::VariableAnnotationInSingletonClassError, _1
      assert_equal "@rbs @foo: String", _1.location.source
    end

    ret.declarations[0].tap do |klass|
      klass.members[0].tap do |sclass|
        assert_instance_of RBS::AST::Ruby::Declarations::SingletonClassDecl, sclass
        assert_empty sclass.members
      end
    end
  end

  def test_error__method_def__toplevel
    buffer, result = parse_ruby(<<~RUBY)
      def foo = 123
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::TopLevelMethodDefinition, _1
      assert_equal "def foo = 123", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_parse__alias__class_module
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        alias foo :bar
      end

      module Bar
        alias :foo bar
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_empty ret.diagnostics

    ret.declarations[0].tap do |klass|
      assert_any!(klass.members) do |member|
        assert_instance_of RBS::AST::Ruby::Members::AliasMember, member
        assert_equal "alias foo :bar", member.location.source
        assert_equal :foo, member.new_name
        assert_equal :bar, member.old_name
      end
    end

    ret.declarations[1].tap do |klass|
      assert_any!(klass.members) do |member|
        assert_instance_of RBS::AST::Ruby::Members::AliasMember, member
        assert_equal "alias :foo bar", member.location.source
        assert_equal :foo, member.new_name
        assert_equal :bar, member.old_name
      end
    end
  end

  def test_error__alias__class_module__non_literal
    buffer, result = parse_ruby(<<~'RUBY')
      class Foo
        alias :"foo#{1+2}" bar

        alias foo :"bar#{1+2}"
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::MethodNameAliasNonLiteralError, _1
      assert_equal ':"foo#{1+2}"', _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::MethodNameAliasNonLiteralError, _1
      assert_equal ':"bar#{1+2}"', _1.location.source
    end

    ret.declarations[0].tap do |klass|
      assert_empty klass.members
    end
  end

  def test_parse__module_decl__no_const_name
    buffer, result = parse_ruby(<<~RUBY)
      module c::Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "c::Foo", _1.location.source
    end

    assert_empty ret.declarations
  end

  def test_error__module_decl__inside_singleton_class
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        class <<self
          module Foo
          end
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_equal "Foo", _1.location.source
    end
  end

  def test_parse__mixin_type_params
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs generic T -- type of the element
      class Foo
        include Bar #[T]
        extend Baz #[T]
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |klass|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, klass
      klass.members[0].tap do |mixin|
        assert_instance_of RBS::AST::Ruby::Members::IncludeMember, mixin
        assert_equal ["T"], mixin.type_args.map(&:to_s)
        assert_instance_of RBS::Types::Variable, mixin.type_args[0]
      end
      klass.members[1].tap do |mixin|
        assert_instance_of RBS::AST::Ruby::Members::ExtendMember, mixin
        assert_equal ["T"], mixin.type_args.map(&:to_s)
        assert_instance_of RBS::Types::ClassInstance, mixin.type_args[0]
      end
    end
  end

  def test_parse__super_class__type_params
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs generic T -- type of the element
      class Foo < Bar #[T]
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |klass|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl, klass
      assert_equal ["T"], klass.super_class.type_args.map(&:to_s)
      assert_instance_of RBS::Types::Variable, klass.super_class.type_args[0]
    end
  end

  def test_parse__private_public__diagnostics__outside_module
    buffer, result = parse_ruby(<<~RUBY)
      private
      public()
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "private", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "public", _1.location.source
    end
  end

  def test_parse__private_public__diagnostics__with_args
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        private :foo
        public(:bar)
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal ":foo", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal ":bar", _1.location.source
    end
  end

  def test_parse__private_public__diagnostics__with_receiver
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        Foo.private
        Bar.public
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "Foo", _1.location.source
    end

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidVisibilityCall, _1
      assert_equal "Bar", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__outside_module
    buffer, result = parse_ruby(<<~RUBY)
      include Foo
      extend Bar
      prepend Baz
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "include", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "prepend", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "extend", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__no_self_receiver
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        Bar.include Baz
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "Bar", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__arguments
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        include
        extend Bar, Baz
        prepend(*baz)
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "include", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "Bar, Baz", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "*baz", _1.location.source
    end
  end

  def test_parse__mixin_calls__diagnostics__non_constant
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        include c
        extend c::Bar
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "c", _1.location.source
    end
    assert_any!(ret.diagnostics) do
      assert_instance_of RBS::InlineParser::Diagnostics::InvalidMixinCall, _1
      assert_equal "c::Bar", _1.location.source
    end
  end

  def test_parse__method_definition__annotated__params
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        # @rbs a: Integer
        # @rbs b: Integer
        # @rbs *c: Integer
        # @rbs d: Integer
        # @rbs e: Integer?
        # @rbs **f: Integer
        # @rbs return: void
        def foo(a, b = 1, *c, d:, e: nil, **f)
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |defn|
      assert_equal [[]], defn.overloads.map { _1.annotations.map(&:string) }
      assert_equal ["(Integer a, ?Integer b, *Integer c, d: Integer, ?e: Integer?, **Integer f) -> void"], defn.overloads.map(&:method_type).map(&:to_s)
    end
  end

  def test_parse__method_definition__return_type_assertion
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        def foo() #: Integer
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |defn|
      assert_equal [[]], defn.overloads.map { _1.annotations.map(&:string) }
      assert_equal ["() -> Integer"], defn.overloads.map(&:method_type).map(&:to_s)
    end
  end

  def test_parse__method_definition__method_types
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        # Hello World
        #
        #: () -> Integer
        #: %a{pure} () -> String?
        # @rbs () -> Symbol
        #    | %a{pure} () -> bool?
        # @rbs %a{pure} () -> Array[String]
        def foo()
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |defn|
      assert_equal [[], ["pure"], [], ["pure"], ["pure"]], defn.overloads.map { _1.annotations.map(&:string) }
      assert_equal ["() -> Integer", "() -> String?", "() -> Symbol", "() -> bool?", "() -> Array[String]"], defn.overloads.map(&:method_type).map(&:to_s)
    end
  end

  def test_parse__method_definition__block
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        # @rbs &block: ? (String) -> void -- Block
        def foo(&block)
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |defn|
      assert_equal [[]], defn.overloads.map { _1.annotations.map(&:string) }
      assert_equal ["() ?{ (String) -> void } -> untyped"], defn.overloads.map(&:method_type).map(&:to_s)
    end
  end

  def test_unused_annotations
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        # @rbs () -> void
        # @rbs x: String
        # @rbs return: untyped
        # @rbs %a{pure}
        # @rbs y: (
        def foo(x)
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |defn|
      assert_equal [[]], defn.overloads.map { _1.annotations.map(&:string) }
      assert_equal ["() -> void"], defn.overloads.map(&:method_type).map(&:to_s)
    end

    assert_equal ["@rbs x: String", "@rbs return: untyped", "@rbs y: ("], ret.diagnostics.map { _1.location.source }
  end

  def test_mixin__type_args
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        include Bar #[Integer, String]
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].members[0].tap do |mixin|
      assert_equal ["Integer", "String"], mixin.type_args.map(&:to_s)
    end
  end

  def test_class_decl__generic
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs generic A -- type parameter of A
      # @rbs generic out B < Integer = untyped
      class Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |klass|
      assert_equal "A", klass.generics.type_params[0].to_s
      assert_equal "out B < Integer = untyped", klass.generics.type_params[1].to_s
    end
  end

  def test_class_decl__super_annotation
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs inherits BasicObject -- inherits super class
      class Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |klass|
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperAnnotation, klass.super_annotation
      assert_instance_of RBS::AST::Ruby::Declarations::ClassDecl::SuperAnnotation, klass.super_class

      assert_equal "BasicObject", klass.super_annotation.name.to_s
      assert_empty klass.super_annotation.args
    end
  end

  def test_module_decl__generic
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs generic A -- type parameter of A
      # @rbs generic out B < Integer = untyped
      module Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |mod|
      assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, mod
      assert_equal "A", mod.generics.type_params[0].to_s
      assert_equal "out B < Integer = untyped", mod.generics.type_params[1].to_s
    end
  end

  def test_module_decl__self_constraints
    buffer, result = parse_ruby(<<~RUBY)
      # @rbs module-self BasicObject -- type parameter of A
      module Foo
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |mod|
      assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, mod

      mod.self_constraints[0].tap do |constraint|
        assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl::SelfConstraint, constraint
        assert_equal "BasicObject", constraint.name.to_s
        assert_equal [], constraint.args
      end
    end
  end

  def test_ivar_annotation
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        # @rbs @name: String -- name of something

        def foo = nil

        # @rbs self.@name: String -- name of something else
        # @rbs @@name: String -- one more name
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |mod|
      assert_instance_of RBS::AST::Ruby::Declarations::ModuleDecl, mod

      mod.members[0].tap do |ivar|
        assert_instance_of RBS::AST::Ruby::Members::InstanceVariableMember, ivar
        assert_equal :@name, ivar.name
        assert_equal "String", ivar.type.to_s
        assert_equal "@rbs @name: String -- name of something", ivar.location.source
      end

      mod.members[2].tap do |ivar|
        assert_instance_of RBS::AST::Ruby::Members::ClassInstanceVariableMember, ivar
        assert_equal :@name, ivar.name
        assert_equal "String", ivar.type.to_s
        assert_equal "@rbs self.@name: String -- name of something else", ivar.location.source
      end

      mod.members[3].tap do |ivar|
        assert_instance_of RBS::AST::Ruby::Members::ClassVariableMember, ivar
        assert_equal :@@name, ivar.name
        assert_equal "String", ivar.type.to_s
        assert_equal "@rbs @@name: String -- one more name", ivar.location.source
      end
    end
  end

  def test_ivar_annotation__singleton_class
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        class <<self
          # @rbs @name: String
          # @rbs self.@name: String
          # @rbs @@name: String
        end
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    assert_equal 3, ret.diagnostics.size
    assert_any!(ret.diagnostics) do |diag|
      assert_instance_of RBS::InlineParser::Diagnostics::VariableAnnotationInSingletonClassError, diag
      assert_equal "@rbs @name: String", diag.location.source
    end
    assert_any!(ret.diagnostics) do |diag|
      assert_instance_of RBS::InlineParser::Diagnostics::VariableAnnotationInSingletonClassError, diag
      assert_equal "@rbs self.@name: String", diag.location.source
    end
    assert_any!(ret.diagnostics) do |diag|
      assert_instance_of RBS::InlineParser::Diagnostics::VariableAnnotationInSingletonClassError, diag
      assert_equal "@rbs @@name: String", diag.location.source
    end
  end

  def test_rbs_embedded_annotation
    buffer, result = parse_ruby(<<~RUBY)
      module Foo
        # @rbs! type t = String | Integer
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    ret.declarations[0].tap do |decl|
      decl.members[0].tap do |member|
        assert_instance_of RBS::AST::Ruby::Declarations::EmbeddedRBSDecl, member
        assert_instance_of RBS::AST::Declarations::TypeAlias, member.members[0]
      end
    end
  end
end
