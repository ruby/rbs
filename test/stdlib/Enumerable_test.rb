require_relative "test_helper"

class EnumerableTest < StdlibTest
  target Enumerable

  def test_find_all
    enumerable.find_all
    enumerable.find_all { |x| x.even? }
  end

  def test_filter
    enumerable.filter
    enumerable.filter { |x| x.even? }
  end

  def test_grep
    enumerable.grep(-> x { x.even? })
    enumerable.grep(-> x { x.even? }) { |x| x * 2 }
  end

  def test_grep_v
    enumerable.grep_v(-> x { x.even? })
    enumerable.grep_v(-> x { x.even? }) { |x| x * 2 }
  end

  def test_select
    enumerable.select
    enumerable.select { |x| x.even? }
  end

  def test_uniq
    enumerable.uniq
    enumerable.uniq { |x| x.even? }
  end

  def test_sum
    enumerable.sum
    enumerable.sum { |x| x * 2 }
    enumerable.sum(0)
    enumerable.sum('') { |x| x.to_s }
  end

  if Enumerable.public_method_defined?(:filter_map)
    def test_filter_map
      enumerable.filter_map
      enumerable.filter_map { |x| x.even? && x * 2 }
    end
  end

  def test_chain
    enumerable.chain
    enumerable.chain([4, 5])
  end

  def test_take
    enumerable.take(10)
    enumerable.take(0)
  end

  if Enumerable.public_method_defined?(:tally)
    def test_tally
      enumerable.tally
    end
  end

  def test_to_h
    enumerable = Class.new {
      def each
        yield [1, 2]
        yield [2, 3]
        yield [3, 4]
      end

      include Enumerable
    }.new
    enumerable.to_h
    enumerable.to_h { |obj| obj }
  end

  def test_each_entry
    enumerable.each_entry
    enumerable.each_entry { |x| x }
  end

  def test_zip
    enumerable.zip([4,5,6])
    enumerable.zip([4,5,6]) { |arr| arr.sum }
  end

  def test_chunk
    enumerable.chunk
    enumerable.chunk { |x| x.even? }
  end

  def test_chunk_while
    enumerable.chunk_while { |elt_before, elt_after| (elt_before & elt_after).zero? }
  end

  def test_slice_when
    enumerable.slice_when { |elt_before, elt_after| (elt_before & elt_after).zero? }
  end

  def test_slice_after
    enumerable.slice_after(1)
    enumerable.slice_after { |elt| elt.even? }
  end

  def test_slice_before
    enumerable.slice_before(1)
    enumerable.slice_before { |elt| elt.even? }
  end

  private

  def enumerable
    Class.new {
      def each
        yield 1
        yield 2
        yield 3
      end

      include Enumerable
    }.new
  end
end

class EnumerableTest2 < Test::Unit::TestCase
  include TypeAssertions

  class TestEnumerable
    include Enumerable

    def each
      yield '1'
      yield '2'
      yield '3'
      self
    end
  end

  testing "::Enumerable[String]"

  def test_inject
    assert_send_type "(String init, Symbol method) -> untyped", TestEnumerable.new, :inject, '', :<<
    assert_send_type "(Symbol method) -> String", TestEnumerable.new, :inject, :+
    assert_send_type("(Integer initial) { (Integer, String) -> Integer } -> Integer", TestEnumerable.new, :inject, 0) do |memo, item|
      memo ^ item.hash
    end
    assert_send_type("() { (String, String) -> String } -> String", TestEnumerable.new, :inject) do |memo, item|
      memo + item
    end
  end
end
