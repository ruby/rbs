require "test_helper"

class RBS::TypeParsingTest < Test::Unit::TestCase
  include TestHelper

  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace

  def test_base_types
    Parser.parse_type("void").yield_self do |type|
      assert_instance_of Types::Bases::Void, type
      assert_equal "void", type.location.source
    end

    Parser.parse_type("untyped").yield_self do |type|
      assert_instance_of Types::Bases::Any, type
      assert_equal "untyped", type.location.source
    end

    Parser.parse_type("bool").yield_self do |type|
      assert_instance_of Types::Bases::Bool, type
      assert_equal "bool", type.location.source
    end

    Parser.parse_type("nil").yield_self do |type|
      assert_instance_of Types::Bases::Nil, type
      assert_equal "nil", type.location.source
    end

    Parser.parse_type("top").yield_self do |type|
      assert_instance_of Types::Bases::Top, type
      assert_equal "top", type.location.source
    end

    Parser.parse_type("bot").yield_self do |type|
      assert_instance_of Types::Bases::Bottom, type
      assert_equal "bot", type.location.source
    end

    Parser.parse_type("self").yield_self do |type|
      assert_instance_of Types::Bases::Self, type
      assert_equal "self", type.location.source
    end

    Parser.parse_type("instance").yield_self do |type|
      assert_instance_of Types::Bases::Instance, type
      assert_equal "instance", type.location.source
    end

    Parser.parse_type("class").yield_self do |type|
      assert_instance_of Types::Bases::Class, type
      assert_equal "class", type.location.source
    end

    Parser.parse_type("any").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal "any", type.location.source
    end
  end

  def test_instance
    Parser.parse_type("Object").yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Object), type.name
      assert_equal [], type.args
      assert_equal "Object", type.location.source
    end

    Parser.parse_type("::Object").yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(namespace: Namespace.root, name: :Object), type.name
      assert_equal [], type.args
      assert_equal "::Object", type.location.source
    end

    Parser.parse_type("Enumerator::Lazy").yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(namespace: Namespace.parse("Enumerator"), name: :Lazy), type.name
      assert_equal [], type.args
      assert_equal "Enumerator::Lazy", type.location.source
    end

    Parser.parse_type("::Enumerator::Lazy").yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(namespace: Namespace.parse("::Enumerator"), name: :Lazy), type.name
      assert_equal [], type.args
      assert_equal "::Enumerator::Lazy", type.location.source
    end

    Parser.parse_type("Array[untyped]").yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Array), type.name
      assert_equal [Types::Bases::Any.new(location: nil)], type.args
      assert_equal "Array[untyped]", type.location.source
    end
  end

  def test_alias
    Parser.parse_type("foo").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :foo), type.name
      assert_equal "foo", type.location.source
    end

    Parser.parse_type("::foo").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal TypeName.new(namespace: Namespace.root, name: :foo), type.name
      assert_equal "::foo", type.location.source
    end

    Parser.parse_type("Foo::foo").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal TypeName.new(namespace: Namespace.parse("Foo"), name: :foo), type.name
      assert_equal "Foo::foo", type.location.source
    end

    Parser.parse_type("::Foo::foo").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal TypeName.new(namespace: Namespace.parse("::Foo"), name: :foo), type.name
      assert_equal "::Foo::foo", type.location.source
    end

    Parser.parse_type("foo[untyped]").yield_self do |type|
      assert_instance_of Types::Alias, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :foo), type.name
      assert_equal "foo[untyped]", type.location.source
      assert_equal "foo", type.location[:name].source
      assert_equal "[untyped]", type.location[:args].source
    end
  end

  def test_interface
    Parser.parse_type("_Foo").yield_self do |type|
      assert_instance_of Types::Interface, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :_Foo), type.name
      assert_equal [], type.args
      assert_equal "_Foo", type.location.source
    end

    Parser.parse_type("::_Foo").yield_self do |type|
      assert_instance_of Types::Interface, type
      assert_equal TypeName.new(namespace: Namespace.root, name: :_Foo), type.name
      assert_equal [], type.args
      assert_equal "::_Foo", type.location.source
    end

    Parser.parse_type("Foo::_Foo").yield_self do |type|
      assert_instance_of Types::Interface, type
      assert_equal TypeName.new(namespace: Namespace.parse("Foo"), name: :_Foo), type.name
      assert_equal [], type.args
      assert_equal "Foo::_Foo", type.location.source
    end

    Parser.parse_type("::Foo::_Foo").yield_self do |type|
      assert_instance_of Types::Interface, type
      assert_equal TypeName.new(namespace: Namespace.parse("::Foo"), name: :_Foo), type.name
      assert_equal [], type.args
      assert_equal "::Foo::_Foo", type.location.source
    end

    Parser.parse_type("_Foo[untyped, nil]").yield_self do |type|
      assert_instance_of Types::Interface, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :_Foo), type.name
      assert_equal [Types::Bases::Any.new(location: nil), Types::Bases::Nil.new(location: nil)], type.args
      assert_equal "_Foo[untyped, nil]", type.location.source
    end
  end

  def test_tuple
    Parser.parse_type("[untyped, nil, void]").yield_self do |type|
      assert_instance_of Types::Tuple, type
      assert_equal [
                     Types::Bases::Any.new(location: nil),
                     Types::Bases::Nil.new(location: nil),
                     Types::Bases::Void.new(location: nil)
                   ], type.types
      assert_equal "[untyped, nil, void]", type.location.source
    end

    Parser.parse_type("[untyped]").yield_self do |type|
      assert_instance_of Types::Tuple, type
      assert_equal [Types::Bases::Any.new(location: nil)], type.types
      assert_equal "[untyped]", type.location.source
    end

    Parser.parse_type("[untyped,]").yield_self do |type|
      assert_instance_of Types::Tuple, type
      assert_equal [Types::Bases::Any.new(location: nil)], type.types
      assert_equal "[untyped,]", type.location.source
    end

    Parser.parse_type("[ ]").yield_self do |type|
      assert_instance_of Types::Tuple, type
      assert_equal [], type.types
      assert_equal "[ ]", type.location.source
    end

    Parser.parse_type("[]").yield_self do |type|
      assert_instance_of Types::Tuple, type
      assert_equal [], type.types
      assert_equal "[]", type.location.source
    end
  end

  def test_union_intersection
    Parser.parse_type("untyped | void | nil").yield_self do |type|
      assert_instance_of Types::Union, type

      assert_equal [
                     Types::Bases::Any.new(location: nil),
                     Types::Bases::Void.new(location: nil),
                     Types::Bases::Nil.new(location: nil)
                   ], type.types

      assert_equal "untyped | void | nil", type.location.source
    end

    Parser.parse_type("untyped & void & nil").yield_self do |type|
      assert_instance_of Types::Intersection, type

      assert_equal [
                     Types::Bases::Any.new(location: nil),
                     Types::Bases::Void.new(location: nil),
                     Types::Bases::Nil.new(location: nil)
                   ], type.types

      assert_equal "untyped & void & nil", type.location.source
    end

    Parser.parse_type("untyped | void & nil").yield_self do |type|
      assert_instance_of Types::Union, type
      assert_instance_of Types::Intersection, type.types[1]

      assert_equal "untyped | void & nil", type.location.source
    end

    Parser.parse_type("untyped & void | nil").yield_self do |type|
      assert_instance_of Types::Union, type
      assert_instance_of Types::Intersection, type.types[0]

      assert_equal "untyped & void | nil", type.location.source
    end

    Parser.parse_type("untyped & (void | nil)").yield_self do |type|
      assert_instance_of Types::Intersection, type
      assert_instance_of Types::Union, type.types[1]

      assert_equal "untyped & (void | nil)", type.location.source
    end
  end

  def test_class_singleton
    Parser.parse_type("singleton(Object)").yield_self do |type|
      assert_instance_of Types::ClassSingleton, type

      assert_equal TypeName.new(namespace: Namespace.empty, name: :Object), type.name

      assert_equal "singleton(Object)", type.location.source
    end

    Parser.parse_type("singleton(::Object)").yield_self do |type|
      assert_instance_of Types::ClassSingleton, type

      assert_equal TypeName.new(namespace: Namespace.root, name: :Object), type.name

      assert_equal "singleton(::Object)", type.location.source
    end

    assert_raises RBS::ParsingError do
      Parser.parse_type("singleton(foo)")
    end

    assert_raises RBS::ParsingError do
      Parser.parse_type("singleton(_FOO)")
    end
  end

  def test_proc_type
    Parser.parse_type("^() -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      assert_equal "^() -> void", type.location.source
    end

    Parser.parse_type("^(untyped) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: nil)
                   ], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped) -> void", type.location.source
    end

    Parser.parse_type("^(untyped, void) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: nil),
                     Types::Function::Param.new(type: Types::Bases::Void.new(location: nil), name: nil),
                   ], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped, void) -> void", type.location.source
    end

    Parser.parse_type("^(untyped x, void _y, bool `type`) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :x),
                     Types::Function::Param.new(type: Types::Bases::Void.new(location: nil), name: :_y),
                     Types::Function::Param.new(type: Types::Bases::Bool.new(location: nil), name: :type),
                   ], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped x, void _y, bool `type`) -> void", type.location.source
    end

    Parser.parse_type("^(untyped x, ?void, ?nil y) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :x),
                   ], fun.required_positionals
      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Void.new(location: nil), name: nil),
                     Types::Function::Param.new(type: Types::Bases::Nil.new(location: nil), name: :y),
                   ], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped x, ?void, ?nil y) -> void", type.location.source
    end

    Parser.parse_type("^(untyped x, ?void, ?nil y, *untyped a) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :x),
                   ], fun.required_positionals
      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Void.new(location: nil), name: nil),
                     Types::Function::Param.new(type: Types::Bases::Nil.new(location: nil), name: :y),
                   ], fun.optional_positionals
      assert_equal Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :a),
                   fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped x, ?void, ?nil y, *untyped a) -> void", type.location.source
    end

    Parser.parse_type("^(untyped x, *untyped a, nil z) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :x),
                   ], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_equal Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: :a),
                   fun.rest_positionals
      assert_equal [
                     Types::Function::Param.new(type: Types::Bases::Nil.new(location: nil), name: :z),
                   ], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(untyped x, *untyped a, nil z) -> void", type.location.source
    end

    Parser.parse_type("^(foo: untyped, _bar: nil bar) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({
                     foo: Types::Function::Param.new(type: Types::Bases::Any.new(location: nil), name: nil),
                     _bar: Types::Function::Param.new(type: Types::Bases::Nil.new(location: nil), name: :bar),
                   }, fun.required_keywords)
      assert_equal({}, fun.optional_keywords)
      assert_nil fun.rest_keywords

      assert_equal "^(foo: untyped, _bar: nil bar) -> void", type.location.source
    end

    Parser.parse_type("^(?_bar: nil, **untyped rest) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      fun = type.type

      assert_equal [], fun.required_positionals
      assert_equal [], fun.optional_positionals
      assert_nil fun.rest_positionals
      assert_equal [], fun.trailing_positionals
      assert_equal({}, fun.required_keywords)
      assert_equal({
                     _bar: Types::Function::Param.new(type: Types::Bases::Nil.new(location: nil), name: nil)
                   }, fun.optional_keywords)
      assert_equal Types::Function::Param.new(type: Types::Bases::Any.new(location: nil),
                                              name: :rest), fun.rest_keywords

      assert_equal "^(?_bar: nil, **untyped rest) -> void", type.location.source
    end

    Parser.parse_type("^-> void").yield_self do |type|
      assert_instance_of Types::Proc, type
    end
  end

  def test_proc_with_block
    Parser.parse_type("^() { () -> void } -> void").tap do |type|
      assert_instance_of Types::Proc, type
      assert_instance_of Types::Block, type.block
    end

    Parser.parse_type("^() { -> void } -> void").tap do |type|
      assert_instance_of Types::Proc, type
      assert_instance_of Types::Block, type.block
    end

    Parser.parse_type("^{ -> void } -> void").tap do |type|
      assert_instance_of Types::Proc, type
      assert_instance_of Types::Block, type.block
    end
  end

  def test_proc_with_self
    Parser.parse_type("^() -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      assert_equal "^() -> void", type.location.source
      assert_nil type.self_type
    end

    Parser.parse_type("^() [self: String] -> void").yield_self do |type|
      assert_instance_of Types::Proc, type

      assert_equal "^() [self: String] -> void", type.location.source
      assert_equal Parser.parse_type("String"), type.self_type
    end

    Parser.parse_type("^ { [self: String] -> void } -> void").tap do |type|
      assert_instance_of Types::Proc, type
      assert_nil type.self_type
      assert_instance_of Types::Block, type.block
      assert_equal Parser.parse_type("String"), type.block.self_type
    end
  end

  def test_untyped_proc_with_self
    Parser.parse_type("^(?) -> void").yield_self do |type|
      assert_instance_of Types::Proc, type
      assert_instance_of Types::UntypedFunction, type.type
      assert_equal "^(?) -> void", type.location.source
      assert_nil type.self_type
    end

    Parser.parse_type("^(?) [self: String] -> void").yield_self do |type|
      assert_instance_of Types::Proc, type
      assert_instance_of Types::UntypedFunction, type.type

      assert_equal "^(?) [self: String] -> void", type.location.source
      assert_equal Parser.parse_type("String"), type.self_type
    end
  end

  def test_optional
    Parser.parse_type("untyped?").yield_self do |type|
      assert_instance_of Types::Optional, type
      assert_instance_of Types::Bases::Any, type.type

      assert_equal "untyped?", type.location.source
    end

    Parser.parse_type("^() -> untyped?").yield_self do |type|
      assert_instance_of Types::Proc, type
    end

    Parser.parse_type("untyped | void?").yield_self do |type|
      assert_instance_of Types::Union, type
    end

    Parser.parse_type(":foo??").yield_self do |type|
      assert_instance_of Types::Optional, type
      assert_instance_of Types::Literal, type.type
      assert_equal :foo?, type.type.literal
    end

    Parser.parse_type(":foo!?").yield_self do |type|
      assert_instance_of Types::Optional, type
      assert_instance_of Types::Literal, type.type
      assert_equal :foo!, type.type.literal
    end

    Parser.parse_type(":foo ?").yield_self do |type|
      assert_instance_of Types::Optional, type
      assert_instance_of Types::Literal, type.type
      assert_equal :foo, type.type.literal
    end
  end

  def test_literal
    Parser.parse_type("1").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal 1, type.literal
      assert_equal "1", type.location.source
    end

    Parser.parse_type("+1").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal 1, type.literal
      assert_equal "+1", type.location.source
    end

    Parser.parse_type("-1").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal(-1, type.literal)
      assert_equal "-1", type.location.source
    end

    Parser.parse_type(":foo").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal :foo, type.literal
    end

    Parser.parse_type(":foo?").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal :foo?, type.literal
    end

    Parser.parse_type(":$foo").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal :$foo, type.literal
    end

    Parser.parse_type(":@foo").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal :@foo, type.literal
    end

    Parser.parse_type(":@@foo").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal :@@foo, type.literal
    end

    operator_symbols = %i(| ^ & <=> == === =~ > >= < <= << >> + - * / % ** ~ +@ -@ [] []= ` ! != !~)

    operator_symbols.each do |symbol|
      Parser.parse_type(symbol.inspect).yield_self do |type|
        assert_instance_of Types::Literal, type
        assert_equal symbol, type.literal
      end
    end

    assert_raises RBS::ParsingError do
      Parser.parse_type("[:+foo]")
    end

    assert_raises RBS::ParsingError do
      Parser.parse_type(":@")
    end

    Parser.parse_type("'hello world'").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "hello world", type.literal
    end

    Parser.parse_type("\"super \\\" duper\"").yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "super \" duper", type.literal
    end

    Parser.parse_type('"escape sequences \a\b\e\f\n\r\s\t\v\""').yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "escape sequences \a\b\e\f\n\r\s\t\v\"", type.literal
    end

    Parser.parse_type(%q{'not escape sequences \a\b\e\f\n\r\s\t\v\"'}).yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal 'not escape sequences \a\b\e\f\n\r\s\t\v\"', type.literal
    end

    # "\\" in RBS
    Parser.parse_type(%q{"\\\\"}).yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "\\", type.literal
    end

    # '\\' in RBS
    Parser.parse_type(%q{'\\\\'}).yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "\\", type.literal
    end
  end

  def test_literal_to_s
    Parser.parse_type(%q{"\\a\\\\"}).yield_self do |type|
      assert_equal type, Parser.parse_type(type.to_s)
    end
  end

  def test_string_literal_union
    Parser.parse_type(%q{"\\\\" | "a"}).yield_self do |type|
      assert_instance_of Types::Union, type

      assert_instance_of Types::Literal, type.types[0]
      assert_equal 1, type.types[0].literal.size
      assert_equal '\\', type.types[0].literal

      assert_instance_of Types::Literal, type.types[1]
      assert_equal "a", type.types[1].literal
    end
  end

  def test_record
    Parser.parse_type("{ foo: untyped, 3 => 'hoge' }").yield_self do |type|
      assert_instance_of Types::Record, type
      assert_equal({
                     foo: Types::Bases::Any.new(location: nil),
                     3 => Types::Literal.new(literal: "hoge", location: nil)
                   }, type.fields)
      assert_equal "{ foo: untyped, 3 => 'hoge' }", type.location.source
    end

    Parser.parse_type("{}").yield_self do |type|
      assert_instance_of Types::Record, type
      assert_equal({}, type.fields)
      assert_equal "{}", type.location.source
    end

    Parser.parse_type("{ foo: untyped, }").yield_self do |type|
      assert_instance_of Types::Record, type
      assert_equal({
                     foo: Types::Bases::Any.new(location: nil),
                   }, type.fields)
      assert_equal "{ foo: untyped, }", type.location.source
    end

    error = assert_raises(RBS::ParsingError) do
      Parser.parse_type("{ foo")
    end
    assert_equal "tLIDENT", error.token_type
    assert_equal "foo", error.location.source
    assert_equal "a.rbs:1:2...1:5: Syntax error: unexpected record key token, token=`foo` (tLIDENT)", error.message
  end

  def test_record_with_optional_key
    Parser.parse_type("{ ?foo: untyped }").yield_self do |type|
      assert_instance_of Types::Record, type
      assert_equal({}, type.fields)
      assert_equal({
                     foo: Types::Bases::Any.new(location: nil),
                   }, type.optional_fields)
      assert_equal "{ ?foo: untyped }", type.location.source
    end

    error = assert_raises(RBS::ParsingError) do
      Parser.parse_type("{ 1?: untyped }")
    end
    assert_equal "pQUESTION", error.token_type
    assert_equal "?", error.location.source
    assert_equal "a.rbs:1:3...1:4: Syntax error: expected a token `pFATARROW`, token=`?` (pQUESTION)", error.message
  end

  def test_record_with_intersection_key
    error = assert_raises(RBS::ParsingError) do
      Parser.parse_type("{ 1&2: untyped }")
    end
    assert_equal "pAMP", error.token_type
    assert_equal "&", error.location.source
    assert_equal "a.rbs:1:3...1:4: Syntax error: expected a token `pFATARROW`, token=`&` (pAMP)", error.message
  end

  def test_record_with_union_key
    error = assert_raises(RBS::ParsingError) do
      Parser.parse_type("{ 1|2: untyped }")
    end
    assert_equal "pBAR", error.token_type
    assert_equal "|", error.location.source
    assert_equal "a.rbs:1:3...1:4: Syntax error: expected a token `pFATARROW`, token=`|` (pBAR)", error.message
  end

  def test_record_key_duplication
    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ foo: Integer, foo: String }')
    end.tap do |error|
      assert_equal "tLIDENT", error.token_type
      assert_equal "foo", error.location.source
      assert_equal "a.rbs:1:16...1:19: Syntax error: duplicated record key, token=`foo` (tLIDENT)", error.message
    end

    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ foo: Integer, ?foo: String }')
    end.tap do |error|
      assert_equal "tLIDENT", error.token_type
      assert_equal "foo", error.location.source
      assert_equal "a.rbs:1:17...1:20: Syntax error: duplicated record key, token=`foo` (tLIDENT)", error.message
    end

    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ ?foo: Integer, ?foo: String }')
    end.tap do |error|
      assert_equal "tLIDENT", error.token_type
      assert_equal "foo", error.location.source
      assert_equal "a.rbs:1:18...1:21: Syntax error: duplicated record key, token=`foo` (tLIDENT)", error.message
    end

    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ foo: 1, "foo" => 2, \'foo\' => 3 }')
    end.tap do |error|
      assert_equal "tSQSTRING", error.token_type
      assert_equal "'foo'", error.location.source
      assert_equal "a.rbs:1:22...1:27: Syntax error: duplicated record key, token=`'foo'` (tSQSTRING)", error.message
    end

    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ foo: 1, \'foo\' => 2, "foo" => 3 }')
    end.tap do |error|
      assert_equal "tDQSTRING", error.token_type
      assert_equal '"foo"', error.location.source
      assert_equal "a.rbs:1:22...1:27: Syntax error: duplicated record key, token=`\"foo\"` (tDQSTRING)", error.message
    end

    assert_raises(RBS::ParsingError) do
      Parser.parse_type('{ void => 1, void: 2 }')
    end.tap do |error|
      assert_equal "kVOID", error.token_type
      assert_equal 'void', error.location.source
      assert_equal "a.rbs:1:2...1:6: Syntax error: unexpected record key token, token=`void` (kVOID)", error.message
    end
  end

  def test_type_var
    Parser.parse_type("Array[A]", variables: []).yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(name: :Array, namespace: Namespace.empty), type.name

      assert_equal 1, type.args.size
      type.args[0].yield_self do |arg|
        assert_instance_of Types::ClassInstance, arg
      end
    end

    Parser.parse_type("Array[A]", variables: [:A]).yield_self do |type|
      assert_instance_of Types::ClassInstance, type
      assert_equal TypeName.new(name: :Array, namespace: Namespace.empty), type.name

      assert_equal 1, type.args.size
      type.args[0].yield_self do |arg|
        assert_instance_of Types::Variable, arg
        assert_instance_of RBS::Location, arg.location
      end
    end

    assert_raises RBS::ParsingError do
      Parser.parse_type("(Array[A])", variables: [:A, :Array])
    end
  end

  def test_record_keywords
    keywords = %w(def class module alias type unchecked interface void nil true false any untyped top bot instance singleton private public attr_reader attr_writer attr_accessor include extend prepend extension incompatible)

    keywords.each do |k|
      Parser.parse_type("{ #{k}: Integer }").tap do |type|
        assert_instance_of Types::Record, type
        assert_equal [k.to_sym], type.fields.keys
      end
    end
  end

  def test_record_escape
    Parser.parse_type('{ `日本語`: Integer }')
    Parser.parse_type('{ `🌼`: Integer }')
  end

  def test_location_children
    Parser.parse_type("_Foo").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "_Foo", type.location[:name].source
      assert_nil type.location[:args]
    end

    Parser.parse_type("_Foo[untyped]").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "_Foo", type.location[:name].source
      assert_equal "[untyped]", type.location[:args].source
    end

    Parser.parse_type("Foo").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "Foo", type.location[:name].source
      assert_nil type.location[:args]
    end

    Parser.parse_type("Foo[untyped]").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "Foo", type.location[:name].source
      assert_equal "[untyped]", type.location[:args].source
    end

    Parser.parse_type("foo").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "foo", type.location[:name].source
      assert_nil type.location[:args]
    end

    Parser.parse_type("singleton(::Foo)").yield_self do |type|
      assert_instance_of RBS::Location, type.location

      assert_equal "::Foo", type.location[:name].source
    end
  end

  def test_untyped__todo
    Parser.parse_type("__todo__").yield_self do |type|
      assert_instance_of Types::Bases::Any, type
      assert_equal "__todo__", type.location.source
    end
  end

  def test_escape_sequences
    Parser.parse_type('"escape sequences \a\b\e\f\n\r\s\t\v\""').yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal "escape sequences \a\b\e\f\n\r\s\t\v\"", type.literal
    end

    Parser.parse_type(%q{'not escape sequences \a\b\e\f\n\r\s\t\v\"'}).yield_self do |type|
      assert_instance_of Types::Literal, type
      assert_equal 'not escape sequences \a\b\e\f\n\r\s\t\v\"', type.literal
    end

    Parser.parse_type('["\u0000", "\00", "\x00"]').yield_self do |type|
      assert_equal "\u0000", type.types[0].literal
      assert_equal "\00", type.types[1].literal
      assert_equal "\x00", type.types[2].literal
    end
  end
end
