require "test_helper"

class RBS::LocatorTest < Test::Unit::TestCase
  include RBS
  include TestHelper

  def locator(src)
    decls = Parser.parse_signature(src)
    Locator.new(decls: decls)
  end

  def test_find_class
    locator = locator(<<RBS)
class Foo[A] < Array[A]

end
RBS

    locator.find(line: 2, column: 0).tap do |cs|
      assert_equal 1, cs.size
      assert_instance_of AST::Declarations::Class, cs[0]
    end

    locator.find(line: 1, column: 2).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :keyword, cs[0]
      assert_instance_of AST::Declarations::Class, cs[1]
    end

    locator.find(line: 1, column: 8).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::Declarations::Class, cs[1]
    end

    locator.find(line: 1, column: 9).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :type_params, cs[0]
      assert_instance_of AST::Declarations::Class, cs[1]
    end

    locator.find(line: 1, column: 10).tap do |cs|
      assert_equal 3, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::TypeParam, cs[1]
      assert_instance_of AST::Declarations::Class, cs[2]
    end

    locator.find(line: 1, column: 18).tap do |cs|
      assert_equal 3, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::Declarations::Class::Super, cs[1]
      assert_instance_of AST::Declarations::Class, cs[2]
    end
  end

  def test_find_module
    locator = locator(<<RBS)
module Foo[A] : Array[A], _Foo

end
RBS

    locator.find(line: 2, column: 0).tap do |cs|
      assert_equal 1, cs.size
      assert_instance_of AST::Declarations::Module, cs[0]
    end

    locator.find(line: 1, column: 1).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :keyword, cs[0]
      assert_instance_of AST::Declarations::Module, cs[1]
    end

    locator.find(line: 1, column: 8).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::Declarations::Module, cs[1]
    end

    locator.find(line: 1, column: 11).tap do |cs|
      assert_equal 3, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::TypeParam, cs[1]
      assert_instance_of AST::Declarations::Module, cs[2]
    end

    locator.find(line: 1, column: 25).tap do |cs|
      assert_equal 2, cs.size
      assert_equal :self_types, cs[0]
      assert_instance_of AST::Declarations::Module, cs[1]
    end

    locator.find(line: 1, column: 27).tap do |cs|
      assert_equal 3, cs.size
      assert_equal :name, cs[0]
      assert_instance_of AST::Declarations::Module::Self, cs[1]
      assert_instance_of AST::Declarations::Module, cs[2]
    end
  end

  def test_find_upper_bound
    locator = locator(<<RBS)
module Foo[A < Baz]
  def bar: [X < Numeric] () -> X
end
RBS

    locator.find(line: 1, column: 17).tap do |cs|
      assert_equal 4, cs.size
      assert_equal :name, cs[0]
      assert_instance_of Types::ClassInstance, cs[1]
      assert_instance_of AST::TypeParam, cs[2]
      assert_instance_of AST::Declarations::Module, cs[3]
    end

    locator.find(line: 2, column: 18).tap do |cs|
      assert_equal 6, cs.size
      assert_equal :name, cs[0]
      assert_instance_of Types::ClassInstance, cs[1]
      assert_instance_of AST::TypeParam, cs[2]
      assert_instance_of MethodType, cs[3]
      assert_instance_of AST::Members::MethodDefinition, cs[4]
      assert_instance_of AST::Declarations::Module, cs[5]
    end
  end
end
