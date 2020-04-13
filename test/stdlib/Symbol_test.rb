require_relative "test_helper"
require "ruby/signature/test/test_helper"

class SymbolSingletonTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "singleton(::Symbol)"

  def test_all_symbols
    assert_send_type "() -> Array[Symbol]",
                     Symbol, :all_symbols
  end
end

class SymbolInstanceTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "::Symbol"

  def test_cmp
    assert_send_type "(Symbol) -> Integer",
                     :a, :<=>, :a
    assert_send_type "(Integer) -> nil",
                     :a, :<=>, 42
  end

  def test_eq
    assert_send_type "(Symbol) -> true",
                     :a, :==, :a
    assert_send_type "(Integer) -> false",
                     :a, :==, 42
  end

  def test_eqq
    assert_send_type "(Symbol) -> true",
                     :a, :===, :a
    assert_send_type "(Integer) -> false",
                     :a, :===, 42
  end

  def test_match_op
    assert_send_type "(Regexp) -> Integer",
                     :a, :=~, /a/
    assert_send_type "(nil) -> nil",
                     :a, :=~, nil
  end

  def test_aref
    assert_send_type "(Integer) -> String",
                     :a, :[], 0
    assert_send_type "(ToInt) -> String",
                     :a, :[], ToInt.new(0)
    assert_send_type "(Integer) -> nil",
                     :a, :[], 1
    assert_send_type "(ToInt) -> nil",
                     :a, :[], ToInt.new(1)
    assert_send_type "(Integer, Integer) -> String",
                     :a, :[], 0, 1
    assert_send_type "(Integer, Integer) -> nil",
                     :a, :[], 2, 1
    assert_send_type "(ToInt, ToInt) -> String",
                     :a, :[], ToInt.new(0), ToInt.new(1)
    assert_send_type "(ToInt, ToInt) -> nil",
                     :a, :[], ToInt.new(2), ToInt.new(1)
    assert_send_type "(Range[Integer]) -> String",
                     :a, :[], 0..1
    assert_send_type "(Range[Integer]) -> nil",
                     :a, :[], 2..1
    assert_send_type "(Range[Integer?]) -> String",
                     :a, :[], (0...)
    assert_send_type "(Range[Integer?]) -> nil",
                     :a, :[], (2...)
    assert_send_type "(Range[Integer?]) -> String",
                     :a, :[], (...0)
    assert_send_type "(Regexp) -> String",
                     :a, :[], /a/
    assert_send_type "(Regexp) -> nil",
                     :a, :[], /b/
    assert_send_type "(Regexp, Integer) -> String",
                     :a, :[], /a/, 0
    assert_send_type "(Regexp, Integer) -> nil",
                     :a, :[], /b/, 0
    assert_send_type "(Regexp, ToInt) -> String",
                     :a, :[], /a/, ToInt.new(0)
    assert_send_type "(Regexp, ToInt) -> nil",
                     :a, :[], /b/, ToInt.new(0)
    assert_send_type "(Regexp, String) -> String",
                     :a, :[], /(?<a>a)/, "a"
    assert_send_type "(Regexp, String) -> nil",
                     :a, :[], /(?<b>b)/, "b"
    assert_send_type "(String) -> String",
                     :a, :[], "a"
    assert_send_type "(String) -> nil",
                     :a, :[], "b"
  end

  def test_capitalize
    assert_send_type "() -> Symbol",
                     :a, :capitalize
    assert_send_type "(:ascii) -> Symbol",
                     :a, :capitalize, :ascii
    assert_send_type "(:lithuanian) -> Symbol",
                     :a, :capitalize, :lithuanian
    assert_send_type "(:turkic) -> Symbol",
                     :a, :capitalize, :turkic
    assert_send_type "(:lithuanian, :turkic) -> Symbol",
                     :a, :capitalize, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> Symbol",
                     :a, :capitalize, :turkic, :lithuanian
  end
end

class SymbolTest < StdlibTest
  target Symbol
  using hook.refinement

  def test_casecmp
    :a.casecmp(:A)
    :a.casecmp(:B)
    :b.casecmp(:A)
    "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym.casecmp(:"\u{c4 d6 dc}")
    :a.casecmp(42)
  end

  def test_casecmp_p
    :a.casecmp?(:A)
    :a.casecmp?(:B)
    "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym.casecmp?(:"\u{c4 d6 dc}")
    :a.casecmp?(42)
  end

  def test_downcase
    :a.downcase
    :a.downcase(:ascii)
    :a.downcase(:fold)
    :a.downcase(:lithuanian)
    :a.downcase(:turkic)
    :a.downcase(:lithuanian, :turkic)
    :a.downcase(:turkic, :lithuanian)
  end

  def test_empty_p
    :"".empty?
    :a.empty?
  end

  def test_encoding
    :a.encoding
  end

  def test_end_with?
    :a.end_with?("a")
    :a.end_with?("b")
    :a.end_with?("a", "b")
  end

  def test_id2name
    :a.id2name
  end

  def test_inspect
    :a.inspect
  end

  def test_intern
    :a.intern
  end

  def test_length
    :a.length
  end

  def test_match
    :a.match(/a/)
    :a.match(/b/)
    :a.match(/a/, 0)
    :a.match("a")
    :a.match("a", 0)
    :a.match(/a/) {|_m| }
  end

  def test_match?
    :a.match?(/a/)
    :a.match?(/b/)
    :a.match?(/a/, 0)
    :a.match?("a")
    :a.match?("a", 0)
  end

  def test_next
    :a.next
  end

  def test_size
    :a.size
  end

  def test_slice
    :a.slice(0) == "a" or raise
    :a.slice(1) == nil or raise
    :a.slice(0, 1) == "a" or raise
    :a.slice(2, 1) == nil or raise
    :a.slice(0..1) == "a" or raise
    :a.slice(2..1) == nil or raise
    :a.slice(0...) == "a" or raise
    :a.slice(2...) == nil or raise
    :a.slice(...0) == "" or raise
    :a.slice(/a/) == "a" or raise
    :a.slice(/b/) == nil or raise
    :a.slice(/a/, 0) == "a" or raise
    :a.slice(/b/, 0) == nil or raise
    :a.slice(/(?<a>a)/, "a") == "a" or raise
    :a.slice(/(?<b>b)/, "b") == nil or raise
    :a.slice("a") == "a" or raise
    :a.slice("b") == nil or raise
  end

  def test_start_with?
    :a.start_with?("a")
    :a.start_with?("b")
    :a.start_with?("b", "a")
  end

  def test_succ
    :a.succ
  end

  def test_swapcase
    :a.swapcase
    :a.swapcase(:ascii)
    :a.swapcase(:lithuanian)
    :a.swapcase(:turkic)
    :a.swapcase(:lithuanian, :turkic)
    :a.swapcase(:turkic, :lithuanian)
  end

  def test_to_proc
    :a.to_proc
  end

  def test_to_s
    :a.to_s
  end

  def test_to_sym
    :a.to_sym
  end

  def test_upcase
    :a.upcase
    :a.upcase(:ascii)
    :a.upcase(:lithuanian)
    :a.upcase(:turkic)
    :a.upcase(:lithuanian, :turkic)
    :a.upcase(:turkic, :lithuanian)
  end
end
