class RangeTest < StdlibTest
  target Range
  using hook.refinement

  def test_new
    Range.new(1, 10)
    Range.new(11, 20, true)
    Range.new('a', 'z', false)
    Range.new(-1, nil)
  end

  def test_begin
    (1..10).begin
    ('A'...'Z').begin
    (1..).begin
  end

  def test_bsearch
    ary = [0, 4, 7, 10, 12]
    (0...ary.size).bsearch { |i| ary[i] >= 4 }
    (0..).bsearch { |x| x <= 1 }
  end

  def test_cover?
    (1..10).cover?(1)
    ('a'...'z').cover?('z')
    (10..).cover?(nil)
    (Time.new(2019,12,24)..Time.new(2020,1,5)).include?(Time.new(2020,1,1,10,10,10))
  end

  def test_each
    (1..10).each do |i|
      # nop
    end

    ('a'..'z').each { |s| s }
  end

  def test_end
    (1..10).end
    ('A'...'Z').end
    (1..).end
  end

  def test_exclude_end?
    (1..10).exclude_end?
    ('A'...'Z').exclude_end?
    (1..).exclude_end?
  end

  def test_first
    (1..10).first
    ('A'...'Z').first(3)
    (1..).first(0)
  end

  def test_hash
    (1..10).hash
    ('A'...'Z').hash
    (1..).hash
  end

  def test_include?
    (1..10).include?(5)
    ('A'...'Z').include?('AB')
    (1..).include?(-2)
  end
end
