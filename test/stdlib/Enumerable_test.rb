class EnumerableTest < StdlibTest
  target Enumerable
  using hook.refinement

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
