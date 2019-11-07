class EnumerableTest < StdlibTest
  target Enumerable
  using hook.refinement

  def test_grep
    [1, 2, 3].grep(-> x { x.even? })
    [1, 2, 3].grep(-> x { x.even? }) { |x| x * 2 }
  end

  def test_grep_v
    [1, 2, 3].grep_v(-> x { x.even? })
    [1, 2, 3].grep_v(-> x { x.even? }) { |x| x * 2 }
  end
end
