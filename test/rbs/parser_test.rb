require "test_helper"

class RBS::ParserTest < Test::Unit::TestCase
  def buffer(source)
    RBS::Buffer.new(content: source, name: "test.rbs")
  end

  def test_interface
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        interface _Foo[unchecked in A]
          def bar: [A] () -> A

          def foo: () -> A
                | { () -> void } -> void
        end
      RBS

      decls[0].tap do |decl|
        decl.members[0].tap do |member|
          assert_equal :bar, member.name
          assert_instance_of RBS::Types::Variable, member.overloads[0].method_type.type.return_type
        end

        decl.members[1].tap do |member|
          assert_equal :foo, member.name
          assert_instance_of RBS::Types::Variable, member.overloads[0].method_type.type.return_type
        end
      end
    end
  end

  def test_interface_def_singleton_error
    assert_raises do
      RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |decls|
          interface _Foo
            def self?.foo: () -> A
          end
        RBS

        decls[0].tap do |decl|
          pp decl
        end
      end
    end
  end

  def test_interface_mixin
    assert_raises do
      RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |decls|
          interface _Foo[unchecked in A]
            include Array[A]
            extend Object
            prepend _Foo[String]
          end
        RBS

        decls[0].tap do |decl|
          pp decl.members
        end
      end
    end
  end

  def test_type_error_for_content
    buffer = RBS::Buffer.new(content: 1, name: nil)
    assert_raises TypeError do
      RBS::Parser.parse_signature(buffer)
    end
  end

  def test_type_error_for_variables
    assert_raises TypeError do
      RBS::Parser.parse_type("bool", variables: 1)
    end
  end

  def test_interface_alias
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        interface _Foo[unchecked in A]
          alias hello world
        end
      RBS

      decls[0].tap do |decl|
        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::Alias, member
          assert_equal :instance, member.kind
          assert_equal :hello, member.new_name
          assert_equal :world, member.old_name
          assert_equal "alias hello world", member.location.source
        end
      end
    end
  end

  def test_module_decl
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[X] : String, _Array[Symbol]
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl
        assert_equal RBS::TypeName.parse("Foo"), decl.name

        assert_equal "module", decl.location[:keyword].source
        assert_equal "Foo", decl.location[:name].source
        assert_equal "[X]", decl.location[:type_params].source
        assert_equal ":", decl.location[:colon].source
        assert_equal "String, _Array[Symbol]", decl.location[:self_types].source
        assert_equal "end", decl.location[:end].source
      end
    end
  end

  def test_module_decl_def
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[X] : String, _Array[Symbol]
          def foo: () -> void

          def self.bar: () -> void

          def self?.baz: () -> void
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl
      end
    end
  end

  def test_module_decl_vars
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[X] : String, _Array[Symbol]
          @foo: Integer

          self.@bar: String

          @@baz: X
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl
      end
    end
  end

  def test_module_decl_attributes
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo
          attr_reader string: String
          attr_writer self.name (): Integer
          attr_accessor writer (@Writer): Symbol
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::AttrReader, member
          assert_equal :instance, member.kind
          assert_equal :string, member.name
          assert_equal "String", member.type.to_s

          assert_equal "attr_reader", member.location[:keyword].source
          assert_equal "string", member.location[:name].source
          assert_nil member.location[:kind]
          assert_nil member.location[:ivar]
          assert_nil member.location[:ivar_name]
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Members::AttrWriter, member
          assert_equal :singleton, member.kind
          assert_equal :name, member.name
          assert_equal "Integer", member.type.to_s
          assert_equal false, member.ivar_name

          assert_equal "attr_writer", member.location[:keyword].source
          assert_equal "name", member.location[:name].source
          assert_equal "self.", member.location[:kind].source
          assert_equal "()", member.location[:ivar].source
          assert_nil member.location[:ivar_name]
        end

        decl.members[2].tap do |member|
          assert_instance_of RBS::AST::Members::AttrAccessor, member
          assert_equal :instance, member.kind
          assert_equal :writer, member.name
          assert_equal "Symbol", member.type.to_s
          assert_equal :"@Writer", member.ivar_name

          assert_equal "attr_accessor", member.location[:keyword].source
          assert_equal "writer", member.location[:name].source
          assert_nil member.location[:kind]
          assert_equal "(@Writer)", member.location[:ivar].source
          assert_equal "@Writer", member.location[:ivar_name].source
        end
      end
    end
  end

  def test_module_decl_public_private
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo
          public
          private
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        assert_instance_of RBS::AST::Members::Public, decl.members[0]
        assert_instance_of RBS::AST::Members::Private, decl.members[1]
      end
    end
  end

  def test_module_decl_nested
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo
          type foo = bar

          BAZ: Integer
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl
      end
    end
  end

  def test_module_type_var_decl
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[A]
          type t = A

          FOO: A
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Declarations::TypeAlias, member
          assert_instance_of RBS::Types::ClassInstance, member.type
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Declarations::Constant, member
          assert_instance_of RBS::Types::ClassInstance, member.type
        end
      end
    end
  end

  def test_module_type_var_ivar
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[A]
          @x: A
          @@x: A
          self.@x: A
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::InstanceVariable, member
          assert_instance_of RBS::Types::Variable, member.type
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Members::ClassVariable, member
          assert_instance_of RBS::Types::ClassInstance, member.type
        end

        decl.members[2].tap do |member|
          assert_instance_of RBS::AST::Members::ClassInstanceVariable, member
          assert_instance_of RBS::Types::ClassInstance, member.type
        end
      end
    end
  end

  def test_module_type_var_attr
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[A]
          attr_reader foo: A
          attr_writer self.bar: A
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::AttrReader, member
          assert_instance_of RBS::Types::Variable, member.type
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Members::AttrWriter, member
          assert_instance_of RBS::Types::ClassInstance, member.type
        end
      end
    end
  end

  def test_module_type_var_method
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[A]
          def foo: () -> A

          def self.bar: () -> A

          def self?.baz: () -> A
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::MethodDefinition, member
          assert_instance_of RBS::Types::Variable, member.overloads[0].method_type.type.return_type
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Members::MethodDefinition, member
          assert_instance_of RBS::Types::ClassInstance, member.overloads[0].method_type.type.return_type
        end

        decl.members[2].tap do |member|
          assert_instance_of RBS::AST::Members::MethodDefinition, member
          assert_instance_of RBS::Types::ClassInstance, member.overloads[0].method_type.type.return_type
        end
      end
    end
  end

  def test_module_type_var_mixin
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        module Foo[A]
          include X[A]

          extend X[A]

          prepend X[A]
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Module, decl

        decl.members[0].tap do |member|
          assert_instance_of RBS::AST::Members::Include, member
          assert_instance_of RBS::Types::Variable, member.args[0]
        end

        decl.members[1].tap do |member|
          assert_instance_of RBS::AST::Members::Extend, member
          assert_instance_of RBS::Types::ClassInstance, member.args[0]
        end

        decl.members[2].tap do |member|
          assert_instance_of RBS::AST::Members::Prepend, member
          assert_instance_of RBS::Types::Variable, member.args[0]
        end
      end
    end
  end

  def test_class_decl
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        class Foo
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Class, decl
        assert_equal RBS::TypeName.parse("Foo"), decl.name
        assert_predicate decl.type_params, :empty?
        assert_nil decl.super_class
      end
    end

    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        class Foo[A] < Bar[A]
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Class, decl
        assert_equal RBS::TypeName.parse("Foo"), decl.name
        assert_equal [:A], decl.type_params.each.map(&:name)
        assert_equal RBS::TypeName.parse("Bar"), decl.super_class.name
      end
    end
  end

  def test_method_name
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        class Foo
          def |: () -> void
          def ^: () -> void
          def &: () -> void
          def <=>: () -> void
          def ==: () -> void
          def ===: () -> void
          def =~: () -> void
          def >: () -> void
          def >=: () -> void
          def <: () -> void
          def <=: () -> void
          def <<: () -> void
          def >>: () -> void
          def +: () -> void
          def -: () -> void
          def *: () -> void
          def /: () -> void
          def %: () -> void
          def **: () -> void
          def ~: () -> void
          def +@: () -> void
          def -@: () -> void
          def []: () -> void
          def []=: () -> void
          def !: () -> void
          def !=: () -> void
          def !~: () -> void
          def `: () -> void
        end
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Class, decl
      end
    end
  end

  def test_parse_type
    assert_equal "hello", RBS::Parser.parse_type(buffer('"hello"')).literal
    assert_equal "hello", RBS::Parser.parse_type(buffer("'hello'")).literal
    assert_equal :hello, RBS::Parser.parse_type(buffer(':"hello"')).literal
    assert_equal :hello, RBS::Parser.parse_type(buffer(':hello')).literal
  end

  def test_parse_comment
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_, _, decls|
        # Hello
        #  World
        #Yes
        #
        # No
        class Foo
        end
      RBS

      assert_equal "Hello\n World\nYes\n\nNo\n", decls[0].comment.string
    end
  end

  def test_lex_error
    assert_raises do
      RBS::Parser.parse_signature(buffer("@"))
    end
  end

  def test_type_var
    RBS::Parser.parse_type(buffer("A"), variables: [:A]).tap do |type|
      assert_instance_of RBS::Types::Variable, type
    end

    RBS::Parser.parse_method_type(buffer("() -> A"), variables: [:A]).tap do |type|
      assert_instance_of RBS::Types::Variable, type.type.return_type
    end
  end

  def test_parse_global
    RBS::Parser.parse_signature(buffer(<<~RBS)).tap do |_buf, _dirs, decls|
        $日本語: String
      RBS

      decls[0].tap do |decl|
        assert_instance_of RBS::AST::Declarations::Global, decl
        assert_equal :"$日本語", decl.name
      end
    end

    names = %w($! $" $$ $& $' $* $+ $, $-0 $-F $-I $-W $-a $-d $-i $-l $-p $-v $-w $. $/ $0 $1 $2 $3 $4 $5 $6 $7 $8 $9 $: $; $< $= $> $? $@ $DEBUG $FILENAME $LOAD_PATH $LOADED_FEATURES $PROGRAM_NAME $VERBOSE $\\ $_ $` $stderr $stdin $stdout $~)

    names.each do |name|
      RBS::Parser.parse_signature(buffer("#{name}: untyped")).tap do |_, _, decls|
        decls[0].tap do |decl|
          assert_instance_of RBS::AST::Declarations::Global, decl
          assert_equal name.to_sym, decl.name
        end
      end
    end
  end

  def test_parse_error
    assert_raises RBS::ParsingError do
      RBS::Parser.parse_type(buffer('[Hello::world::t]'))
    end.tap do |exn|
      assert_equal(
        'test.rbs:1:13...1:15: Syntax error: comma delimited type list is expected, token=`::` (pCOLON2)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_signature(buffer(<<~RBS))
        interface foo
      RBS
    end.tap do |exn|
      assert_equal(
        'test.rbs:1:10...1:13: Syntax error: expected one of interface name, token=`foo` (tLIDENT)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_type(buffer('interface'))
    end.tap do |exn|
      assert_equal(
        'test.rbs:1:0...1:9: Syntax error: unexpected token for simple type, token=`interface` (kINTERFACE)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_signature(buffer(<<~RBS))
        interface _Foo
          def 123: () -> void
        end
      RBS
    end.tap do |exn|
      assert_equal(
        'test.rbs:2:6...2:9: Syntax error: unexpected token for method name, token=`123` (tINTEGER)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_signature(buffer(<<~RBS))
        interface _Foo
          def foo: () -> void |
          end
        end
      RBS
    end.tap do |exn|
      assert_equal(
        'test.rbs:3:2...3:5: Syntax error: unexpected token for method type, token=`end` (kEND)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_signature(buffer(<<~RBS))
        interface _Foo
          extend _Bar
        end
      RBS
    end.tap do |exn|
      assert_equal(
        'test.rbs:2:2...2:8: Syntax error: unexpected mixin in interface declaration, token=`extend` (kEXTEND)',
        exn.message
      )
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_signature(buffer(<<~RBS))
        type a = Array[Integer String]
      RBS
    end.tap do |exn|
      assert_equal(
        'test.rbs:1:23...1:29: Syntax error: comma delimited type list is expected, token=`String` (tUIDENT)',
        exn.message
      )
    end
  end

  def test_parse_method_type
    RBS::Parser.parse_method_type(buffer("() -> void")).tap do |method_type|
      assert_equal "", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(Integer) -> void")).tap do |method_type|
      assert_equal "Integer", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(Integer int , ) -> void")).tap do |method_type|
      assert_equal "Integer int", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(Integer, String) -> void")).tap do |method_type|
      assert_equal "Integer, String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(?Integer) -> void")).tap do |method_type|
      assert_equal "?Integer", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(?Integer i ,) -> void")).tap do |method_type|
      assert_equal "?Integer i", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(*Integer) -> void")).tap do |method_type|
      assert_equal "*Integer", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(*Integer is ,) -> void")).tap do |method_type|
      assert_equal "*Integer is", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(*Integer, String) -> void")).tap do |method_type|
      assert_equal "*Integer, String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(*Integer, String s, ) -> void")).tap do |method_type|
      assert_equal "*Integer, String s", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(Integer, ?String, *Symbol, Object) -> void")).tap do |method_type|
      assert_equal "Integer, ?String, *Symbol, Object", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(foo: String, ?bar: Symbol, **baz) -> void")).tap do |method_type|
      assert_equal "foo: String, ?bar: Symbol, **baz", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(foo, foo: String) -> void")).tap do |method_type|
      assert_equal "foo, foo: String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(?foo, ?foo: String) -> void")).tap do |method_type|
      assert_equal "?foo, ?foo: String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(`foo`: String) -> void")).tap do |method_type|
      assert_equal "`foo`: String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(?`foo`: String) -> void")).tap do |method_type|
      assert_equal "?`foo`: String", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(1) -> void")).tap do |method_type|
      assert_equal "1", method_type.type.param_to_s
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(foo + 1) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:5...1:6: Syntax error: unexpected token for function parameter name, token=`+` (tOPERATOR)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(foo: untyped, Bar) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:15...1:18: Syntax error: required keyword argument type is expected, token=`Bar` (tUIDENT)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(foo`: untyped) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:4...1:5: Syntax error: unexpected token for function parameter name, token=``` (tOPERATOR)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(?foo\": untyped) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:5...1:6: Syntax error: unexpected token for function parameter name, token=`\"` (ErrorToken)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(**untyped, ?Bar) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:13...1:16: Syntax error: optional keyword argument type is expected, token=`Bar` (tUIDENT)", exn.message
    end
  end

  def test_duplicate_keyword
    RBS::Parser.parse_method_type(buffer("(top foo, foo: top) -> void")).tap do |method_type|
      assert_equal "top foo, foo: top", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(?foo, foo: top) -> void")).tap do |method_type|
      assert_equal "?foo, foo: top", method_type.type.param_to_s
    end

    RBS::Parser.parse_method_type(buffer("(foo: top, **top foo) -> void")).tap do |method_type|
      assert_equal "foo: top, **top foo", method_type.type.param_to_s
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(foo: top, foo: top) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:11...1:14: Syntax error: duplicated keyword argument, token=`foo` (tLIDENT)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(foo: top, ?foo: top) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:12...1:15: Syntax error: duplicated keyword argument, token=`foo` (tLIDENT)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(?foo: top, foo: top) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:12...1:15: Syntax error: duplicated keyword argument, token=`foo` (tLIDENT)", exn.message
    end

    assert_raises RBS::ParsingError do
      RBS::Parser.parse_method_type(buffer("(?foo: top, ?foo: top) -> void"))
    end.tap do |exn|
      assert_equal "test.rbs:1:13...1:16: Syntax error: duplicated keyword argument, token=`foo` (tLIDENT)", exn.message
    end
  end

  def test_parse_method_type2
    RBS::Parser.parse_method_type(buffer("(foo?: String, bar!: Integer) -> void")).tap do |method_type|
      assert_equal "foo?: String, bar!: Integer", method_type.type.param_to_s
    end
  end

  def test_newline_inconsistency
    code = "module Test\r\nend"

    RBS::Parser.parse_signature(code)
  end

  def test_buffer_location
    code = buffer("type1 type2 type3")

    RBS::Parser.parse_type(code, range: 0...).tap do |type|
      assert_equal "type1", type.to_s
      assert_equal 0...5, type.location.range
    end

    RBS::Parser.parse_type(code, range: 5...).tap do |type|
      assert_equal "type2", type.to_s
      assert_equal 6...11, type.location.range
      assert_equal 1, type.location.start_line
      assert_equal 6, type.location.start_column
      assert_equal 1, type.location.end_line
      assert_equal 11, type.location.end_column
    end

    RBS::Parser.parse_type(code, range: 5...).tap do |type|
      assert_equal "type2", type.to_s
      assert_equal 6...11, type.location.range
      assert_equal 1, type.location.start_line
      assert_equal 6, type.location.start_column
      assert_equal 1, type.location.end_line
      assert_equal 11, type.location.end_column
    end

    RBS::Parser.parse_type(code, range: 6...8).tap do |type|
      assert_equal "ty", type.to_s
      assert_equal 6...8, type.location.range
      assert_equal 1, type.location.start_line
      assert_equal 6, type.location.start_column
      assert_equal 1, type.location.end_line
      assert_equal 8, type.location.end_column
    end
  end

  def test_negative_range
    assert_raises ArgumentError do
      RBS::Parser.parse_type("a", range: -2...-1)
    end
  end

  def test_parse_eof_nil
    code = buffer("type1   ")

    RBS::Parser.parse_type(code, range: 0...).tap do |type|
      assert_equal "type1", type.to_s
      assert_equal 0...5, type.location.range
    end

    RBS::Parser.parse_type(code, range: 5...).tap do |type|
      assert_nil type
    end

    RBS::Parser.parse_type(code, range: 5...8).tap do |type|
      assert_nil type
    end
  end

  def test_parse_require_eof
    RBS::Parser.parse_type("String", range: 0..., require_eof: false)
    assert_raises(RBS::ParsingError) do
      RBS::Parser.parse_type("String void", range: 0..., require_eof: true)
    end

    RBS::Parser.parse_method_type("() -> void () -> void", range: 0..., require_eof: false)
    assert_raises(RBS::ParsingError) do
      RBS::Parser.parse_method_type("() -> void () -> void", range: 0..., require_eof: true)
    end
  end

  def test_proc__untyped_function
    RBS::Parser.parse_type("^(?) -> Integer").tap do |type|
      assert_instance_of RBS::Types::UntypedFunction, type.type
    end

    RBS::Parser.parse_type("^() { (?) -> String } -> Integer").tap do |type|
      assert_instance_of RBS::Types::UntypedFunction, type.block.type
    end
  end

  def test__lex
    content = <<~RBS
      # LineComment
      class Foo[T < Integer] < Bar # Comment
      end
    RBS
    tokens = RBS::Parser._lex(buffer(content), content.length)
    assert_equal [:tLINECOMMENT, '# LineComment', 0...13], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, "\n", 13...14], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:kCLASS, 'class', 14...19], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 19...20], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tUIDENT, 'Foo', 20...23], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:pLBRACKET, '[', 23...24], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tUIDENT, 'T', 24...25], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 25...26], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:pLT, '<', 26...27], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 27...28], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tUIDENT, 'Integer', 28...35], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:pRBRACKET, ']', 35...36], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 36...37], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:pLT, '<', 37...38], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 38...39], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tUIDENT, 'Bar', 39...42], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, " ", 42...43], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tCOMMENT, '# Comment', 43...52], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, "\n", 52...53], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:kEND, 'end', 53...56], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:tTRIVIA, "\n", 56...57], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
    assert_equal [:pEOF, '', 57...57], tokens.shift.then { |t| [t[0], t[1].source, t[1].range] }
  end
end
