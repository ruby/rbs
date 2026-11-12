require_relative "test_helper"

class EnumeratorTest < Test::Unit::TestCase
  include TestHelper

  testing "::Enumerator[::Integer, Array[::Integer]]"

  def test_map
    g = [1,2,3].to_enum
    assert_send_type "() { (Integer) -> String } -> Array[String]",
                     g, :map do |x| x.to_s end
    assert_send_type "() -> Enumerator[Integer, Array[untyped]]",
                     g, :map
  end

  def test_with_object
    g = [1,2,3].to_enum
    assert_send_type "(String) -> Enumerator[[Integer, String], String]", g, :with_object, ''
    assert_send_type "(String) { (Integer, String) -> untyped } -> String", g, :with_object, '' do end
  end

  def test_each
    enum = Enumerator.new { [1,2,3] }
    assert_send_type "() { (Integer) -> nil } -> [1,2,3]",
                     enum, :each do end
  end

  def test_plus
    assert_send_type "(Array[Integer]) -> Enumerator::Chain[Integer]", (1..3).each, :+, [4, 5]
  end
end

class EnumeratorSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Enumerator)"

  def test_new
    assert_send_type "() { (Enumerator::Yielder) -> 12345 } -> Enumerator[untyped, 12345]",
                     Enumerator, :new do 12345 end
  end

  def test_produce
    assert_send_type(
      "(Integer initial) { (Integer) -> Integer } -> Enumerator[Integer, bot]",
      Enumerator, :produce, 1, &:succ
    )
  end

  def test_product
    assert_send_type(
      "(Array[String], Array[Integer]) -> Enumerator::Product[String | Integer]",
      Enumerator, :product, ["a", "b"], [1, 2]
    )

    assert_send_type "(Range[Integer], Array[Integer]) { (Array[Integer]) -> void } -> nil",
                     Enumerator, :product, 1..3, [1, 2] do end
  end
end

class EnumeratorYielderTest < Test::Unit::TestCase
  include TestHelper

  testing "::Enumerator::Yielder"

  def test_ltlt
    Enumerator.new do |y|
      assert_send_type "(untyped) -> void",
                       y, :<<, 1
    end.next
  end

  def test_yield
    Enumerator.new do |y|
      assert_send_type "() -> void",
                       y, :yield
    end.next

    Enumerator.new do |y|
      assert_send_type "(untyped) -> void",
                       y, :yield, 1
    end.next

    Enumerator.new do |y|
      assert_send_type "(untyped, untyped) -> void",
                       y, :yield, 1, 2
    end.next
  end

  def test_to_proc
    Enumerator.new do |y|
      assert_send_type "() -> Proc",
                       y, :to_proc
      y << 42 # To avoid StopIteration error
    end.next
  end
end

class EnumeratorLazyInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Enumerator::Lazy[::Integer, ::Range[Integer]]"

  def test_eager
    assert_send_type "() -> Enumerator[Integer, Range[Integer]]", (1..3).lazy, :eager
  end

  def test_chunk
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[[bool, Array[Integer]]]",
                     (1..3).lazy, :chunk do |i| i.odd? end
  end

  def test_chunk_while
    assert_send_type "() { (Integer, Integer) -> bool } -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :chunk_while do |i, j| i + 1 == j end
  end

  def test_collect
    assert_send_type "() { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :collect do |i| i.to_s end
  end

  def test_collect_concat
    assert_send_type "() { (Integer) -> Array[String] } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :collect_concat do |i| [i.to_s] end
    assert_send_type "() { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :collect_concat do |i| i.to_s end
  end

  def test_drop
    with_int(1) do |n|
      assert_send_type "(int) -> Enumerator::Lazy[Integer]",
                       (1..3).lazy, :drop, n
    end
  end

  def test_drop_while
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :drop_while do |i| i.odd? end
  end

  def test_filter
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :filter do |i| i.odd? end
  end

  def test_filter_map
    assert_send_type "() { (Integer) -> String? } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :filter_map do |i| i.to_s if i.odd? end
  end

  def test_find_all
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :find_all do |i| i.odd? end
  end

  def test_flat_map
    assert_send_type "() { (Integer) -> Array[String] } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :flat_map do |i| [i.to_s] end
    assert_send_type "() { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :flat_map do |i| i.to_s end
  end

  def test_force
    assert_send_type "() -> Array[Integer]",
                     (1..3).lazy, :force
  end

  def test_grep
    assert_send_type "(Range[Integer]) -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :grep, 1..2
    assert_send_type "(Range[Integer]) { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :grep, 1..2 do |i| i.to_s end
  end

  def test_grep_v
    assert_send_type "(Range[Integer]) -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :grep_v, 1..2
    assert_send_type "(Range[Integer]) { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :grep_v, 1..2 do |i| i.to_s end
  end

  def test_lazy
    assert_send_type "() -> Enumerator::Lazy[Integer, Range[Integer]]",
                     (1..3).lazy, :lazy
  end

  def test_map
    assert_send_type "() { (Integer) -> String } -> Enumerator::Lazy[String]",
                     (1..3).lazy, :map do |i| i.to_s end
  end

  def test_reject
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :reject do |i| i.odd? end
  end

  def test_select
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :select do |i| i.odd? end
  end

  def test_slice_after
    assert_send_type "(Integer) -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :slice_after, 2
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :slice_after do |i| i.even? end
  end

  def test_slice_before
    assert_send_type "(Integer) -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :slice_before, 2
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :slice_before do |i| i.even? end
  end

  def test_slice_when
    assert_send_type "() { (Integer, Integer) -> bool } -> Enumerator::Lazy[Array[Integer]]",
                     (1..3).lazy, :slice_when do |i, j| i + 1 != j end
  end

  def test_take
    with_int(2) do |n|
      assert_send_type "(int) -> Enumerator::Lazy[Integer]",
                       (1..3).lazy, :take, n
    end
  end

  def test_take_while
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :take_while do |i| i.odd? end
  end

  def test_uniq
    assert_send_type "() -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :uniq
    assert_send_type "() { (Integer) -> bool } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :uniq do |i| i.odd? end
  end

  def test_with_index
    assert_send_type "() -> Enumerator::Lazy[[Integer, Integer]]",
                     (1..3).lazy, :with_index
    assert_send_type "(Integer) -> Enumerator::Lazy[[Integer, Integer]]",
                     (1..3).lazy, :with_index, 1
    assert_send_type "(nil) -> Enumerator::Lazy[[Integer, Integer]]",
                     (1..3).lazy, :with_index, nil
    assert_send_type "() { (Integer, Integer) -> void } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :with_index do |i, j| end
    assert_send_type "(Integer) { (Integer, Integer) -> void } -> Enumerator::Lazy[Integer]",
                     (1..3).lazy, :with_index, 1 do |i, j| end
  end

  def test_zip
    assert_send_type "(Array[String]) -> Enumerator::Lazy[[Integer, String?]]",
                     (1..3).lazy, :zip, ["a"]
    assert_send_type "(Each[String]) -> Enumerator::Lazy[[Integer, String?]]",
                     (1..3).lazy, :zip, Each.new("a")
    assert_send_type "(Array[String], Array[Symbol]) -> Enumerator::Lazy[Array[untyped]]",
                     (1..3).lazy, :zip, ["a"], [:b]
    assert_send_type "(Array[String]) { ([Integer, String?]) -> void } -> nil",
                     (1..3).lazy, :zip, ["a"] do end
  end
end

class EnumeratorChainInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Enumerator::Chain[::Integer]"

  def test_each
    enum = Enumerator::Chain.new 1..3, [4, 5]
    assert_send_type "() { (Integer) -> nil } -> Enumerator::Chain[Integer]",
                     enum, :each do end
  end
end

class EnumeratorChainSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Enumerator::Chain)"

  def test_class_new
    assert_send_type "(Range[Integer], Array[Integer]) -> Enumerator::Chain[Integer]",
                     Enumerator::Chain, :new, 1..3, [4, 5]
  end
end
