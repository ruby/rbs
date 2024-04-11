require_relative "test_helper"

class SetTest < Test::Unit::TestCase
  include TestHelper

  testing "::Set[::Integer]"

  def test_each
    assert_send_type(
      "() -> ::Enumerator[::Integer, ::Set[::Integer]]",
      Set[1], :each
    )

    assert_send_type(
      "() { (::Integer) -> ::Integer } -> ::Set[::Integer]",
      Set[1], :each
    ) do |x| x+1 end
  end

  def test_compare_by_identity
    assert_send_type(
      "() -> ::Set[::Integer]",
      Set[1], :compare_by_identity
    )
  end
end

class SetSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Set)"

  def test_new
    assert_send_type "() -> ::Set[untyped]", Set, :new
    assert_send_type "(nil) -> ::Set[untyped]", Set, :new, nil
    assert_send_type "(Array[Integer]) -> Set[Integer]", Set, :new, [1, 2]
    assert_send_type "(Range[Integer]) -> Set[Integer]", Set, :new, 1..5
    assert_send_type "(Array[Integer]) { (Integer) -> Integer } -> Set[Integer]",
                     Set, :new, [1, 2, 3] do |x| x * x end

    o = Object.new
    def o.each
      hash_key = BasicObject.new
      def hash_key.hash = 12345
      def hash_key.eql?(_) = true
      yield hash_key
      yield hash_key
      yield hash_key
    end
    assert_send_type "(Object & _Each[Hash::_Key]) -> Set[Hash::_Key]",
                     Set, :new, o

    o = Object.new
    def o.each
      yield BasicObject.new
      yield BasicObject.new
      yield BasicObject.new
    end
    block = proc do |x|
      hash_key = BasicObject.new
      def hash_key.hash = 12345
      def hash_key.eql?(_) = true
      hash_key
    end
    assert_send_type "(Object & _Each[BasicObject]) { (BasicObject) -> Hash::_Key } -> Set",
                     Set, :new, o, &block
  end
end
