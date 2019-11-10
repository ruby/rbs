class RangeTest < StdlibTest
  target Range
  using hook.refinement

  def test_new
    Range.new(1, 10)
    Range.new(11, 20, true)
    Range.new('a', 'z', false)
    Range.new(-1, nil)
  end
end
