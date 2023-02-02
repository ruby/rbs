require "test_helper"
require "json_validator"

class RBS::SchemaTest < Test::Unit::TestCase
  include TestHelper

  def test_location_schema
    JSONValidator.location.validate!(
      {
        start: {
          line: 1,
          column: 0
        },
        end: {
          line: 10,
          column: 0
        },
        buffer: {
          name: "hello.rbs"
        }
      }
    )
  end

  def test_comment_schema
    JSONValidator.comment.validate!(
      {
        string: "hello",
        location: {
          start: {
            line: 1,
            column: 0
          },
          end: {
            line: 10,
            column: 0
          },
          buffer: {
            name: "hello.rbs"
          }
        }
      }
    )
  end

  def assert_type(type, name = nil)
    type = parse_type(type) if type.is_a?(String)

    if name
      JSONValidator.types.validate!(
        type.to_json,
        fragment: "#/definitions/#{name}"
      )
    end

    JSONValidator.types.validate!(type.to_json)
  end

  def refute_type(type, name)
    type = parse_type(type) if type.is_a?(String)

    refute JSONValidator.types.validate(
      type.to_json,
      fragment: name ? "#/definitions/#{name}" : nil
    )
  end

  def assert_decl(decl, name = nil)
    JSONValidator.decls.validate!(decl.to_json)

    if name
      JSONValidator.decls.validate!(
        decl.to_json,
        fragment: "#/definitions/#{name}"
      )
    end
  end

  def test_type_schema
    assert_type "::Integer", "classInstance"
    assert_type "::Integer[u]", "classInstance"
    refute_type "nil", "classInstance"

    assert_type "void", "base"
    assert_type "bool", "base"
    assert_type "untyped", "base"
    assert_type "nil", "base"

    assert_type parse_type("X", variables: [:X]), "variable"
    refute_type parse_type("X"), "variable"

    assert_type parse_type("singleton(::Array)"), "classSingleton"
    refute_type parse_type("::Array"), "classSingleton"

    assert_type parse_type("string"), "alias"
    refute_type parse_type("Foo"), "alias"

    assert_type parse_type("[Integer]"), "tuple"
    refute_type parse_type("Foo"), "tuple"

    assert_type parse_type("{ id: Integer, name: String }"), "record"

    assert_type parse_type("string?"), "optional"
    refute_type parse_type("string"), "optional"

    assert_type parse_type("Foo | Bar"), "union"
    refute_type parse_type("Foo & Bar"), "union"

    assert_type parse_type("Foo & Bar"), "intersection"
    refute_type parse_type("Foo | Bar"), "intersection"

    assert_type parse_type("^() -> void"), "proc"
    refute_type parse_type("string?"), "proc"

    assert_type parse_type("30"), "literal"
    assert_type parse_type(":foo"), "literal"
  end

  def test_method_type_schema
    JSONValidator.method_type.validate!(
      parse_method_type("[G] (A a, ?B, *C, d: D, ?e: E e, **f) ?{ (G) -> void } -> String").to_json
    )
  end

  def test_decls
    assert_decl RBS::Parser.parse_signature("type Steep::foo = untyped")[2][0], :alias
    assert_decl RBS::Parser.parse_signature("type Steep::foo[A] = A")[2][0], :alias

    assert_decl RBS::Parser.parse_signature('Steep::VERSION: "1.2.3"')[2][0], :constant

    assert_decl RBS::Parser.parse_signature('$SIZE: Integer?')[2][0], :global
  end

  def assert_member(member, name=nil)
    if name
      JSONValidator.members.validate!(
        member.to_json,
        fragment: "#/definitions/#{name}"
      )
    end

    JSONValidator.members.validate!(member.to_json)
  end

  def test_members
    members = RBS::Parser.parse_signature(<<EOF)[2][0].members
class Foo
  # Hello
  %a{foo:bar:baz}
  def self?.foo: () -> Integer

  @foo: Integer
  self.@bar: String
  @@baz: Symbol

  include Foo
  extend _Baz
  prepend Bar[Integer, String]

  attr_reader name: String
  attr_accessor age (@age): Integer
  attr_writer email(): String?

  private
  public

  alias foo bar
  alias self.foo self.bar
end
EOF

    assert_member members[0], :methodDefinition

    assert_member members[1], :variable
    assert_member members[2], :variable
    assert_member members[3], :variable

    assert_member members[4], :include
    assert_member members[5], :extend
    assert_member members[6], :prepend

    assert_member members[7], :attribute
    assert_member members[8], :attribute
    assert_member members[9], :attribute

    assert_member members[10], :visibility
    assert_member members[11], :visibility

    assert_member members[12], :alias
    assert_member members[13], :alias
  end

  def test_class_decl
    _, _, (decl, *_) = RBS::Parser.parse_signature(<<EOF)
class Foo[A] < String
  # Hello
  %a{foo:bar:baz}
  def self?.foo: () -> Integer

  @foo: Integer
  self.@bar: String
  @@baz: Symbol

  include Foo
  extend _Baz
  prepend Bar[Integer, String]

  attr_reader name: String
  attr_accessor age (@age): Integer
  attr_writer email(): String?

  private
  public

  alias foo bar
  alias self.foo self.bar
end
EOF

    assert_decl decl, :class
  end

  def test_module_decl
    _, _, (decl, *_) = RBS::Parser.parse_signature(<<EOF)
module Enumerable[A, unchecked out B] : _Each[A, B]
  # Hello
  %a{foo:bar:baz}
  def self?.foo: () -> Integer

  @foo: Integer
  self.@bar: String
  @@baz: Symbol

  include Foo
  extend _Baz
  prepend Bar[Integer, String]

  attr_reader name: String
  attr_accessor age (@age): Integer
  attr_writer email(): String?

  private
  public

  alias foo bar
  alias self.foo self.bar
end
EOF

    assert_decl decl, :module
  end

  def test_interface_decl
    _, _, (decl, *_) = RBS::Parser.parse_signature(<<EOF)
interface _Hello
  # Hello
  %a{foo:bar:baz}
  def foo: () -> Integer

  include _Foo
end
EOF

    assert_decl decl, :interface
  end

  def test_nested
    _, _, (decl, *_) = RBS::Parser.parse_signature(<<EOF)
module RBS
  VERSION: String

  class Namespace
  end
end
EOF

    assert_decl decl, :module
  end
end
