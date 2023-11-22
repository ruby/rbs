require_relative "test_helper"

class StructSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Struct)"

  def test_new
    # Since we're redefining `TestNewStruct` constantly, we need to set `$VERBOSE` to nil to suppress
    # the redeclaration warnings.
    old_verbose = $VERBOSE
    $VERBOSE = nil

    with_string 'TestNewStruct' do |classname|
      with_interned :field1 do |field1|
        with_interned :field2 do |field2|
          assert_send_type  "(::string?, *::interned) -> singleton(Struct)",
                            Struct, :new, classname, field1, field2
          assert_send_type  "(::string?, *::interned) { (self) -> void } -> singleton(Struct)",
                            Struct, :new, classname, field1, field2 do end

          if Symbol === field1 # can't use `.is_a?` since `ToStr` doesn't define it.
            assert_send_type  "(Symbol, *::interned) -> singleton(Struct)",
                              Struct, :new, field1, field2
            assert_send_type  "(Symbol, *::interned) { (self) -> void } -> singleton(Struct)",
                              Struct, :new, field1, field2 do end
          end

          ['yes', false, nil].each do |kwinit|
            assert_send_type  "(::string?, *::interned, keyword_init: ::boolish?) ?{ (self) -> void } -> singleton(Struct)",
                              Struct, :new, classname, field1, field2, keyword_init: kwinit
            assert_send_type  "(::string?, *::interned, keyword_init: ::boolish?) ?{ (self) -> void } -> singleton(Struct)",
                              Struct, :new, classname, field1, field2, keyword_init: kwinit do end
            
            if Symbol === field1 # can't use `.is_a?` since `ToStr` doesn't define it.
              assert_send_type  "(Symbol, *::interned, keyword_init: ::boolish?) -> singleton(Struct)",
                                Struct, :new, field1, field2, keyword_init: kwinit
              assert_send_type  "(Symbol, *::interned, keyword_init: ::boolish?) { (self) -> void } -> singleton(Struct)",
                                Struct, :new, field1, field2, keyword_init: kwinit do end
            end
          end
        end
      end
    end
  ensure
    $VERBOSE = old_verbose
  end

  def test_members
    assert_send_type  "() -> Array[Symbol]",
                      Struct.new(:foo, :bar), :members
  end

  def test_keyword_init?
    assert_send_type  "() -> bool?",
                      Struct.new(:foo), :keyword_init?
    assert_send_type  "() -> bool?",
                      Struct.new(:foo, keyword_init: true), :keyword_init?
    assert_send_type  "() -> bool?",
                      Struct.new(:foo, keyword_init: false), :keyword_init?
    assert_send_type  "() -> bool?",
                      Struct.new(:foo, keyword_init: nil), :keyword_init?
  end
end

class StructInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Struct[Rational]"

  MyStruct = Struct.new(:foo, :bar)
  Instance = MyStruct.new(1r, 2r)


  def with_index(int=1, str=:bar, &block)
    block.call str.to_s
    block.call str.to_sym
    with_int(int, &block)
  end

  def test_equal
    assert_send_type  "(untyped) -> bool",
                      Instance, :==, 3
  end

  def test_eql?
    assert_send_type  "(untyped) -> bool",
                      Instance, :eql?, 3
  end

  def test_hash
    assert_send_type  "() -> Integer",
                      Instance, :hash
  end

  def test_inspect
    assert_send_type  "() -> String",
                      Instance, :inspect
  end

  def test_to_s
    assert_send_type  "() -> String",
                      Instance, :to_s
  end

  def test_to_a
    assert_send_type  "() -> Array[Rational]",
                      Instance, :to_a
  end

  def test_to_h
    assert_send_type  "() -> Hash[Symbol, Rational]",
                      Instance, :to_h
    assert_send_type  "[K, V] () { (Symbol, Rational) -> [K, V] } -> Hash[K, V]",
                      Instance, :to_h do [1, 2] end
  end

  def test_values
    assert_send_type  "() -> Array[Rational]",
                      Instance, :values
  end

  def test_size
    assert_send_type  "() -> Integer",
                      Instance, :size
  end

  def test_length
    assert_send_type  "() -> Integer",
                      Instance, :length
  end

  def test_each
    assert_send_type  "() -> Enumerator[Rational, self]",
                      Instance, :each
    assert_send_type  "() { (Rational) -> void } -> self",
                      Instance, :each do end
  end

  def test_each_pair
    assert_send_type  "() -> Enumerator[[Symbol, Rational], self]",
                      Instance, :each_pair
    assert_send_type  "() { ([Symbol, Rational]) -> void } -> self",
                      Instance, :each_pair do end
  end

  def test_aref
    with_index do |idx|
      assert_send_type  "(Struct::index) -> Rational",
                        Instance, :[], idx
    end
  end

  def test_aset
    with_index do |idx|
      assert_send_type  "(Struct::index, Rational) -> Rational",
                        Instance, :[]=, idx, 1r
    end
  end

  def test_select
    assert_send_type  "() -> Enumerator[Rational, Array[Rational]]",
                      Instance, :select
    assert_send_type  "() { (Rational) -> ::boolish } -> Array[Rational]",
                      Instance, :select do end
  end


  def test_filter
    assert_send_type  "() -> Enumerator[Rational, Array[Rational]]",
                      Instance, :filter
    assert_send_type  "() { (Rational) -> ::boolish } -> Array[Rational]",
                      Instance, :filter do end
  end

  def test_values_at
    assert_send_type  "() -> Array[Rational]",
                      Instance, :values_at
  
    with_int 1 do |idx|
      assert_send_type  "(*::int | ::range[::int?]) -> Array[Rational]",
                        Instance, :values_at, idx, idx..nil
    end
  end

  def test_members
    assert_send_type  "() -> Array[Symbol]",
                      Instance, :members
  end

  def test_dig
    array_instance = MyStruct.new([1])
    with_index do |idx|
      assert_send_type  "(Struct::index) -> Rational",
                        Instance, :dig, idx
      assert_send_type  "(Struct::index, untyped, *untyped) -> untyped",
                        array_instance, :dig, idx, 1
    end
  end

  def test_deconstruct
    assert_send_type  "() -> Array[Rational]",
                      Instance, :deconstruct
  end

  def test_deconstruct_keys
    assert_send_type  "(nil) -> Hash[Symbol, Rational]",
                      Instance, :deconstruct_keys, nil

    with_index do |idx|
      # Ensure that the `ToInt` variants have `hash` and `eql?` defined.
      def idx.hash = 0 unless defined? idx.hash
      def idx.eql?(r) = false unless defined? idx.eql? 

      assert_send_type  "(Array[Struct::index & Hash::_Key]) -> Hash[Struct::index & Hash::_Key, Rational]",
                        Instance, :deconstruct_keys, [idx]
    end
  end
end
