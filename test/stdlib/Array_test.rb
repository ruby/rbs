require_relative "test_helper"

class ArrayTest < StdlibTest
  target Array
  using hook.refinement

  def test_try_convert
    Array.try_convert([1])
    Array.try_convert("1")
  end

  def test_new
    Array.new(1)
    Array.new(1, true)
    Array.new([1,2,3])
    Array.new(3) { true }
  end

  def test_uniq
    [1, 2, 3].uniq
    [1, 2, 3].uniq { |x| x.even? }
  end

  def test_collect
    [1, 2, 3].collect
    [1, 2, 3].collect { |x| x * 2 }
  end

  def test_map
    [1, 2, 3].map
    [1, 2, 3].map { |x| x * 2 }
  end

  def test_collect!
    [1, 2, 3].collect!
    [1, 2, 3].collect! { |x| x * 2 }
  end

  def test_map!
    [1, 2, 3].map!
    [1, 2, 3].map! { |x| x * 2 }
  end
end
