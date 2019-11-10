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
end
