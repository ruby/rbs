require_relative 'test_helper'

class MatchDataInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::MatchData'

  KW_INSTANCE  = "hello, friend; how are you?".match(/(?<greet>hello).*?(?<whom>friend)(?<punct>[!?])?.*/)
  INSTANCE = "hello, friend; how are you?".match(/(hello).*?(friend)([!?])?/)
  $~ = nil

  def with_backref(str, int, &block)
    with_int(int, &block) if int

    if str
      yield str.to_s
      yield str.to_sym
    end
  end

  def with_instance
    yield KW_INSTANCE
    yield INSTANCE
  end

  def test_eq(meth: :==)
    with_instance do |isntance|
      [KW_INSTANCE, INSTANCE, true, BasicObject.new, nil, :hello].each do |obj|
        assert_send_type '(untyped) -> bool',
                         instance, meth, obj
      end
    end
  end

=begin
  def test_aref
    with_backref 'greet', 1 do |bref|
      assert_send_type  '(backref) -> String',
                        INSTANCE, :[], bref
      assert_send_type  '(backref, nil) -> String',
                        INSTANCE, :[], bref, nil
    end

    with_backref 'invalid', 999 do |bref|
      assert_send_type  '(backref) -> nil',
                        INSTANCE, :[], bref
      assert_send_type  '(backref, nil) -> nil',
                        INSTANCE, :[], bref, nil
    end

    with_int()

    with_range

  def []: (backref idx, ?nil) -> String?
        | (range[int?] range, ?nil) -> Array[String?]?
        | (int start, int length) -> Array[String?]?
=end

  def test_begin
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       KW_INSTANCE, :begin, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       KW_INSTANCE, :begin, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       INSTANCE, :begin, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       INSTANCE, :begin, bref
    end
  end

  def test_byteoffset
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> [Integer, Integer]',
                       KW_INSTANCE, :byteoffset, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> [nil, nil]',
                       KW_INSTANCE, :byteoffset, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> [Integer, Integer]',
                       INSTANCE, :byteoffset, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> [nil, nil]',
                       INSTANCE, :byteoffset, bref
    end
  end

  def test_captures(meth: :captures)
    with_instance do |instance|
      assert_send_type '() -> Array[String?]',
                       instance, meth
    end
  end

  def test_deconstruct
    test_captures meth: :deconstruct
  end

  def test_deconstruct_keys
    with_instance do |instance|
      assert_send_type '(nil) -> Hash[Symbol, String?]',
                       instance, :deconstruct_keys, nil
      assert_send_type '(Array[Symbol]) -> Hash[Symbol, String?]',
                       instance, :deconstruct_keys, [:greet, :punct, :invalid]
    end
  end

  def test_end
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       KW_INSTANCE, :end, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       KW_INSTANCE, :end, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       INSTANCE, :end, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       INSTANCE, :end, bref
    end
  end

  def test_eql?
    test_eq meth: :eql?
  end

  def test_hash
    assert_send_type '() -> Integer',
                     INSTANCE, :hash
  end

  def test_inspect
    assert_send_type '() -> String',
                     INSTANCE, :inspect
  end

  def test_length
    test_size meth: :length
  end

  def test_named_captures
    with_instance do |instance|
      assert_send_type '() -> Hash[String, String?]',
                       instance, :named_captures

      next if RUBY_VERSION < '3.3'

      assert_send_type '(symbolize_names: true) -> Hash[Symbol, String?]',
                       instance, :named_captures, symbolize_names: true
      assert_send_type '(symbolize_names: false) -> Hash[String, String?]',
                       instance, :named_captures, symbolize_names: false

      [123, nil].each do |symbolize_names|
        assert_send_type '(symbolize_names: boolish) -> Hash[String | Symbol, String?]',
                         instance, :named_captures, symbolize_names: symbolize_names
      end
    end
  end

  def test_names
    with_instance do |instance|
      assert_send_type '() -> Array[String]',
                       instance, :names
    end
  end

  def test_match
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> String',
                       KW_INSTANCE, :match, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       KW_INSTANCE, :match, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> String',
                       INSTANCE, :match, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       INSTANCE, :match, bref
    end
  end

  def test_match_length
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       KW_INSTANCE, :match_length, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       KW_INSTANCE, :match_length, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> Integer',
                       INSTANCE, :match_length, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> nil',
                       INSTANCE, :match_length, bref
    end
  end

  def test_offset
    with_backref :whom, 2 do |bref|
      assert_send_type '(MatchData::backref) -> [Integer, Integer]',
                       KW_INSTANCE, :offset, bref
    end

    with_backref :punct, 3 do |bref|
      assert_send_type '(MatchData::backref) -> [nil, nil]',
                       KW_INSTANCE, :offset, bref
    end

    with_int 2 do |bref|
      assert_send_type '(MatchData::backref) -> [Integer, Integer]',
                       INSTANCE, :offset, bref
    end

    with_int 3 do |bref|
      assert_send_type '(MatchData::backref) -> [nil, nil]',
                       INSTANCE, :offset, bref
    end
  end

  def test_post_match
    assert_send_type '() -> String',
                     INSTANCE, :post_match
  end

  def test_pre_match
    assert_send_type '() -> String',
                     INSTANCE, :pre_match
  end

  def test_regexp
    assert_send_type '() -> Regexp',
                     INSTANCE, :regexp
  end

  def test_size(meth: :size)
    assert_send_type '() -> Integer',
                     INSTANCE, meth
  end

  def test_string
    assert_send_type '() -> String',
                     INSTANCE, :string
  end

  def test_to_a
    assert_send_type '() -> Array[String?]',
                     INSTANCE, :to_a
  end

  def test_to_s
    assert_send_type '() -> String',
                     INSTANCE, :to_s
  end

=begin
  def test_values_at
  def values_at: (*backref | range[int?] indices) -> Array[String?]
    assert_send_type '() -> String',
                     INSTANCE, :to_s
  end
=end
end
