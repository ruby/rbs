require_relative "test_helper"

class SymbolSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Symbol)"

  def test_all_symbols
    assert_send_type "() -> Array[Symbol]",
                     Symbol, :all_symbols
  end
end

class SymbolInstanceTest < Test::Unit::TestCase
  include TypeAssertions

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

  def test_casecmp
    assert_send_type "(Symbol) -> 0",
                     :a, :casecmp, :A
    assert_send_type "(Symbol) -> -1",
                     :a, :casecmp, :B
    assert_send_type "(Symbol) -> 1",
                     :b, :casecmp, :A
    assert_send_type "(Symbol) -> nil",
                     "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym, :casecmp, :"\u{c4 d6 dc}"
    assert_send_type "(Integer) -> nil",
                     :a, :casecmp, 42
  end

  def test_casecmp_p
    assert_send_type "(Symbol) -> true",
                     :a, :casecmp?, :A
    assert_send_type "(Symbol) -> false",
                     :a, :casecmp?, :B
    assert_send_type "(Symbol) ->nil",
                     "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym, :casecmp?, :"\u{c4 d6 dc}"
    assert_send_type "(Integer) -> nil",
                     :a, :casecmp?, 42
  end

  def test_downcase
    assert_send_type "() -> Symbol",
                     :a, :downcase
    assert_send_type "(:ascii) -> Symbol",
                     :a, :downcase, :ascii
    assert_send_type "(:fold) -> Symbol",
                     :a, :downcase, :fold
    assert_send_type "(:lithuanian) -> Symbol",
                     :a, :downcase, :lithuanian
    assert_send_type "(:turkic) -> Symbol",
                     :a, :downcase, :turkic
    assert_send_type "(:lithuanian, :turkic) -> Symbol",
                     :a, :downcase, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> Symbol",
                     :a, :downcase, :turkic, :lithuanian
  end

  def test_empty_p
    assert_send_type "() -> true",
                     :"", :empty?
    assert_send_type "() -> false",
                     :a, :empty?
  end

  def test_encoding
    assert_send_type "() -> Encoding",
                     :a, :encoding
  end

  def test_end_with?
    assert_send_type "() -> false",
                     :a, :end_with?
    assert_send_type "(String) -> true",
                     :a, :end_with?, "a"
    assert_send_type "(String) -> false",
                     :a, :end_with?, "b"
    assert_send_type "(String, String) -> true",
                     :a, :end_with?, "a", "b"
    assert_send_type "(ToStr) -> true",
                     :a, :end_with?, ToStr.new("a")
  end

  def test_id2name
    assert_send_type "() -> String",
                     :a, :id2name
  end

  def test_inspect
    assert_send_type "() -> String",
                     :a, :inspect
  end

  def test_intern
    assert_send_type "() -> Symbol",
                     :a, :intern
  end

  def test_length
    assert_send_type "() -> Integer",
                     :a, :length
  end

  def test_match
    assert_send_type "(Regexp) -> MatchData",
                     :a, :match, /a/
    assert_send_type "(Regexp) -> nil",
                     :a, :match, /b/
    assert_send_type "(String) -> MatchData",
                     :a, :match, "a"
    assert_send_type "(String) -> nil",
                     :a, :match, "b"
    assert_send_type "(ToStr) -> MatchData",
                     :a, :match, ToStr.new("a")
    assert_send_type "(ToStr) -> nil",
                     :a, :match, ToStr.new("b")
    assert_send_type "(Regexp, Integer) -> MatchData",
                     :a, :match, /a/, 0
    assert_send_type "(Regexp, Integer) -> nil",
                     :a, :match, /a/, 1
    assert_send_type "(String, Integer) -> MatchData",
                     :a, :match, "a", 0
    assert_send_type "(String, Integer) -> nil",
                     :a, :match, "a", 1
    assert_send_type "(ToStr, Integer) -> MatchData",
                     :a, :match, ToStr.new("a"), 0
    assert_send_type "(ToStr, Integer) -> nil",
                     :a, :match, ToStr.new("a"), 1
    assert_send_type "(Regexp, ToInt) -> MatchData",
                     :a, :match, /a/, ToInt.new(0)
    assert_send_type "(Regexp, ToInt) -> nil",
                     :a, :match, /a/, ToInt.new(1)
    assert_send_type "(String, ToInt) -> MatchData",
                     :a, :match, "a", ToInt.new(0)
    assert_send_type "(String, ToInt) -> nil",
                     :a, :match, "a", ToInt.new(1)
    assert_send_type "(ToStr, ToInt) -> MatchData",
                     :a, :match, ToStr.new("a"), ToInt.new(0)
    assert_send_type "(ToStr, ToInt) -> nil",
                     :a, :match, ToStr.new("a"), ToInt.new(1)
    assert_send_type "(Regexp) { (MatchData) -> void } -> untyped",
                     :a, :match, /a/ do |_m| end
  end

  def test_match?
    assert_send_type "(Regexp) -> true",
                     :a, :match?, /a/
    assert_send_type "(Regexp) -> false",
                     :a, :match?, /b/
    assert_send_type "(String) -> true",
                     :a, :match?, "a"
    assert_send_type "(String) -> false",
                     :a, :match?, "b"
    assert_send_type "(ToStr) -> true",
                     :a, :match?, ToStr.new("a")
    assert_send_type "(ToStr) -> false",
                     :a, :match?, ToStr.new("b")
    assert_send_type "(Regexp, Integer) -> true",
                     :a, :match?, /a/, 0
    assert_send_type "(Regexp, Integer) -> false",
                     :a, :match?, /a/, 1
    assert_send_type "(String, Integer) -> true",
                     :a, :match?, "a", 0
    assert_send_type "(String, Integer) -> false",
                     :a, :match?, "a", 1
    assert_send_type "(ToStr, Integer) -> true",
                     :a, :match?, ToStr.new("a"), 0
    assert_send_type "(ToStr, Integer) -> false",
                     :a, :match?, ToStr.new("a"), 1
    assert_send_type "(Regexp, ToInt) -> true",
                     :a, :match?, /a/, ToInt.new(0)
    assert_send_type "(Regexp, ToInt) -> false",
                     :a, :match?, /a/, ToInt.new(1)
    assert_send_type "(String, ToInt) -> true",
                     :a, :match?, "a", ToInt.new(0)
    assert_send_type "(String, ToInt) -> false",
                     :a, :match?, "a", ToInt.new(1)
    assert_send_type "(ToStr, ToInt) -> true",
                     :a, :match?, ToStr.new("a"), ToInt.new(0)
    assert_send_type "(ToStr, ToInt) -> false",
                     :a, :match?, ToStr.new("a"), ToInt.new(1)
  end

  def test_next
    assert_send_type "() -> Symbol",
                     :a, :next
  end

  def test_size
    assert_send_type "() -> Integer",
                     :a, :size
  end

  def test_start_with?
    assert_send_type "() -> false",
                     :a, :start_with?
    assert_send_type "(String) -> true",
                     :a, :start_with?, "a"
    assert_send_type "(String) -> false",
                     :a, :start_with?, "b"
    assert_send_type "(String, String) -> true",
                     :a, :start_with?, "b", "a"
    assert_send_type "(ToStr) -> true",
                     :a, :start_with?, ToStr.new("a")
    assert_send_type "(ToStr) -> false",
                     :a, :start_with?, ToStr.new("b")
    assert_send_type "(ToStr, ToStr) -> true",
                     :a, :start_with?, ToStr.new("b"), ToStr.new("a")
    assert_send_type "(Regexp) -> true",
                     :a, :start_with?, /a/
  end

  def test_succ
    assert_send_type "() -> Symbol",
                     :a, :succ
  end

  def test_swapcase
    assert_send_type "() -> Symbol",
                     :a, :swapcase
    assert_send_type "(:ascii) -> Symbol",
                     :a, :swapcase, :ascii
    assert_send_type "(:lithuanian) -> Symbol",
                     :a, :swapcase, :lithuanian
    assert_send_type "(:turkic) -> Symbol",
                     :a, :swapcase, :turkic
    assert_send_type "(:lithuanian, :turkic) -> Symbol",
                     :a, :swapcase, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> Symbol",
                     :a, :swapcase, :turkic, :lithuanian
  end

  def test_to_proc
    assert_send_type "() -> Proc",
                     :a, :to_proc
  end

  def test_to_s
    assert_send_type "() -> String",
                     :a, :to_s
  end

  def test_to_sym
    assert_send_type "() -> Symbol",
                     :a, :to_sym
  end

  def test_upcase
    assert_send_type "() -> Symbol",
                     :a, :upcase
    assert_send_type "(:ascii) -> Symbol",
                     :a, :upcase, :ascii
    assert_send_type "(:lithuanian) -> Symbol",
                     :a, :upcase, :lithuanian
    assert_send_type "(:turkic) -> Symbol",
                     :a, :upcase, :turkic
    assert_send_type "(:lithuanian, :turkic) -> Symbol",
                     :a, :upcase, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> Symbol",
                     :a, :upcase, :turkic, :lithuanian
  end
end
