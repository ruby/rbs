require_relative "test_helper"

class ArraySingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Array)'

  def test_new
    assert_send_type '() -> Array[untyped]',
                     Array, :new
    with_array 1r, 2r do |array|
      assert_send_type  '(array[Rational]) -> Array[Rational]',
                        Array, :new, array
    end

    with_int 5 do |size|
      assert_send_type '(int) -> Array[nil]',
                       Array, :new, size
      assert_send_type '(int, Rational) -> Array[Rational]',
                       Array, :new, size, 1r
      assert_send_type '(int) { (Integer) -> Rational } -> Array[Rational]',
                       Array, :new, size do it.to_r end
    end
  end

  def test_op_aref
    assert_send_type  '() -> Array[untyped]',
                      Array, :[]
    assert_send_type '(Rational, String) -> Array[Rational | String]',
                     Array, :[], 1r, '2'
  end

  def test_try_convert
    with [1r, 2r], Class.new(Array).new([1r, 2r]) do |subclass|
      assert_send_type  '[A < Array[U], U] (A) -> A',
                        Array, :try_convert, subclass
    end

    with_array 1r, 2r do |ary|
      assert_send_type  '[U] (array[U]) -> Array[U]',
                        Array, :try_convert, ary
    end

    with_untyped.and [1r, 2r] do |untyped|
      assert_send_type '[U] (untyped) -> Array[U]?',
                       Array, :try_convert, untyped
    end
  end
end

class ArrayInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Array[Rational]'

  class ArraySubclass < Array
  end

  class RngGen < BlankSlate
    def rand(max) = ::RBS::UnitTest::Convertibles::ToInt.new(::Random.new.rand(max))
  end

  class ComparableToZero < BlankSlate
    def initialize(cmp) = @cmp = cmp
    def <(x) = 0.equal?(x) ? @cmp < x : fail
    def >(x) = 0.equal?(x) ? @cmp > x : fail
  end

  class HashKey < BlankSlate
    protected attr_reader :key
    def initialize(key) = @key = key
    def hash = @key.hash
    def eql?(other) = HashKey === other && @key.eql?(other.key)
  end

  def with_each(*eles)
    yield Each.new(*eles)
  end

  def test_op_and
    with_array [1r, 1i] do |other|
      assert_send_type  '(array[untyped]) -> Array[Rational]',
                        [1r, 2r], :&, other
    end
  end

  def test_op_times
    with_string do |sep|
      assert_send_type  '(string) -> String',
                        [1r, 2r], :*, sep
    end

    with_int 3 do |n|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :*, n
    end
  end

  def test_op_plus
    with_array 3r, 4r do |ary|
      assert_send_type  '(array[Rational]) -> Array[Rational]',
                        [1r, 2r], :+, ary
    end

    with_array 'a', 'b' do |ary|
      assert_send_type  '(array[String]) -> Array[Rational | String]',
                        [1r, 2r], :+, ary
    end
  end

  def test_op_sub
    with_array 1r, 3r do |ary|
      assert_send_type  '(array[Rational]) -> Array[Rational]',
                        [1r, 2r], :-, ary
    end

    with_untyped do |untyped|
      with_array untyped do |ary|
        assert_send_type  '(array[untyped]) -> Array[Rational]',
                          [1r, 2r], :-, ary
      end
    end
  end

  def test_op_lsh
    assert_send_type '(Rational) -> Array[Rational]',
                     [1r, 2r, 3r], :<<, 4r

    assert_send_type '(Rational) -> ArrayInstanceTest::ArraySubclass[Rational]',
                     ArraySubclass.new([1r, 2r, 3r]), :<<, 4r
  end

  def test_op_cmp
    with_untyped.and [2r], [1r, 3r], [1r, 2r], [1r, 0r] do |other|
      assert_send_type  '(untyped) -> Integer?',
                        [1r, 2r], :<=>, other
    end
  end

  def test_op_eq
    with_untyped.and [1r] do |untyped|
      assert_send_type  '(untyped) -> bool',
                        [1r], :==, untyped
    end
  end

  def test_op_aref(method: :[])
    with_int 1 do |index|
      assert_send_type  '(int) -> Rational',
                        [1r, 2r], method, index
      assert_send_type  '(int) -> nil',
                        [1r], method, index
    end

    with_int 2 do |start|
      with_int 1 do |length|
        assert_send_type  '(int, int) -> Array[Rational]',
                          [1r, 2r, 3r], method, start, length
        assert_send_type  '(int, int) -> nil',
                          [1r], method, start, length
      end
    end

    with_range with_int(2).and_nil, with_int(1).and_nil do |range|
      assert_send_type  '(range[int?]) -> Array[Rational]?',
                        [1r, 2r, 3r], method, range
    end
  end

  def test_slice
    test_op_aref(method: :slice)
  end

  def test_op_aset
    with_int 1 do |index|
      assert_send_type  '(int, Rational) -> Rational',
                        [1r, 2r], :[]=, index, 3r
    end

    with_range with_int(2).and_nil, with_int(1).and_nil do |range|
      with_array 4r do |ary|
        assert_send_type  '[T < _ToAry[Rational]] (range[int?], T) -> T',
                          [1r, 2r, 3r], :[]=, range, ary
      end

      assert_send_type  '(range[int?], Rational) -> Rational',
                        [1r, 2r, 3r], :[]=, range, 4r
    end

    with_int 2 do |start|
      with_int 1 do |length|
        with_array 4r do |ary|
          assert_send_type  '[T < _ToAry[Rational]] (int, int, T) -> T',
                            [1r, 2r, 3r], :[]=, start, length, ary
        end

        assert_send_type  '(int, int, Rational) -> Rational',
                          [1r, 2r, 3r], :[]=, start, length, 4r
      end
    end
  end

  def test_any?
    assert_send_type '() -> bool',
                     [], :any?
    assert_send_type '() -> bool',
                     [1r, 2r, 3r], :any?
    assert_send_type '(singleton(Rational)) -> bool',
                     [1r, 2r, 3r], :any?, Rational
    assert_send_type '() { (Rational) -> boolish } -> bool',
                     [1r, 2r, 3r], :any? do :true end
  end

  def test_all?
    assert_send_type '() -> bool',
                     [], :all?
    assert_send_type '() -> bool',
                     [1r, 2r, 3r], :all?
    assert_send_type '(singleton(Rational)) -> bool',
                     [1r, 2r, 3r], :all?, Rational
    assert_send_type '() { (Rational) -> boolish } -> bool',
                     [1r, 2r, 3r], :all? do :true end
  end

  def test_assoc
    with_untyped.and 1r, :a, 'b' do |object|
      next unless defined? object.==

      assert_send_type  '(untyped) -> Array[untyped]?',
                        [{foo: 3}, [1r, 1i], [:a, :b, :c], ['b']], :assoc, object
    end
  end

  def test_at
    with_int 1 do |index|
      assert_send_type  '(int) -> Rational',
                        [1r, 2r], :at, index
      assert_send_type  '(int) -> nil',
                        [1r], :at, index
    end
  end

  def test_bsearch
    omit 'todo'
  end

  def test_bsearch_index
    omit 'todo'
  end

  def test_clear
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :clear
  end

  def test_collect(method: :collect)
    omit 'todo'
  end

  def test_map
    test_collect(method: :map)
  end

  def test_collect!(method: :collect!)
    omit 'todo'
  end

  def test_map!
    test_collect!(method: :map!)
  end

  def test_combination
    omit 'todo'
  end

  def test_compact
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r], :compact
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, nil, 3r], :compact
  end

  def test_compact!
    assert_send_type  '() -> nil',
                      [1r, 2r, 3r], :compact!
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, nil, 3r], :compact!
  end

  def test_concat
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :concat
    with_array 3r do |array1|
      assert_send_type  '(*array[Rational]) -> Array[Rational]',
                        [1r, 2r], :concat, array1

      with_array 4r do |array2|
        assert_send_type  '(*array[Rational]) -> Array[Rational]',
                          [1r, 2r], :concat, array1, array2
      end
    end
  end

  def test_count
    assert_send_type  '() -> Integer',
                      [], :count
    assert_send_type  '() -> Integer',
                      [1r], :count
    assert_send_type  '() { (Rational) -> boolish } -> Integer',
                      [1r, 2r, 3r], :count do |x| x >= 2 end

    with_untyped.and 1r do |untyped|
      next unless defined? untyped.==
      assert_send_type  '(untyped) -> Integer',
                        [1r, 2r], :count, untyped
    end
  end

  def test_cycle
    omit 'todo'
  end

  def test_deconstruct
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :deconstruct
    assert_send_type  '() -> ArrayInstanceTest::ArraySubclass[Rational]',
                      ArraySubclass.new([1r, 2r]), :deconstruct
  end

  def test_delete
    with_untyped.and 1r do |untyped|
      next unless defined? untyped.==

      assert_send_type  '(untyped) -> Rational?',
                        [1r], :delete, untyped
      assert_send_type  '[S] (S) { (S) -> Complex } -> (Rational | Complex) ',
                        [1r], :delete, untyped do 1i end
    end
  end

  def test_delete_at
    with_int 2 do |index|
      assert_send_type  '(int) -> Rational',
                        [1r, 2r, 3r], :delete_at, index
      assert_send_type  '(int) -> nil',
                        [1r, 2r], :delete_at, index
    end
  end

  def test_delete_if(method: :delete_if)
    omit 'todo'
  end

  def test_difference
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :difference

    with_array 2r, 3r do |array1|
      with_array 1, :a, 'b' do |array2|
        assert_send_type  '(*array[untyped]) -> Array[Rational]',
                          [1r, 2r], :difference, array1, array2
      end
    end
  end

  def test_dig
    with_int 2 do |index|
      assert_send_type  '(int) -> nil',
                        [1r, 2r], :dig, index
      assert_send_type  '(int) -> Rational',
                        [1r, 2r, 3r], :dig, index

      assert_send_type  '(int, untyped) -> untyped',
                        [1r, [3]], :dig, index, 0
      assert_send_type  '(int, untyped, *untyped) -> untyped',
                        [1r, [[3]]], :dig, index, 0, 0

      assert_send_type  '(int, untyped) -> untyped',
                        [1r, 2r, [3]], :dig, index, 0
      assert_send_type  '(int, untyped, *untyped) -> untyped',
                        [1r, 2r, [[3]]], :dig, index, 0, 0
    end
  end

  def test_drop
    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :drop, count
    end
  end

  def test_drop_while
    omit 'todo'
  end

  def test_each
    omit 'todo'
  end

  def test_each_index
    omit 'todo'
  end

  def test_empty?
    assert_send_type  '() -> bool',
                      [], :empty?
    assert_send_type  '() -> bool',
                      [1r], :empty?
  end

  def test_eql?
    with_untyped.and [1r] do |untyped|
      assert_send_type  '(untyped) -> bool',
                        [1r], :eql?, untyped
    end
  end

  def test_fetch
    with_int 2 do |index|
      assert_send_type  '(int) -> Rational',
                        [1r, 2r, 3r], :fetch, index

      assert_send_type  '(int, Complex) -> Complex',
                        [1r, 2r], :fetch, index, 1i
      assert_send_type  '(int, Complex) -> Rational',
                        [1r, 2r, 3r], :fetch, index, 1i

      assert_send_type  '[I < _ToInt] (I) { (I) -> Complex } -> Complex',
                        [1r, 2r], :fetch, index do 1i end
      assert_send_type  '[I < _ToInt] (I) { (I) -> Complex } -> Rational',
                        [1r, 2r, 3r], :fetch, index do 1i end
    end
  end

  def test_fetch_values
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :fetch_values
    assert_send_type  '() { (Integer) -> void } -> Array[Rational]',
                      [1r, 2r], :fetch_values do end

    with_int 1 do |index1|
      with_int 2 do |index2|
        assert_send_type  '(*int) -> Array[Rational]',
                          [1r, 2r, 3r], :fetch_values, index1, index2
        assert_send_type  '[I < _ToInt] (*I) { (I) -> void } -> Array[Rational]',
                          [1r, 2r, 3r], :fetch_values, index1, index2 do fail end
        assert_send_type  '[I < _ToInt] (*I) { (I) -> Complex } -> Array[Rational | Complex]',
                          [1r, 2r], :fetch_values, index1, index2 do |x| x.to_int.i end
      end
    end
  end

  def test_fill
    assert_send_type  '(Rational) -> Array[Rational]',
                      [1r, 2r, 3r, 4r], :fill, 2r
    with_int(1).and_nil do |start|
      assert_send_type  '(Rational, int?) -> Array[Rational]',
                        [1r, 2r, 3r, 4r], :fill, 2r, start

      with_int(3).and_nil do |length|
        assert_send_type  '(Rational, int?, int?) -> Array[Rational]',
                          [1r, 2r, 3r, 4r], :fill, 2r, start, length
      end
    end

    with_range with_int(1).and_nil, with_int(3).and_nil do |range|
      assert_send_type  '(Rational, range[int?]) -> Array[Rational]',
                        [1r, 2r, 3r, 4r], :fill, 2r, range
    end

    assert_send_type  '() { (Integer) -> Rational } -> Array[Rational]',
                      [1r, 2r, 3r, 4r], :fill do 1r end

    with_int(1).and_nil do |start|
      assert_send_type  '(int?) { (Integer) -> Rational } -> Array[Rational]',
                        [1r, 2r, 3r, 4r], :fill, start do 1r end

      with_int(3).and_nil do |length|
        assert_send_type  '(int?, int?) { (Integer) -> Rational } -> Array[Rational]',
                          [1r, 2r, 3r, 4r], :fill, start, length do 1r end
      end
    end
  end

  def test_find(method: :find)
    omit 'todo'
  end

  def test_detect
    test_find(method: :detect)
  end

  def test_find_index(method: :find_index)
    omit 'todo'
  end

  def test_index
    test_find_index(method: :index)
  end

  def test_first
    assert_send_type  '() -> nil',
                      [], :first
    assert_send_type  '() -> Rational',
                      [1r, 2r], :first

    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [], :first, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :first, count
    end
  end

  def test_flatten
    assert_send_type  '() -> Array[untyped]',
                      [[1r, 2r]], :flatten

    with_int(1).and_nil do |level|
      assert_send_type  '(int?) -> Array[untyped]',
                        [[1r, 2r]], :flatten, level
    end
  end

  def test_flatten!
    assert_send_type  '() -> nil',
                      ArraySubclass.new([1r, 2r]), :flatten!
    assert_send_type  '() -> ArrayInstanceTest::ArraySubclass[untyped]',
                      ArraySubclass.new([[1r, 2r]]), :flatten!

    with_int(1).and_nil do |level|
      assert_send_type  '(int?) -> nil',
                        ArraySubclass.new([1r, 2r]), :flatten!, level
      assert_send_type  '(int?) -> ArrayInstanceTest::ArraySubclass[untyped]',
                        ArraySubclass.new([[1r, 2r]]), :flatten!, level
    end
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      [], :hash
    assert_send_type  '() -> Integer',
                      [1r, 2r], :hash
  end

  def test_include?
    with_untyped.and 1r do |untyped|
      next unless defined? untyped.==
      assert_send_type  '(top) -> bool',
                        [1r, 2r], :include?, untyped
    end
  end

  def test_insert
    with_int 1 do |index|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r, 3r], :insert, index
      assert_send_type  '(int, *Rational) -> Array[Rational]',
                        [1r, 2r, 3r], :insert, index, 3r, 4r
    end
  end

  def test_inspect(method: :inspect)
    assert_send_type  '() -> String',
                      [], method
    assert_send_type  '() -> String',
                      [1r, 2r], method
  end

  def test_to_s
    test_inspect(method: :to_s)
  end

  def test_intersect?
    with_array 1r, 3r do |array|
      assert_send_type  '(array[untyped]) -> bool',
                        [1r, 2r, 3r], :intersect?, array
    end

    with_array :a, :b do |array|
      assert_send_type  '(array[untyped]) -> bool',
                        [1r, 2r, 3r], :intersect?, array
    end
  end

  def test_intersection
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r], :intersection

    with_array 1r, 2r, 4r do |array1|
      with_array 1, 2, 4 do |array2|
        assert_send_type  '(*array[untyped]) -> Array[Rational]',
                          [1r, 2r, 3r], :intersection, array1, array2
      end
    end
  end

  def test_join
    assert_send_type  '() -> String',
                      [1r, 2r], :join

    with_string("x").and_nil do |sep|
      assert_send_type  '(string?) -> String',
                        [1r, 2r], :join, sep
    end
  end

  def test_keep_if
    omit 'todo'
  end

  def test_last
    assert_send_type  '() -> nil',
                      [], :last
    assert_send_type  '() -> Rational',
                      [1r, 2r], :last

    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [], :last, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :last, count
    end
  end

  def test_length(method: :length)
    assert_send_type  '() -> Integer',
                      [], method
    assert_send_type  '() -> Integer',
                      [1r, 2r], method
  end

  def test_size
    test_length(method: :size)
  end

  def test_max
    ary = 10.times.map { |x| Rational(x) }.shuffle

    assert_send_type  '() -> nil',
                      [], :max
    assert_send_type  '() -> Rational',
                      ary, :max
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> Rational',
                      ary, :max do |a, b| ComparableToZero.new(a <=> b) end

    with_int 3 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        ary, :max, count
      assert_send_type  '(int) { (Rational, Rational) -> Comparable::_CompareToZero } -> Array[Rational]',
                        ary, :max, count do |a, b| ComparableToZero.new(a <=> b) end
    end
  end

  def test_min
    ary = 10.times.map { |x| Rational(x) }.shuffle

    assert_send_type  '() -> nil',
                      [], :min
    assert_send_type  '() -> Rational',
                      ary, :min
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> Rational',
                      ary, :min do |a, b| ComparableToZero.new(a <=> b) end

    with_int 3 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        ary, :min, count
      assert_send_type  '(int) { (Rational, Rational) -> Comparable::_CompareToZero } -> Array[Rational]',
                        ary, :min, count do |a, b| ComparableToZero.new(a <=> b) end
    end
  end

  def test_minmax
    ary = 10.times.map { |x| Rational(x) }.shuffle

    assert_send_type  '() -> [nil, nil]',
                      [], :minmax
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> [nil, nil]',
                      [], :minmax do end
    assert_send_type  '() -> [Rational, Rational]',
                      ary, :minmax
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> [Rational, Rational]',
                      ary, :minmax do |a, b| ComparableToZero.new(a <=> b) end
  end

  def test_pack
    with_string 'ccc' do |fmt|
      assert_send_type  '(string) -> String',
                        [1, 2, 3], :pack, fmt

      assert_send_type  '(string, buffer: nil) -> String',
                        [1, 2, 3], :pack, fmt, buffer: nil
      assert_send_type  '(string, buffer: String) -> String',
                        [1, 2, 3], :pack, fmt, buffer: +''
      refute_send_type  '(string, buffer: _ToStr) -> String',
                        [1,2,3], :pack, fmt, buffer: ToStr.new(+'')
    end
  end

  def test_permutation
    omit 'todo'
  end

  def test_pop
    assert_send_type  '() -> nil',
                      [], :pop
    assert_send_type  '() -> Rational',
                      [1r], :pop

    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r, 3r], :pop, count
    end
  end

  def test_product
    assert_send_type  '() -> Array[[Rational]]',
                      [1r, 2r], :product
    assert_send_type  '() { ([Rational]) -> void } -> ArrayInstanceTest::ArraySubclass[Rational]',
                      ArraySubclass.new([1r, 2r]), :product do end

    with_array 1i, 2i do |array1|
      assert_send_type  '(array[Complex]) -> Array[[Rational, Complex]]',
                        [1r, 2r], :product, array1
      assert_send_type  '(array[Complex]) { ([Rational, Complex]) -> void } -> ArrayInstanceTest::ArraySubclass[Rational]',
                        ArraySubclass.new([1r, 2r]), :product, array1 do end

      with_array 1.0, 2.0 do |array2|
        assert_send_type  '(array[Complex], array[Float]) -> Array[[Rational, Complex, Float]]',
                          [1r, 2r], :product, array1, array2
        assert_send_type  '(array[Complex], array[Float]) { ([Rational, Complex, Float]) -> void } -> ArrayInstanceTest::ArraySubclass[Rational]',
                          ArraySubclass.new([1r, 2r]), :product, array1, array2 do end

        with_array 1, 2 do |array3|
          assert_send_type  '(*array[Complex | Float | Integer]) -> Array[Array[Rational | Complex | Float | Integer]]',
                            [1r, 2r], :product, array1, array2, array3
          assert_send_type  '(*array[Complex | Float | Integer]) { (Array[Rational | Complex | Float | Integer]) -> void } -> ArrayInstanceTest::ArraySubclass[Rational]',
                            ArraySubclass.new([1r, 2r]), :product, array1, array2, array3 do end
        end
      end
    end
  end

  def test_push(method: :push)
    assert_send_type  '() -> Array[Rational]',
                      [1r], method
    assert_send_type  '(*Rational) -> Array[Rational]',
                      [1r], method, 2r
    assert_send_type  '(*Rational) -> Array[Rational]',
                      [1r], method, 2r, 3r
  end

  def test_append
    test_push(method: :append)
  end

  def test_reject!
    omit 'todo'
  end

  def test_repeated_combination
    omit 'todo'
  end

  def test_repeated_permutation
    omit 'todo'
  end

  def test_replace(method: :replace)
    with_array 3r, 4r do |array|
      assert_send_type  '(array[Rational]) -> Array[Rational]',
                        [1r, 2r], method, array
    end
  end

  def test_reverse
    assert_send_type  '() -> Array[Rational]',
                      [], :reverse
    assert_send_type  '() -> Array[Rational]',
                      [1r], :reverse
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :reverse
  end

  def test_reverse!
    assert_send_type  '() -> Array[Rational]',
                      [], :reverse!
    assert_send_type  '() -> Array[Rational]',
                      [1r], :reverse!
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :reverse!
  end

  def test_reverse_each
    omit 'todo'
  end

  def test_rfind
    omit 'todo'
  end

  def test_rindex
    omit 'todo'
  end

  def test_rotate
    assert_send_type  '() -> Array[Rational]',
                      [], :rotate
    assert_send_type  '() -> Array[Rational]',
                      [1r], :rotate
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :rotate
    with_int 1 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [], :rotate, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r], :rotate, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :rotate, count
    end
  end

  def test_rotate!
    assert_send_type  '() -> Array[Rational]',
                      [], :rotate!
    assert_send_type  '() -> Array[Rational]',
                      [1r], :rotate!
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :rotate!
    with_int 1 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [], :rotate!, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r], :rotate!, count
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :rotate!, count
    end
  end

  def test_sample
    assert_send_type  '() -> nil',
                      [], :sample
    assert_send_type  '(random: Array::_Rand) -> nil',
                      [], :sample, random: RngGen.new

    assert_send_type  '() -> Rational',
                      [1r, 2r, 3r], :sample
    assert_send_type  '(random: Array::_Rand) -> Rational',
                      [1r, 2r, 3r], :sample, random: RngGen.new

    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r, 3r], :sample, count
      assert_send_type  '(int, random: Array::_Rand) -> Array[Rational]',
                        [1r, 2r, 3r], :sample, count, random: RngGen.new
    end
  end

  def test_select(method: :select)
    omit 'todo'
  end

  def test_filter
    test_select(method: :filter)
  end

  def test_select!(method: :select!)
    omit 'todo'
  end

  def test_filter!
    test_select(method: :filter!)
  end

  def test_shift
    assert_send_type  '() -> nil',
                      [], :shift
    assert_send_type  '() -> Rational',
                      [1r], :shift

    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r, 3r], :shift, count
    end
  end

  def test_shuffle
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r], :shuffle

    assert_send_type  '(random: Array::_Rand) -> Array[Rational]',
                      [1r, 2r, 3r], :shuffle, random: RngGen.new
  end

  def test_shuffle!
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r], :shuffle!

    assert_send_type  '(random: Array::_Rand) -> Array[Rational]',
                      [1r, 2r, 3r], :shuffle!, random: RngGen.new
  end

  def test_slice!
    with_int 1 do |index|
      assert_send_type  '(int) -> Rational',
                        [1r, 2r], :slice!, index
      assert_send_type  '(int) -> nil',
                        [1r], :slice!, index
    end

    with_int 2 do |start|
      with_int 1 do |length|
        assert_send_type  '(int, int) -> Array[Rational]',
                          [1r, 2r, 3r], :slice!, start, length
        assert_send_type  '(int, int) -> nil',
                          [1r], :slice!, start, length
      end
    end

    with_range with_int(2).and_nil, with_int(1).and_nil do |range|
      assert_send_type  '(range[int?]) -> Array[Rational]?',
                        [1r, 2r, 3r], :slice!, range
    end
  end

  def test_sort
    ary = 10.times.map { |x| Rational(x) }.shuffle

    assert_send_type  '() -> Array[Rational]',
                      ary, :sort
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> Array[Rational]',
                      ary, :sort do |a, b| ComparableToZero.new(a <=> b) end
  end

  def test_sort!
    ary = 10.times.map { |x| Rational(x) }.shuffle

    assert_send_type  '() -> Array[Rational]',
                      ary, :sort!
    assert_send_type  '() { (Rational, Rational) -> Comparable::_CompareToZero } -> Array[Rational]',
                      ary, :sort! do |a, b| ComparableToZero.new(a <=> b) end
  end

  def test_sort_by!
    omit 'todo'
  end

  def test_sum
    assert_send_type  '() -> untyped',
                      [1, 2r, 3.0, 4i], :sum

    with 5, 6r, 7.0, 8i do |init|
      assert_send_type  '(untyped) -> untyped',
                        [1, 2r, 3.0, 4i], :sum, init
    end

    assert_send_type  '() { (Rational) -> untyped } -> untyped',
                      [1r, 2r, 3r], :sum do |ele| ele.i end

    with 5, 6r, 7.0, 8i do |init|
      assert_send_type  '(untyped) { (Rational) -> untyped } -> untyped',
                        [1r, 2r, 3r], :sum, init do |ele| ele.i end
    end

    # Test an extremely esoteric edgecase, which any updates to the signature will have to allow for
    outer = BlankSlate.new
    def outer.+(rhs)
      inner = BlankSlate.new
      ::Kernel.instance_method(:instance_variable_set).bind_call(inner, :@rhs, rhs)
      def inner.+(rhs) = [:innermost, @rhs, rhs]
      inner
    end

    assert_send_type  '(untyped) -> [:innermost, 1, 2]',
                      [1, 2], :sum, outer
  end

  def test_take
    with_int 2 do |count|
      assert_send_type  '(int) -> Array[Rational]',
                        [1r, 2r], :take, count
    end
  end

  def test_take_while
    omit 'todo'
  end

  def test_to_a
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :to_a
    assert_send_type  '() -> Array[Rational]',
                      ArraySubclass.new([1r, 2r]), :to_a
  end

  def test_to_ary
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :to_ary
    assert_send_type  '() -> ArrayInstanceTest::ArraySubclass[Rational]',
                      ArraySubclass.new([1r, 2r]), :to_ary
  end

  def test_to_h
    assert_send_type  '() -> Hash[untyped, untyped]',
                      [], :to_h
    assert_send_type  '() -> Hash[untyped, untyped]',
                      [[:a, 1]], :to_h

    assert_send_type  '() { (Rational) -> Hash::_Pair[Rational, Complex] } -> Hash[Rational, Complex]',
                      [1r, 2r], :to_h do |x| ToArray.new(x, x.i) end
  end

  def test_transpose
    assert_send_type  '() -> Array[Array[Rational]]',
                      [], :transpose
    assert_send_type  '() -> Array[Array[Rational]]',
                      [[1r]], :transpose
    assert_send_type  '() -> Array[Array[Rational]]',
                      [[1r, 2r, 3r], [4r, 5r, 6r]], :transpose
  end

  def test_union
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :union

    with_array 2r, 3r do |array1|
      with_array 1, :a, 'b' do |array2|
        assert_send_type  '[T] (*array[T]) -> Array[Rational | T]',
                          [1r, 2r], :union, array1, array2
      end
    end

  end

  def test_uniq
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r, 2r, 1r], :uniq
    assert_send_type  '() { (Rational) -> Hash::_Key } -> Array[Rational]',
                      [1r, 2r, 3r, 2r, 1r], :uniq do |x| HashKey.new x end
  end

  def test_uniq!
    assert_send_type  '() -> nil',
                      [1r, 2r, 3r], :uniq!
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r, 3r, 2r, 1r], :uniq!
    assert_send_type  '() { (Rational) -> Hash::_Key } -> nil',
                      [1r, 2r, 3r], :uniq! do |x| HashKey.new x end
    assert_send_type  '() { (Rational) -> Hash::_Key } -> Array[Rational]',
                      [1r, 2r, 3r, 2r, 1r], :uniq! do |x| HashKey.new x end
  end

  def test_unshift(method: :unshift)
    assert_send_type  '() -> Array[Rational]',
                      [1r], method
    assert_send_type  '(*Rational) -> Array[Rational]',
                      [1r], method, 0r
    assert_send_type  '(*Rational) -> Array[Rational]',
                      [1r], method, -1r, 0r
  end

  def test_prepend
    test_unshift(method: :prepend)
  end

  def test_values_at
    ary = 10.times.map { |x| Rational(x) }

    assert_send_type  '() -> Array[Rational]',
                      ary, :values_at

    with_int 3 do |index1|
      with_int 99999 do |index2|
        with_range with_int(3).and_nil, with_int(-2).and_nil do |range|
          assert_send_type  '(*int | range[int?]) -> Array[Rational?]',
                            ary, :values_at, index1, index2, range
        end
      end
    end
  end

  def test_zip
    assert_send_type  '() -> Array[[Rational]]',
                      [1r, 2r, 3r], :zip
    assert_send_type  '() { ([Rational]) -> void } -> nil',
                      [1r, 2r, 3r], :zip do end

    with_each 1, 2 do |iter1|
      assert_send_type  '(_Each[Integer]) -> Array[[Rational, Integer?]]',
                        [1r, 2r, 3r], :zip, iter1
      assert_send_type  '(_Each[Integer]) { ([Rational, Integer?]) -> void } -> nil',
                        [1r, 2r, 3r], :zip, iter1 do end

      with_each 1i, 2i do |iter2|
        assert_send_type  '(_Each[Integer], _Each[Complex]) -> Array[[Rational, Integer?, Complex?]]',
                          [1r, 2r, 3r], :zip, iter1, iter2
        assert_send_type  '(_Each[Integer], _Each[Complex]) { ([Rational, Integer?, Complex?]) -> void } -> nil',
                          [1r, 2r, 3r], :zip, iter1, iter2 do end

        with_each 1.0, 2.0 do |iter3|
          assert_send_type  '(*_Each[Integer | Complex | Float]) -> Array[Array[Rational | Integer | Complex | Float | nil]]',
                            [1r, 2r, 3r], :zip, iter1, iter2, iter3
          assert_send_type  '(*_Each[Integer | Complex | Float]) { (Array[Rational | Integer | Complex | Float | nil]) -> void } -> nil',
                            [1r, 2r, 3r], :zip, iter1, iter2, iter3 do end
        end
      end
    end
  end

  def test_op_or
    with_array 1r, 1i do |other|
      assert_send_type  '(array[Complex]) -> Array[Rational | Complex]',
                        [1r, 2r], :|, other
    end
  end

  def test_initialize_copy
    assert_visibility :private, :initialize_copy
    test_replace(method: :initialize_copy)
  end

  def test_none?
    assert_send_type '() -> bool',
                     [], :none?
    assert_send_type '() -> bool',
                     [1r, 2r, 3r], :none?
    assert_send_type '(singleton(Rational)) -> bool',
                     [1r, 2r, 3r], :none?, Rational
    assert_send_type '() { (Rational) -> boolish } -> bool',
                     [1r, 2r, 3r], :none? do :true end
  end

  def test_one?
    assert_send_type '() -> bool',
                     [], :one?
    assert_send_type '() -> bool',
                     [1r, 2r, 3r], :one?
    assert_send_type '(singleton(Rational)) -> bool',
                     [1r, 2r, 3r], :one?, Rational
    assert_send_type '() { (Rational) -> boolish } -> bool',
                     [1r, 2r, 3r], :one? do :true end
  end

  def test_rassoc
    with_untyped.and 1r, :a, 'b' do |object|
      next unless defined? object.==
      assert_send_type  '(untyped) -> Array[untyped]?',
                        [{foo: 3}, [1r, 1i], [:a, :b, :c], ['b']], :rassoc, object
    end
  end

  def test_reject
    test_delete_if(method: :reject)
  end

  def test_freeze
    assert_send_type  '() -> Array[Rational]',
                      [1r, 2r], :freeze
  end
end
