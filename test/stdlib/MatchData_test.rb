require_relative 'test_helper'

class MatchDataInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::MatchData'

  INSTANCE = /[^q](?<a>.)(.)(?<b>.)/.match('qwerty')
  INSTANCE2 = /u\K(?<a>a)?./.match('uiop')

  def with_backref(name: 'a', idx: 1, &block)
    yield name.to_s
    yield name.to_sym
    with_int(idx, &block)
  end

  def test_initalize_copy
    instance = /./.match('&')

    assert_send_type  '(MatchData) -> self',
                      instance, :initialize_copy, INSTANCE
  end

  def test_eq(method: :==)
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '(MatchData) -> bool',
                        INSTANCE, method, instance
    end

    with_untyped.but MatchData do |untyped|
      assert_send_type  '(untyped) -> false',
                        INSTANCE, method, untyped
    end
  end

  def test_aref
    with_int 1 do |start|
      with_int 2 do |length|
        assert_send_type  '(int, int) -> Array[String]',
                          INSTANCE, :[], start, length
        assert_send_type  '(int, int) -> Array[nil]',
                          INSTANCE2, :[], start, length
      end
    end

    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> String',
                        INSTANCE, :[], backref
      assert_send_type  '(MatchData::capture, nil) -> String',
                        INSTANCE, :[], backref, nil

      assert_send_type  '(MatchData::capture) -> nil',
                        INSTANCE2, :[], backref
      assert_send_type  '(MatchData::capture, nil) -> nil',
                        INSTANCE2, :[], backref, nil
    end

    with_range with_int(1).and_nil, with_int(2).and_nil do |range|
      assert_send_type  '(range[int?]) -> Array[String]',
                        INSTANCE, :[], range

      # if the beginning is `nil`, then it'll include index `0`, which is the entire capture,
      # and thus will be `Array[String?]`.
      next if nil.equal?(range.begin)
      assert_send_type  '(range[int?]) -> Array[String?]',
                        INSTANCE2, :[], range
    end
  end

  def test_begin
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> Integer',
                        INSTANCE, :begin, backref
      assert_send_type  '(MatchData::capture) -> nil',
                        INSTANCE2, :begin, backref
    end
  end

  def test_byteoffset
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> [Integer, Integer]',
                        INSTANCE, :byteoffset, backref
      assert_send_type  '(MatchData::capture) -> [nil, nil]',
                        INSTANCE2, :byteoffset, backref
    end
  end

  def test_captures(method: :captures)
    assert_send_type  '() -> Array[String]',
                      INSTANCE, method
    assert_send_type  '() -> Array[nil]',
                      INSTANCE2, method
  end

  def test_deconstruct
    test_captures(method: :deconstruct)
  end

  def test_deconstruct_keys
    assert_send_type  '(nil) -> Hash[Symbol, String]',
                      INSTANCE, :deconstruct_keys, nil
    assert_send_type  '(nil) -> Hash[Symbol, nil]',
                      INSTANCE2, :deconstruct_keys, nil

    assert_send_type  '(Array[Symbol]) -> Hash[Symbol, String]',
                      INSTANCE, :deconstruct_keys, [:a]
    assert_send_type  '(Array[Symbol]) -> Hash[Symbol, nil]',
                      INSTANCE2, :deconstruct_keys, [:a]
  end

  def test_end
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> Integer',
                        INSTANCE, :end, backref
      assert_send_type  '(MatchData::capture) -> nil',
                        INSTANCE2, :end, backref
    end
  end

  def test_eql?
    test_eq(method: :eql?)
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      INSTANCE, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      INSTANCE, :inspect
  end

  def test_length
    test_size(method: :length)
  end

  def test_named_captures
    assert_send_type  '() -> Hash[String, String]',
                      INSTANCE, :named_captures
    assert_send_type  '() -> Hash[String, nil]',
                      INSTANCE2, :named_captures
  end

  def test_names
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '() -> Array[String]',
                        instance, :names
    end
  end

  def test_match
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> String',
                        INSTANCE, :match, backref
      assert_send_type  '(MatchData::capture) -> nil',
                        INSTANCE2, :match, backref
    end
  end

  def test_match_length
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> Integer',
                        INSTANCE, :match_length, backref
      assert_send_type  '(MatchData::capture) -> nil',
                        INSTANCE2, :match_length, backref
    end
  end

  def test_offset
    with_backref do |backref|
      assert_send_type  '(MatchData::capture) -> [Integer, Integer]',
                        INSTANCE, :offset, backref
      assert_send_type  '(MatchData::capture) -> [nil, nil]',
                        INSTANCE2, :offset, backref
    end
  end

  def test_post_match
    assert_send_type  '() -> String',
                      INSTANCE, :post_match
  end

  def test_pre_match
    assert_send_type  '() -> String',
                      INSTANCE, :pre_match
  end

  def test_regexp
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '() -> Regexp',
                        instance, :regexp
    end
  end

  def test_size(method: :size)
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '() -> Integer',
                        instance, :size
    end
  end

  def test_string
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '() -> String',
                        instance, :string
    end
  end

  def test_to_a
    assert_send_type  '() -> Array[String]',
                      INSTANCE, :to_a

    # In `.to_a`, the first field is always non-nil.
    assert_send_type  '() -> Array[String?]',
                      INSTANCE2, :to_a
    assert_type 'Array[nil]',
                INSTANCE2.to_a[1..]
  end

  def test_to_s
    with INSTANCE, INSTANCE2 do |instance|
      assert_send_type  '() -> String',
                        instance, :to_s
    end
  end

  def test_values_at
    with INSTANCE, INSTANCE2 do |instance|
        assert_send_type  '(*MatchData::capture) -> []',
                          instance, :values_at
    end

    with_backref do |backref|
      with_range with_int(1).and_nil, with_int(2).and_nil do |range|
        assert_send_type  '(*MatchData::capture | range[int?]) -> Array[String]',
                          INSTANCE, :values_at, backref, range

        # if the beginning is `nil`, then it'll include index `0`, which is the entire capture,
        # and thus will be `Array[String?]`.
        next if nil.equal?(range.begin)
        assert_send_type  '(*MatchData::capture | range[int?]) -> Array[nil]',
                          INSTANCE2, :values_at, backref, range
      end
    end
  end
end
