require_relative "test_helper"

class HashSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Hash)'

  Subclass = Class.new(Hash)

  def test_op_aref
    with_hash 'hello' => :word do |hash|
      assert_send_type '(hash[String, Symbol]) -> HashSingletonTest::Subclass[String, Symbol]',
                       Subclass, :[], hash
    end

    with_array :a, 1 do |pair1|
      with_array :b, 2 do |pair2|
        with_array pair1, pair2 do |ary|
          assert_send_type '(array[Hash::_Pair[String, Symbol]]) -> HashSingletonTest::Subclass[Symbol, Integer]',
                           Subclass, :[], ary
        end
      end
    end

    assert_send_type '(*String | Integer) -> Hash[String | Integer, String | Integer]',
                     Subclass, :[], 'a', 1, 'b', 2
  end

  def test_try_convert
    with_hash 'hello' => :word do |hash|
      assert_send_type '(hash[String, Symbol]) -> Hash[String, Symbol]',
                       Hash, :try_convert, hash
    end

    with_untyped do |untyped|
      next if defined? untyped.to_hash

      assert_send_type '(untyped) -> nil',
                       Hash, :try_convert, untyped
    end
  end

  def test_new
    assert_send_type '() -> Hash[Symbol, Rational]',
                     Hash, :new
    assert_send_type '(Rational) -> Hash[Symbol, Rational]',
                     Hash, :new, 1r
    assert_send_type '() { (Hash[Symbol, Rational], Hash::_Key) -> Rational } -> Hash[Symbol, Rational]',
                     Hash, :new do 1r end

    with_int 1 do |capacity|
      assert_send_type '(capacity: int) -> Hash[Symbol, Rational]',
                       Hash, :new, capacity: capacity
      assert_send_type '(Rational, capacity: int) -> Hash[Symbol, Rational]',
                       Hash, :new, 1r, capacity: capacity
      assert_send_type '(capacity: int) { (Hash[Symbol, Rational], Hash::_Key) -> Rational } -> Hash[Symbol, Rational]',
                       Hash, :new, capacity: capacity do 1r end
    end
  end
end

class HashInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Hash[Symbol, Rational]'

  class BlankKey < BlankSlate
    def initialize(key) = @key = key
    def hash = @key.hash
    def eql?(rhs) = @key.eql?(rhs)
  end

  def with_key(key)
    yield key
    yield BlankKey.new key
  end

  def test_op_lt
    with_hash a: 3, 'b' => 4 do |hash|
      assert_send_type '(hash[untyped, untyped]) -> bool',
                       {a: 1r}, :<, hash
    end
  end

  def test_op_le
    with_hash a: 3, 'b' => 4 do |hash|
      assert_send_type '(hash[untyped, untyped]) -> bool',
                       {a: 1r}, :<=, hash
    end
  end

  def test_op_gt
    with_hash a: 3, 'b' => 4 do |hash|
      assert_send_type '(hash[untyped, untyped]) -> bool',
                       {a: 1r}, :>, hash
    end
  end

  def test_op_ge
    with_hash a: 3, 'b' => 4 do |hash|
      assert_send_type '(hash[untyped, untyped]) -> bool',
                       {a: 1r}, :>=, hash
    end
  end

  def test_rehash
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :rehash
  end

  def test_freeze
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :freeze
  end

  def test_to_hash
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :to_hash
  end

  def test_to_a
    assert_send_type '() -> Array[[Symbol, Rational]]',
                     {a: 1r}, :to_a
  end

  def test_to_h
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :to_h

    with_array 'a', 1i do |pair|
      assert_send_type '[A, B] () { (Symbol, Rational) -> Hash::_Pair[A, B] } -> Hash[A, B]',
                       {a: 1r}, :to_h do pair end
    end
  end

  def test_inspect(method: :inspect)
    assert_send_type '() -> String',
                     {a: 1r}, method
  end

  def test_to_s
    test_inspect(method: :to_s)
  end

  def test_to_proc
    assert_send_type '() -> ^(Symbol) -> Rational?',
                     {a: 1r}, :to_proc

    # Make sure return type is correct
    assert_type 'Rational', {a: 1r}.to_proc.call(:a)
    assert_type 'nil', {a: 1r}.to_proc.call(:not_a_key)

    # make sure it only takes one argument
    assert_raises ArgumentError do {a: 1r}.to_proc.call(:a, :b) end
    assert_raises ArgumentError do {a: 1r}.to_proc.call() end
  end

  def test_op_eq
    h = {a: 1r}
    with_untyped.and h do |untyped|
      assert_send_type '(untyped) -> bool',
                       h, :==, untyped
    end
  end

  def test_op_aref
    with_key :a do |key|
      assert_send_type '(Hash::_Key) -> Rational',
                       {a: 1r}, :[], key
    end

    with_key :not_a_key do |key|
      assert_send_type '(Hash::_Key) -> nil',
                       {a: 1r}, :[], key
    end
  end

  def test_hash
    assert_send_type '() -> Integer',
                     {a: 1r}, :hash
  end

  def test_eql?
    h = {a: 1r}
    with_untyped.and h do |untyped|
      assert_send_type '(untyped) -> bool',
                       h, :eql?, untyped
    end
  end

  def test_fetch
    with_key :a do |key|
      assert_send_type '(Hash::_Key) -> Rational',
                       {a: 1r}, :fetch, key

      with_untyped do |default_value|
        assert_send_type '(Hash::_Key, untyped) -> Rational',
                         {a: 1r}, :fetch, key, default_value
      end

      assert_send_type '[K2 < Hash::_Key] (K2) {(K2) -> void} -> Rational',
                       {a: 1r}, :fetch, key do fail end
    end

    with_key :not_a_key do |key|
      with_untyped do |default_value|
        assert_send_type '[T] (Hash::_Key, T) -> T',
                         {a: 1r}, :fetch, key, default_value

        assert_send_type '[K2 < Hash::_Key, T] (K2) { (K2) -> T } -> T',
                         {a: 1r}, :fetch, key do default_value end
      end
    end
  end

  def test_op_aset(method: :[]=)
    assert_send_type '(Symbol, Rational) -> Rational',
                     {a: 1r}, method, :a, 10r
    assert_send_type '(Symbol, Rational) -> Rational',
                     {a: 1r}, method, :not_a_key, 10r
  end

  def test_store
    test_op_aset(method: :store)
  end

  def test_default
    no_default = {a: 10r}
    with_default = Hash.new(10r)

    assert_send_type '() -> nil',
                     no_default, :default
    assert_send_type '() -> Rational',
                     with_default, :default

    with_key :a do |key|
      assert_send_type '(Hash::_Key) -> nil',
                       no_default, :default, key
      assert_send_type '(Hash::_Key) -> Rational',
                       with_default, :default, key
    end
  end

  def test_default=
    assert_send_type '(Rational) -> Rational',
                     {a: 1r}, :default=, 1r
  end

  def test_default_proc
    assert_send_type '() -> nil',
                     {a: 1r}, :default_proc
    assert_send_type '() -> ^(HashInstanceTest::Subclass[Symbol, Rational], Hash::_Key) -> Rational',
                     Subclass.new{ :oops }, :default_proc
  end

  Subclass = Class.new(Hash)

  def test_default_proc=
    assert_send_type '(nil) -> nil',
                     {}, :default_proc=, nil
    assert_send_type '(^(HashInstanceTest::Subclass[Symbol, Rational], Hash::_Key) -> Rational) -> ^(HashInstanceTest::Subclass[Symbol, Rational], Hash::_Key) -> Rational',
                     Subclass[], :default_proc=, ->(h, k) { 1r }

    toproc = BlankSlate.new
    def toproc.to_proc = ->(h, k) { 1r }
    with proc{}, toproc do |proc_like|
      assert_send_type '(_ToProc) -> Proc',
                       {}, :default_proc=, proc_like
    end
  end

  def test_key
    equals_1r = BlankSlate.new
    def equals_1r.==(r) = 1r == r

    assert_send_type '(Hash::_Equals) -> Symbol',
                     { a: 1r, b: 2r }, :key, equals_1r
    assert_send_type '(Hash::_Equals) -> nil',
                     { a: 3r, b: 2r }, :key, equals_1r
  end

  def test_size(method: :size)
    assert_send_type '() -> Integer',
                     {a: 1r}, method
  end

  def test_length
    test_size(method: :length)
  end

  def test_empty?
    assert_send_type '() -> bool',
                     {a: 1r}, :empty?
  end

  def test_each_value
    assert_send_type '() -> Enumerator[Rational, Hash[Symbol, Rational]]',
                     {a: 1r}, :each_value
    assert_send_type '() { (Rational) -> void } -> Hash[Symbol, Rational]',
                     {a: 1r}, :each_value do end
  end

  def test_each_key
    assert_send_type '() -> Enumerator[Symbol, Hash[Symbol, Rational]]',
                     {a: 1r}, :each_key
    assert_send_type '() { (Symbol) -> void } -> Hash[Symbol, Rational]',
                     {a: 1r}, :each_key do end
  end

  def test_each(method: :each)
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, method
    assert_send_type '() { ([Symbol, Rational]) -> void } -> Hash[Symbol, Rational]',
                     {a: 1r}, method do end
  end

  def test_each_pair
    test_each(method: :each_pair)
  end

  def test_transform_keys
    assert_send_type '() -> Enumerator[Symbol, Hash[untyped, Rational]]',
                     {a: 1r}, :transform_keys

    with_hash a: 'hello', 'not_a_symbol' => 'what' do |replacements|
      assert_send_type '(hash[Hash::_Key, String]) -> Hash[Symbol | String, Rational]',
                       {a: 1r}, :transform_keys, replacements
      assert_send_type '(hash[Hash::_Key, String]) { (Symbol) -> String } -> Hash[String, Rational]',
                       {a: 1r}, :transform_keys, replacements, &:to_s
    end

    assert_send_type '() { (Symbol) -> String } -> Hash[String, Rational]',
                     {a: 1r}, :transform_keys, &:to_s
  end

  def test_transform_keys!
    ## You cannot properly test the following, because when `assert_send_type` tries to figure out
    ## the types, it ends up converting the hash to `{nil => 1r}`.
    # assert_send_type '() -> Enumerator[Symbol, Hash[Symbol, Rational]]',
    #                  {a: 1r}, :transform_keys!

    with_hash a: :hello, 'not_a_symbol' => :what do |replacements|
      assert_send_type '(hash[Hash::_Key, Symbol]) -> Hash[Symbol, Rational]',
                       {a: 1r}, :transform_keys!, replacements
      assert_send_type '(hash[Hash::_Key, Symbol]) { (Symbol) -> Symbol } -> Hash[Symbol, Rational]',
                       {a: 1r}, :transform_keys!, replacements, &:upcase
    end

    assert_send_type '() { (Symbol) -> Symbol } -> Hash[Symbol, Rational]',
                     {a: 1r}, :transform_keys!, &:upcase
  end

  def test_transform_values
    assert_send_type '() -> Enumerator[Rational, Hash[Symbol, untyped]]',
                     {a: 1r}, :transform_values
    assert_send_type '() { (Rational) -> Complex } -> Hash[Symbol, Complex]',
                     {a: 1r}, :transform_values, &:i
  end

  def test_transform_values!
    ## You cannot properly test the following, because when `assert_send_type` tries to figure out
    ## the types, it ends up converting the hash to `{a: nil}`.
    # assert_send_type '() -> Enumerator[Rational, Hash[Symbol, Rational]]',
    #                  {a: 1r}, :transform_values!
    assert_send_type '() { (Rational) -> Rational } -> Hash[Symbol, Rational]',
                     {a: 1r}, :transform_values! do |rat| rat + 1 end
  end

  def test_keys
    assert_send_type '() -> Array[Symbol]',
                     {a: 1r}, :keys
  end

  def test_values
    assert_send_type '() -> Array[Rational]',
                     {a: 1r}, :values
  end

  def test_values_at
    assert_send_type '() -> Array[Rational]',
                     {a: 1r}, :values_at

    with_key :a do |key|
      assert_send_type '(*Hash::_Key) -> Array[Rational]',
                       {a: 1r}, :values_at, key

      with_key :not_a_key do |not_a_key|
        assert_send_type '(*Hash::_Key) -> Array[Rational?]',
                         {a: 1r}, :values_at, key, not_a_key
      end
    end
  end

  def test_fetch_values
    assert_send_type '() -> Array[Rational]',
                     {a: 1r}, :fetch_values

    with_key :a do |key|
      assert_send_type '(*Hash::_Key) -> Array[Rational]',
                       {a: 1r}, :fetch_values, key
      assert_send_type '[K < Hash::_Key] (*K) { (K) -> Complex } -> Array[Rational]',
                       {a: 1r}, :fetch_values, key do 1i end

      with_key :not_a_key do |not_a_key|
        assert_send_type '[K < Hash::_Key] (*K) { (K) -> Complex } -> Array[Rational | Complex]',
                         {a: 1r}, :fetch_values, key, not_a_key do 1i end
      end
    end
  end

  def test_shift
    assert_send_type '() -> nil',
                     {}, :shift
    assert_send_type '() -> [Symbol, Rational]',
                     {a: 1r}, :shift
  end

  def test_delete
    with_key :a do |key|
      assert_send_type '(Hash::_Key) -> nil',
                       {}, :delete, key
      assert_send_type '(Hash::_Key) -> Rational',
                       {a: 1r}, :delete, key

      assert_send_type '[K < Hash::_Key] (K) { (K) -> Complex } -> (Rational | Complex)',
                       {}, :delete, key do 1i end
      assert_send_type '[K < Hash::_Key] (K) { (K) -> Complex } -> (Rational | Complex)',
                       {a: 1r}, :delete, key do 1i end
    end
  end

  def test_delete_if
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, :delete_if
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, :delete_if do :boolish end
  end

  def test_keep_if
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, :keep_if
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, :keep_if do :boolish end
  end

  def test_select(method: :select)
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, method
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, method do :boolish end
  end

  def test_select!(method: :select!)
    assert_send_type '() -> Enumerator[[Symbol, Rational], nil]',
                     {}, method
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, method
    assert_send_type '() { (Symbol, Rational) -> boolish } -> nil',
                     {a: 1r}, method do :boolish end
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, method do nil end
  end

  def test_filter
    test_select(method: :filter)
  end

  def test_filter!
    test_select!(method: :filter!)
  end

  def test_reject
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]]',
                     {a: 1r}, :reject
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, :reject do :boolish end
  end

  def test_reject!
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]?]',
                     {}, :reject!
    assert_send_type '() -> Enumerator[[Symbol, Rational], Hash[Symbol, Rational]?]',
                     {a: 1r}, :reject!
    assert_send_type '() { (Symbol, Rational) -> boolish } -> Hash[Symbol, Rational]',
                     {a: 1r}, :reject! do :boolish end
    assert_send_type '() { (Symbol, Rational) -> boolish } -> nil',
                     {a: 1r}, :reject! do nil end
  end

  def test_slice
    assert_send_type '[K < Hash::_Key] (*K) -> Hash[K, Rational]',
                     {a: 1r}, :slice
    with_key :a do |key|
      assert_send_type '[K < Hash::_Key] (*K) -> Hash[K, Rational]',
                       {a: 1r}, :slice, key
      with_key :not_a_key do |not_a_key|
        assert_send_type '[K < Hash::_Key] (*K) -> Hash[K, Rational]',
                         {a: 1r}, :slice, key, not_a_key
      end
    end
  end

  def test_except
    assert_send_type '(*Hash::_Key) -> Hash[Symbol, Rational]',
                     {a: 1r, b: 2r}, :except

    with_key :a do |key|
      assert_send_type '(*Hash::_Key) -> Hash[Symbol, Rational]',
                       {a: 1r, b: 2r}, :except, key

      with_key :not_a_key do |not_a_key|
        assert_send_type '(*Hash::_Key) -> Hash[Symbol, Rational]',
                         {a: 1r, b: 2r}, :except, key, not_a_key
      end
    end
  end

  def test_clear
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r, b: 2r}, :clear
  end

  def test_invert
    assert_send_type '() -> Hash[Rational, Symbol]',
                     {a: 1r, b: 2r}, :invert
  end

  def test_update
    test_merge!(method: :update)
  end

  def test_replace(method: :replace)
    with_hash a: 2r do |hash|
      assert_send_type '(hash[Symbol, Rational]) -> Hash[Symbol, Rational]',
                       {a: 1r}, method, hash
    end
  end

  def test_initialize_copy
    test_replace(method: :initialize_copy)
  end

  def test_merge!(method: :merge!)
    assert_send_type '(*hash[Symbol, Rational]) -> Hash[Symbol, Rational]',
                     {a: 1r}, method
    assert_send_type '(*hash[Symbol, Rational]) {(Symbol, Rational, Rational) -> Rational} -> Hash[Symbol, Rational]',
                     {a: 1r}, method do 2r end

    with_hash b: 2r do |hash1|
      assert_send_type '(*hash[Symbol, Rational]) -> Hash[Symbol, Rational]',
                       {a: 1r}, method, hash1
      assert_send_type '(*hash[Symbol, Rational]) {(Symbol, Rational, Rational) -> Rational} -> Hash[Symbol, Rational]',
                       {a: 1r}, method, hash1 do 2r end

      with_hash a: 3r do |hash2|
        assert_send_type '(*hash[Symbol, Rational]) -> Hash[Symbol, Rational]',
                         {a: 1r}, method, hash1, hash2
        assert_send_type '(*hash[Symbol, Rational]) {(Symbol, Rational, Rational) -> Rational} -> Hash[Symbol, Rational]',
                         {a: 1r}, method, hash1, hash2 do 2r end
      end
    end
  end

  def test_merge
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :merge
    assert_send_type '() { (Symbol, Rational, Complex) -> Float} -> Hash[Symbol, Rational]',
                     {a: 1r}, :merge do 1.0 end

    with_hash 'b' => 2i do |hash1|
      assert_send_type '(*hash[String, Complex]) -> Hash[Symbol | String, Rational | Complex]',
                       {a: 1r}, :merge, hash1
      assert_send_type '(*hash[String, Complex]) { (Symbol, Rational, Complex) -> Float} -> Hash[Symbol | String, Rational | Complex]',
                       {a: 1r}, :merge, hash1 do 1.0 end

      with_hash a: 3i do |hash2|
        assert_send_type '(*hash[String, Complex]) -> Hash[Symbol | String, Rational | Complex]',
                         {a: 1r}, :merge, hash1, hash2
        assert_send_type '(*hash[String, Complex]) { (Symbol, Rational, Complex) -> Float} -> Hash[Symbol | String, Rational | Complex | Float]',
                         {a: 1r}, :merge, hash1, hash2 do 1.0 end
      end
    end
  end

  def test_assoc
    equals_symbol_a = BlankSlate.new
    def equals_symbol_a.==(r) = :a == r

    with :a, equals_symbol_a do |key|
      assert_send_type '(Hash::_Equals) -> [Symbol, Rational]',
                       {a: 1r}, :assoc, key
      assert_send_type '(Hash::_Equals) -> nil',
                       {b: 1r}, :assoc, key
    end
  end

  def test_rassoc
    equals_1r = BlankSlate.new
    def equals_1r.==(r) = 1r == r

    with 1r, equals_1r do |value|
      assert_send_type '(Hash::_Equals) -> [Symbol, Rational]',
                       {a: 1r}, :rassoc, value
      assert_send_type '(Hash::_Equals) -> nil',
                       {a: 2r}, :rassoc, value
    end
  end

  def test_flatten
    assert_send_type '() -> Array[Symbol | Rational]',
                     {a: 1r}, :flatten
    assert_send_type '(1) -> Array[Symbol | Rational]',
                     {a: 1r}, :flatten, 1
    assert_send_type '(0) -> Array[[Symbol, Rational]]',
                     {a: 1r}, :flatten, 0

    with_int -1 do |level|
      assert_send_type '(int) -> Array[untyped]',
                       {a: 1r}, :flatten, level
    end
  end

  def test_compact
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r, b: nil}, :compact
  end

  def test_compact!
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r, b: nil}, :compact!
    assert_send_type '() -> nil',
                     {a: 1r, b: 2r}, :compact!
  end

  def test_include?
    test_has_key?(method: :include?)
  end

  def test_member?
    test_has_key?(method: :member?)
  end

  def test_has_key?(method: :has_key?)
    with_key :a do |key|
      assert_send_type '(Hash::_Key) -> bool',
                       {a: 1r}, method, key
      assert_send_type '(Hash::_Key) -> bool',
                       {b: 1r}, method, key
    end
  end

  def test_has_value?(method: :has_value?)
    equals_1r = BlankSlate.new
    def equals_1r.==(r) = 1r == r

    with 1r, equals_1r do |value|
      assert_send_type '(Hash::_Equals) -> bool',
                       {a: 1r}, method, value
      assert_send_type '(Hash::_Equals) -> bool',
                       {a: 12}, method, value
    end
  end

  def test_key?
    test_has_key?(method: :key?)
  end

  def test_value?
    test_has_value?(method: :value?)
  end

  def test_compare_by_identity
    assert_send_type '() -> Hash[Symbol, Rational]',
                     {a: 1r}, :compare_by_identity
  end

  def test_compare_by_identity?
    assert_send_type '() -> bool',
                     {a: 1r}, :compare_by_identity?
    assert_send_type '() -> bool',
                     {a: 1r}.compare_by_identity, :compare_by_identity?
  end

  def test_any?
    assert_send_type '() -> bool',
                     {}, :any?
    assert_send_type '() -> bool',
                     {a: 1r}, :any?

    pattern = BlankSlate.new
    def pattern.===(r) = r == [:a, 1r] ? :boolish : nil
    assert_send_type '(Enumerable::_Pattern) -> bool',
                     {a: 1r}, :any?, pattern
    assert_send_type '(Enumerable::_Pattern) -> bool',
                     {a: 2r}, :any?, pattern

    assert_send_type '() { ([Symbol, Rational]) -> boolish } -> bool',
                     {a: 1r}, :any? do :boolish end
    assert_send_type '() { ([Symbol, Rational]) -> boolish } -> bool',
                     {a: 1r}, :any? do nil end
  end

  def test_dig
    with_key :a do |key|
      assert_send_type '(Hash::_Key, *untyped) -> untyped',
                       {a: [1r]}, :dig, key, 0
      assert_send_type '(Hash::_Key, *untyped) -> untyped',
                       {b: [1r]}, :dig, key, 0
    end
  end

  def test_deconstruct_keys
    with_untyped do |argument|
      assert_send_type '(untyped) -> Hash[Symbol, Rational]',
                       {a: 1r}, :deconstruct_keys, argument
    end
  end
end
