require_relative "test_helper"

class HashTest < StdlibTest
  target Hash
  using hook.refinement

  # test_<
  def test_less_than
    { a: 1 } < { a: 1, b: 2 }
  end

  # test_<=
  def test_less_than_equal
    { a: 1 } <= { a: 1, b: 2 }
  end

  # test_>
  def test_greater_than
    { a: 1 } > { a: 1, b: 2 }
  end

  # test_>=
  def test_greater_than_equal
    { a: 1 } >= { a: 1, b: 2 }
  end

  def test_compact
    { a: nil }.compact
  end

  def test_compact!
    { a: nil }.compact!
    { a: 1 }.compact!
  end

  def test_each
    h = { a: 123 }

    h.each do |k, v|
      # nop
    end

    h.each do |x|
      # nop
    end

    h.each.each do |x, y|
      #
    end
  end

  def test_filter
    { a: 1, b: 2 }.filter
    { a: 1, b: 2 }.filter { |k, v| v == 1 }
  end

  def test_filter!
    { a: 1 }.filter!
    { a: 1 }.filter! { |k, v| v == 0 }
    { a: 1 }.filter! { |k, v| v == 1 }
  end

  def test_flatten
    h = { a: 1, b: 2 }
    h.flatten
    h.flatten(2)
  end

  def test_to_proc
    { a: 1 }.to_proc.call(:a)
  end

  def test_replace
    { a: 1 }.replace({ b: 2 })
  end

  def test_select
    h = { a: 1 }
    h.filter
    h.filter { |k, v| v == 1 }
  end

  def test_select!
    { a: 1 }.select!
    { a: 1 }.select! { |k, v| v == 0 }
    { a: 1 }.select! { |k, v| v == 1 }
  end
end
