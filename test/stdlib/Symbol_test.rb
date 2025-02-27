require_relative 'test_helper'

class SymbolSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Symbol)'

  def test_all_symbols
    assert_send_type '() -> Array[Symbol]',
                     Symbol, :all_symbols
  end
end

class SymbolInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Symbol'

  def test_op_cmp
    %i[a b s y z].each do |other|
      assert_send_type '(Symbol) -> (-1 | 0 |1)',
                       :s, :<=>, other
    end

    with_untyped.and :sym do |untyped|
      assert_send_type '(untyped) -> Integer?',
                       :a, :<=>, untyped
    end
  end

  def test_op_eq(method: :==)
    with_untyped.and :a do |untyped|
      assert_send_type '(untyped) -> bool',
                       :a, method, untyped
    end
  end

  def test_op_eqq
    test_op_eq(method: :===)
  end

  def test_op_match
    assert_send_type '(Regexp) -> Integer',
                     :a, :=~, /a/
    assert_send_type '(nil) -> nil',
                     :a, :=~, nil

    matcher = BlankSlate.new
    def matcher.=~(rhs)
      :world
    end
    assert_send_type '(String::_MatchAgainst[String, Symbol]) -> Symbol',
                     :hello, :=~, matcher
  end

  def test_op_aref(method: :[])
    # (int start, ?int length) -> String?
    with_int(3) do |start|
      assert_send_type  '(int) -> String',
                        :'hello, world', method, start
      assert_send_type  '(int) -> nil',
                        :q, method, start

      with_int 3 do |length|
        assert_send_type  '(int, int) -> String',
                          :'hello, world', method, start, length
        assert_send_type  '(int, int) -> nil',
                          :q, method, start, length
      end
    end

    # (range[int?] range) -> String?
    with_range with_int(3).and_nil, with_int(5).and_nil do |range|
      assert_send_type  '(range[int?]) -> String',
                        :hello, method, range

      next if nil == range.begin # if the starting value is `nil`, you can't get `nil` outputs.
      assert_send_type  '(range[int?]) -> nil',
                        :hi, method, range
    end

    # (Regexp regexp, ?MatchData::capture backref) -> String?
    assert_send_type  '(Regexp) -> String',
                      :hello, method, /./
    assert_send_type  '(Regexp) -> nil',
                      :hello, method, /doesn't match/
    with_int(1).and 'a', :a do |backref|
      assert_send_type  '(Regexp, MatchData::capture) -> String',
                        :hallo, method, /(?<a>)./, backref
      assert_send_type  '(Regexp, MatchData::capture) -> nil',
                        :hallo, method, /(?<a>)doesn't match/, backref
    end

    # (String substring) -> String?
    assert_send_type  '(String) -> String',
                      :hello, method, 'hello'
    assert_send_type  '(String) -> nil',
                      :hello, method, 'does not exist'
    refute_send_type  '(_ToStr) -> untyped',
                      :hello, method, ToStr.new('e')
  end

  def test_capitalize
    assert_send_type '() -> Symbol',
                     :a, :capitalize
    assert_send_type '(:ascii) -> Symbol',
                     :a, :capitalize, :ascii
    assert_send_type '(:lithuanian) -> Symbol',
                     :a, :capitalize, :lithuanian
    assert_send_type '(:turkic) -> Symbol',
                     :a, :capitalize, :turkic
    assert_send_type '(:lithuanian, :turkic) -> Symbol',
                     :a, :capitalize, :lithuanian, :turkic
    assert_send_type '(:turkic, :lithuanian) -> Symbol',
                     :a, :capitalize, :turkic, :lithuanian
  end

  def test_casecmp
    %i[a A s S z Z].each do |other|
      assert_send_type '(Symbol) -> (-1 | 0 | 1)',
                       :s, :casecmp, other
    end

    # invalid encoding
    assert_send_type '(Symbol) -> nil',
                     "\u{e4 f6 fc}".encode('ISO-8859-1').to_sym, :casecmp, :"\u{c4 d6 dc}"

    with_untyped.and :sym do |other|
      assert_send_type '(untyped) -> (-1 | 0 | 1)?',
                       :a, :casecmp, other
    end
  end

  def test_casecmp?
    %i[a A s S z Z].each do |other|
      assert_send_type '(Symbol) -> bool',
                        :s, :casecmp?, other
    end
    assert_send_type '(String) -> nil',
                     :abc, :casecmp?, "abc"
    assert_send_type '(Integer) -> nil',
                     :abc, :casecmp?, 1
  end

  def test_downcase
    assert_send_type '() -> Symbol',
                     :a, :downcase
    assert_send_type '(:ascii) -> Symbol',
                     :a, :downcase, :ascii
    assert_send_type '(:fold) -> Symbol',
                     :a, :downcase, :fold
    assert_send_type '(:lithuanian) -> Symbol',
                     :a, :downcase, :lithuanian
    assert_send_type '(:turkic) -> Symbol',
                     :a, :downcase, :turkic
    assert_send_type '(:lithuanian, :turkic) -> Symbol',
                     :a, :downcase, :lithuanian, :turkic
    assert_send_type '(:turkic, :lithuanian) -> Symbol',
                     :a, :downcase, :turkic, :lithuanian
  end

  def test_empty_p
    assert_send_type '() -> bool',
                     :a, :empty?
  end

  def test_encoding
    assert_send_type '() -> Encoding',
                     :a, :encoding
  end

  def test_end_with?
    assert_send_type '() -> bool',
                     :a, :end_with?

    with_string 'a' do |string_a|
      assert_send_type '(string) -> true',
                       :a, :end_with?, string_a

      with_string 'b' do |string_b|
        assert_send_type '(string, string) -> true',
                         :a, :end_with?, string_a, string_b
      end
    end
  end

  def test_id2name
    test_to_s(method: :id2name)
  end

  def test_inspect
    assert_send_type '() -> String',
                     :a, :inspect
  end

  def test_intern
    test_to_sym(method: :intern)
  end

  def test_length(method: :length)
    assert_send_type '() -> Integer',
                     :a, method
  end

  def test_match
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> MatchData',
                        :hello, :match, pattern
      assert_send_type  '(Regexp | string) -> nil',
                        :heya, :match, pattern

      assert_send_type  '[T] (Regexp | string) { (MatchData) -> T } -> T',
                        :hello, :match, pattern do 1r end
      assert_send_type  '[T] (Regexp | string) { (MatchData) -> T } -> nil',
                        :heya, :match, pattern do 1r end

      with_int 0 do |offset|
        assert_send_type  '(Regexp | string, int) -> MatchData',
                          :hello, :match, pattern, offset
        assert_send_type  '(Regexp | string, int) -> nil',
                          :heya, :match, pattern, offset

        assert_send_type  '[T] (Regexp | string, int) { (MatchData) -> T } -> T',
                          :hello, :match, pattern, offset do 1r end
        assert_send_type  '[T] (Regexp | string, int) { (MatchData) -> T } -> nil',
                          :heya, :match, pattern, offset do 1r end
      end
    end
  end

  def test_match?
    with_string('l').and /l/ do |pattern|
      assert_send_type  '(Regexp | string) -> bool',
                        :hello, :match?, pattern
      assert_send_type  '(Regexp | string) -> bool',
                        :heya, :match?, pattern

      with_int 0 do |offset|
        assert_send_type  '(Regexp | string, int) -> bool',
                          :hello, :match?, pattern, offset
        assert_send_type  '(Regexp | string, int) -> bool',
                          :heya, :match?, pattern, offset
      end
    end
  end

  def test_next(method: :next)
    assert_send_type '() -> Symbol',
                     :a, method
  end

  def test_name
    assert_send_type '() -> String',
                     :a, :name
  end

  def test_size
    test_length(method: :size)
  end

  def test_slice
    test_op_aref(method: :slice)
  end

  def test_start_with?
    assert_send_type  '() -> bool',
                      :hello, :start_with?

    with_string('he').and /he/ do |prefix|
      assert_send_type  '(*string | Regexp) -> bool',
                        :hello, :start_with?, prefix
      assert_send_type  '(*string | Regexp) -> bool',
                        :hello, :start_with?, prefix, prefix
    end
  end

  def test_succ
    test_next(method: :succ)
  end

  def test_swapcase
    assert_send_type '() -> Symbol',
                     :a, :swapcase
    assert_send_type '(:ascii) -> Symbol',
                     :a, :swapcase, :ascii
    assert_send_type '(:lithuanian) -> Symbol',
                     :a, :swapcase, :lithuanian
    assert_send_type '(:turkic) -> Symbol',
                     :a, :swapcase, :turkic
    assert_send_type '(:lithuanian, :turkic) -> Symbol',
                     :a, :swapcase, :lithuanian, :turkic
    assert_send_type '(:turkic, :lithuanian) -> Symbol',
                     :a, :swapcase, :turkic, :lithuanian
  end

  def test_to_proc
    assert_send_type '() -> Proc',
                     :a, :to_proc
  end

  def test_to_s(method: :to_s)
    assert_send_type '() -> String',
                     :a, method
  end

  def test_to_sym(method: :to_sym)
    assert_send_type '() -> Symbol',
                     :a, method
  end

  def test_upcase
    assert_send_type '() -> Symbol',
                     :a, :upcase
    assert_send_type '(:ascii) -> Symbol',
                     :a, :upcase, :ascii
    assert_send_type '(:lithuanian) -> Symbol',
                     :a, :upcase, :lithuanian
    assert_send_type '(:turkic) -> Symbol',
                     :a, :upcase, :turkic
    assert_send_type '(:lithuanian, :turkic) -> Symbol',
                     :a, :upcase, :lithuanian, :turkic
    assert_send_type '(:turkic, :lithuanian) -> Symbol',
                     :a, :upcase, :turkic, :lithuanian
  end
end
