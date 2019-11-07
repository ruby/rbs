class EnumerableTest < StdlibTest
  target Enumerable
  using hook.refinement

  def test_grep_v
    [1, 2, 3].grep_v(-> x { x.even? })
    [1, 2, 3].grep_v(-> x { x.even? }) { |x| x * 2 }
  end
end
