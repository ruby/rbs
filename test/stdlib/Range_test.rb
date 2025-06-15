require_relative "test_helper"

class RangeTest < StdlibTest
  target Range

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
    (0...ary.size).bsearch
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

  def test_inspect
    (1..10).inspect
    ('A'...'Z').inspect
    (1..).inspect
  end

  def test_last
    (1..10).last
    (1..10).last(3)
    ('A'...'Z').last
  end

  def test_percent
    (1..10).%(2)
    if_ruby(..."3.4.0", skip: false) do
      ('A'...'Z').%(2) { |s| s.downcase }
    end
  end

  def test_size
    (1..10).size
    ('A'...'Z').size
    (1..).size
  end

  def test_step
    (1..10).step
    (1..10).step(2)

    if_ruby(..."3.4.0", skip: false) do
      ('A'...'Z').step { |s| s.downcase }
      ('A'...'Z').step(2) { |s| s.downcase }
    end

    if_ruby("3.4.0"..., skip: false) do
      ('A'...'AAA').step('A') { |s| s.downcase }
    end
  end

  def test_to_s
    (1..10).to_s
    ('A'...'Z').to_s
    (1..).to_s
  end

  def test_eql?
    (1..10).eql?(1..10)
    (1..10).eql?(1)
    ('A'...'Z').eql?('a'...'z')
    (1..).eql?(1..Float::INFINITY)
  end

  def test_member?
    (1..10).member?(5)
    ('A'...'Z').member?('AB')
    (1..).member?(-2)
  end
end

class RangeInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Range[::Integer]"

  def test_overlap?
    assert_send_type(
      "(::Range[::Integer]) -> bool",
      (2..5), :overlap?, (3..4)
    )
  end

  def test_min
    assert_send_type "() -> ::Integer", (1..4), :min
    assert_send_type "() -> nil", (4..1), :min
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> ::Integer", (1..4), :min do |a, b| a <=> b end
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> nil", (4..1), :min do |a, b| a <=> b end
    assert_send_type "(::Integer) -> ::Array[::Integer]", (1..4), :min, 2
    assert_send_type "(::Integer) { (::Integer, ::Integer) -> ::Integer } -> ::Array[::Integer]", (1..4), :min, 0 do |a, b| a <=> b end
  end

  def test_max
    assert_send_type "() -> ::Integer", (1..4), :max
    assert_send_type "() -> nil", (4..1), :max
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> ::Integer", (1..4), :max do |a, b| a <=> b end
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> nil", (4..1), :max do |a, b| a <=> b end
    assert_send_type "(::Integer) -> ::Array[::Integer]", (1..4), :max, 2
    assert_send_type "(::Integer) { (::Integer, ::Integer) -> ::Integer } -> ::Array[::Integer]", (4..1), :max, 0 do |a, b| a <=> b end
  end

  def test_minmax
    assert_send_type "() -> [::Integer, ::Integer]", (1..4), :minmax
    assert_send_type "() -> [nil, nil]", [], :minmax
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> [::Integer, ::Integer]", (1..4), :minmax do |a, b| a.size <=> b.size end
    assert_send_type "() { (::Integer, ::Integer) -> ::Integer } -> [nil, nil]", [], :minmax do |a, b| a <=> b end
  end
end
