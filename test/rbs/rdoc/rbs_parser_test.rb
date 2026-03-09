require "test_helper"

require "rdoc_plugin/parser"

class RDocPluginParserTest < Test::Unit::TestCase
  def parser(content)
    top_level = RDoc::TopLevel.new("a.rbs")
    top_level.store = RDoc::Store.new(RDoc::Options.new)

    RBS::RDocPlugin::Parser.new(top_level, content)
  end

  def test_class_decl_1
    parser = parser(<<~RBS)
class A
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")

    assert_instance_of RDoc::NormalClass, klass
    assert_equal "A", klass.full_name
    assert_equal "A", klass.name
    assert_equal "", klass.comment
    assert_equal "Object", klass.superclass
  end

  def test_class_decl_2
    parser = parser(<<~RBS)
# This is class A
class A[Store] < StringBuilder[Store]
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")

    assert_instance_of RDoc::NormalClass, klass
    assert_equal "A", klass.full_name
    assert_equal "A", klass.name
    assert_equal "This is class A", klass.comment.text
    assert_equal "StringBuilder", klass.superclass
  end

  def test_module_decl_1
    parser = parser(<<~RBS)
module A
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")

    assert_instance_of RDoc::NormalModule, klass
    assert_equal "A", klass.full_name
    assert_equal "A", klass.name
    assert_equal "", klass.comment
  end

  def test_module_decl_2
    parser = parser(<<~RBS)
# Test comment for module A
module A[Element] : _Each[Element]
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")

    assert_instance_of RDoc::NormalModule, klass
    assert_equal "A", klass.full_name
    assert_equal "A", klass.name
    assert_equal "Test comment for module A", klass.comment.text
  end

  def test_instance_method_1
    parser = parser(<<~RBS)
class A
  def foo: (Integer) -> void
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "foo" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "", method.comment
    assert_equal "foo(Integer) -> void", method.call_seq
  end

  def test_instance_method_with_block
    parser = parser(<<~RBS)
class A
  def foo: (Integer) { (String) -> void } -> void
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "foo" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "", method.comment
    assert_equal "foo(Integer) { (String) -> void } -> void", method.call_seq
  end

  def test_instance_method_generic
    parser = parser(<<~RBS)
class A
  def foo: [A] (Integer) { (String) -> A } -> A
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "foo" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "", method.comment
    assert_equal "foo[A] (Integer) { (String) -> A } -> A", method.call_seq
  end

  def test_instance_method_comment_and_tokens
    parser = parser(<<~RBS)
class A
  # Added comment for foo
  def foo: [A] (Integer) { (String) -> A } -> A
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "foo" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "Added comment for foo", method.comment.text
    assert_equal "foo[A] (Integer) { (String) -> A } -> A", method.call_seq
    assert_equal "# File a.rbs, line(s) 3:3\n" + "def foo: [A] (Integer) { (String) -> A } -> A", method.tokens_to_s
  end

  def test_constant_decl_1
    parser = parser(<<~RBS)
class A
  CONSTANT: Integer
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    constant = klass.constants.first

    assert_instance_of RDoc::Constant, constant
    assert_equal "CONSTANT", constant.name
    assert_equal "Integer", constant.value
    assert_equal "", constant.comment
  end

  def test_constant_decl_2
    parser = parser(<<~RBS)
class A
  # Constant comment test
  CONSTANT: ("Literal" | "Union check")
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    constant = klass.constants.first

    assert_instance_of RDoc::Constant, constant
    assert_equal "CONSTANT", constant.name
    assert_equal "\"Literal\" | \"Union check\"", constant.value
    assert_equal "Constant comment test", constant.comment.text
  end

  def test_method_alias_decl_1
    parser = parser(<<~RBS)
class A
  def foo: () -> void
  alias bar foo
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "bar" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "bar", method.name
    assert_instance_of RDoc::AnyMethod, method.is_alias_for
    assert_equal "foo", method.is_alias_for.name
    assert_nil method.is_alias_for.is_alias_for
  end

  def test_method_alias_decl_2
    parser = parser(<<~RBS)
class A
  def foo: () -> void
  alias bar foo
  alias baz bar
  alias foo dam
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    method = klass.method_list.find { |m| m.name == "baz" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "baz", method.name
    assert_instance_of RDoc::AnyMethod, method.is_alias_for
    assert_equal "bar", method.is_alias_for.name
    assert_instance_of RDoc::AnyMethod, method.is_alias_for.is_alias_for
    assert_equal "foo", method.is_alias_for.is_alias_for.name

    assert_instance_of RDoc::Alias, klass.external_aliases.first
    assert_equal "foo", klass.external_aliases.first.name
    assert_equal "dam", klass.external_aliases.first.old_name
  end

  def test_attr_decl_1
    parser = parser(<<~RBS)
class A
  attr_reader foo: Integer
  attr_writer bar: Float
  attr_accessor dam: String
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    attr_r = klass.attributes[0]
    attr_w = klass.attributes[1]
    attr_a = klass.attributes[2]

    assert_instance_of RDoc::Attr, attr_r
    assert_equal "foo", attr_r.name
    assert_equal "R", attr_r.rw
    assert_equal "", attr_r.comment

    assert_instance_of RDoc::Attr, attr_w
    assert_equal "bar", attr_w.name
    assert_equal "W", attr_w.rw
    assert_equal "", attr_w.comment

    assert_instance_of RDoc::Attr, attr_a
    assert_equal "dam", attr_a.name
    assert_equal "RW", attr_a.rw
    assert_equal "", attr_a.comment
  end

  def test_attr_decl_2
    parser = parser(<<~RBS)
class A
  # Comment 1
  attr_reader foo: Integer
  # Comment 2
  attr_writer bar: Float
  # Comment 3
  attr_accessor dam: String
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A")
    attr_r = klass.attributes[0]
    attr_w = klass.attributes[1]
    attr_a = klass.attributes[2]

    assert_instance_of RDoc::Attr, attr_r
    assert_equal "foo", attr_r.name
    assert_equal "R", attr_r.rw
    assert_equal "Comment 1", attr_r.comment.text

    assert_instance_of RDoc::Attr, attr_w
    assert_equal "bar", attr_w.name
    assert_equal "W", attr_w.rw
    assert_equal "Comment 2", attr_w.comment.text

    assert_instance_of RDoc::Attr, attr_a
    assert_equal "dam", attr_a.name
    assert_equal "RW", attr_a.rw
    assert_equal "Comment 3", attr_a.comment.text
  end

  def test_include_decl_1
    parser = parser(<<~RBS)
module D
end
class A
  module B
  end
  class C
    include B
    # Test comment
    include D
  end
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A::C")
    rdoc_include = klass.includes.first
    assert_instance_of RDoc::Include, rdoc_include
    assert_equal "A::B", rdoc_include.name
    assert_equal "", rdoc_include.comment

    rdoc_include = klass.includes[1]
    assert_instance_of RDoc::Include, rdoc_include
    assert_equal "D", rdoc_include.name
    assert_equal "Test comment", rdoc_include.comment.text
  end

  def test_extend_decl_1
    parser = parser(<<~RBS)
module D
end
class A
  module B
  end
  class C
    extend B
    # Test comment
    extend D
  end
end
RBS

    parser.scan()

    top_level = parser.top_level

    klass = top_level.find_class_or_module("A::C")
    rdoc_extend = klass.extends.first
    assert_instance_of RDoc::Extend, rdoc_extend
    assert_equal "A::B", rdoc_extend.name
    assert_equal "", rdoc_extend.comment

    rdoc_extend = klass.extends[1]
    assert_instance_of RDoc::Extend, rdoc_extend
    assert_equal "D", rdoc_extend.name
    assert_equal "Test comment", rdoc_extend.comment.text
  end
end
