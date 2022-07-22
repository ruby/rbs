require "test_helper"

require "tempfile"

require "rdoc/parser/rbs"

class RBSParserTest < Test::Unit::TestCase
  def parser(content)
    top_level = RDoc::TopLevel.new("a.rbs")
    top_level.store = RDoc::Store.new()

    RBS::RDocPlugin::RBSParser.new(top_level, content)
  end

  def teardown
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
    method = klass.method_list.find {|m| m.name == "foo" }

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
    method = klass.method_list.find {|m| m.name == "foo" }

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
    method = klass.method_list.find {|m| m.name == "foo" }

    assert_instance_of RDoc::AnyMethod, method
    assert_equal "", method.comment
    assert_equal "foo[A] (Integer) { (String) -> A } -> A", method.call_seq
  end
end
