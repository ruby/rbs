require "test_helper"

class RBS::SingletonTypeTest < Test::Unit::TestCase
  include TestHelper

  Parser = RBS::Parser
  Buffer = RBS::Buffer
  Types = RBS::Types
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace

  def test_singleton_type_with_arguments
    Parser.parse_type("singleton(Array)[String]").yield_self do |type|
      assert_instance_of Types::ClassSingleton, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Array), type.name
      assert_equal 1, type.args.size
      assert_instance_of Types::ClassInstance, type.args[0]
      assert_equal TypeName.new(namespace: Namespace.empty, name: :String), type.args[0].name
      assert_equal "singleton(Array)[String]", type.location.source
    end

    Parser.parse_type("singleton(Hash)[Symbol, Integer]").yield_self do |type|
      assert_instance_of Types::ClassSingleton, type
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Hash), type.name
      assert_equal 2, type.args.size
      assert_instance_of Types::ClassInstance, type.args[0]
      assert_instance_of Types::ClassInstance, type.args[1]
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Symbol), type.args[0].name
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Integer), type.args[1].name
      assert_equal "singleton(Hash)[Symbol, Integer]", type.location.source
    end

    Parser.parse_type("singleton(::Foo::Bar)[Baz]").yield_self do |type|
      assert_instance_of Types::ClassSingleton, type
      assert_equal TypeName.new(namespace: Namespace.parse("::Foo"), name: :Bar), type.name
      assert_equal 1, type.args.size
      assert_instance_of Types::ClassInstance, type.args[0]
      assert_equal TypeName.new(namespace: Namespace.empty, name: :Baz), type.args[0].name
      assert_equal "singleton(::Foo::Bar)[Baz]", type.location.source
    end
  end

  def test_singleton_type_equality
    type1 = parse_type("singleton(Array)[String]")
    type2 = parse_type("singleton(Array)[String]")
    type3 = parse_type("singleton(Array)[Integer]")
    type4 = parse_type("singleton(Hash)[String]")

    assert_equal type1, type2
    refute_equal type1, type3
    refute_equal type1, type4
  end

  def test_singleton_type_hash
    type1 = parse_type("singleton(Array)[String]")
    type2 = parse_type("singleton(Array)[String]")
    type3 = parse_type("singleton(Array)[Integer]")

    assert_equal type1.hash, type2.hash
    refute_equal type1.hash, type3.hash
  end

  def test_singleton_type_sub
    type = parse_type("singleton(Array)[T]", variables: [:T])
    subst = RBS::Substitution.build([:T], [parse_type("String")])

    result = type.sub(subst)
    assert_instance_of Types::ClassSingleton, result
    assert_equal TypeName.new(namespace: Namespace.empty, name: :Array), result.name
    assert_equal 1, result.args.size
    assert_instance_of Types::ClassInstance, result.args[0]
    assert_equal TypeName.new(namespace: Namespace.empty, name: :String), result.args[0].name
  end

  def test_singleton_type_map_type_name
    type = parse_type("singleton(Array)[String]")

    mapped = type.map_type_name do |name, _, _|
      TypeName.new(namespace: Namespace.empty, name: :List)
    end

    assert_instance_of Types::ClassSingleton, mapped
    assert_equal TypeName.new(namespace: Namespace.empty, name: :List), mapped.name
    assert_equal 1, mapped.args.size
    assert_instance_of Types::ClassInstance, mapped.args[0]
    assert_equal TypeName.new(namespace: Namespace.empty, name: :List), mapped.args[0].name
  end
end
