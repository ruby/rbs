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
    omit 'todo'
  end

  def test_count
    omit 'todo'
  end

  def test_cycle
    omit 'todo'
  end

  def test_deconstruct
    omit 'todo'
  end

  def test_delete
    omit 'todo'
  end

  def test_delete_at
    omit 'todo'
  end

  def test_delete_if
    omit 'todo'
  end

  def test_difference
    omit 'todo'
  end

  def test_dig
    omit 'todo'
  end

  def test_drop
    omit 'todo'
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
    omit 'todo'
  end

  def test_fetch
    omit 'todo'
  end

  def test_fetch_values
    omit 'todo'
  end

  def test_fill
    omit 'todo'
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
    omit 'todo'
  end

  def test_flatten
    omit 'todo'
  end

  def test_flatten!
    omit 'todo'
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      [], :hash
    assert_send_type  '() -> Integer',
                      [1r, 2r], :hash
  end

  def test_include?
    omit 'todo'
  end

  def test_insert
    omit 'todo'
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
    omit 'todo'
  end

  def test_intersection
    omit 'todo'
  end

  def test_join
    omit 'todo'
  end

  def test_keep_if
    omit 'todo'
  end

  def test_last
    omit 'todo'
  end

  def test_length(method: :length)
    omit 'todo'
  end

  def test_size
    test_length(method: :size)
  end

  def test_max
    omit 'todo'
  end

  def test_minmax
    omit 'todo'
  end

  def test_pack
    omit 'todo'
  end

  def test_permutation
    omit 'todo'
  end

  def test_pop
    omit 'todo'
  end

  def test_product
    omit 'todo'
  end

  def test_push(method: :push)
    omit 'todo'
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
    omit 'todo'
  end

  def test_reverse
    omit 'todo'
  end

  def test_reverse!
    omit 'todo'
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
    omit 'todo'
  end

  def test_rotate!
    omit 'todo'
  end

  def test_sample
    omit 'todo'
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
    omit 'todo'
  end

  def test_shuffle
    omit 'todo'
  end

  def test_shuffle!
    omit 'todo'
  end

  def test_slice!
    omit 'todo'
  end

  def test_sort
    omit 'todo'
  end

  def test_sort!
    omit 'todo'
  end

  def test_sort_by!
    omit 'todo'
  end

  def test_sum
    omit 'todo'
  end

  def test_take
    omit 'todo'
  end

  def test_take_while
    omit 'todo'
  end

  def test_to_a
    omit 'todo'
  end

  def test_to_ary
    omit 'todo'
  end

  def test_to_h
    omit 'todo'
  end

  def test_transpose
    omit 'todo'
  end

  def test_union
    omit 'todo'
  end

  def test_uniq
    omit 'todo'
  end

  def test_uniq!
    omit 'todo'
  end

  def test_unshift(method: :unshift)
    omit 'todo'
  end

  def test_prepend
    test_unshift(method: :prepend)
  end

  def test_values_at
    omit 'todo'
  end

  def test_zip
    omit 'todo'
  end

  def test_op_or
    with_array 1r, 1i do |other|
      assert_send_type  '(array[Complex]) -> Array[Rational | Complex]',
                        [1r, 2r], :|, other
    end
  end

  def test_initialize_copy
    test_replace(method: :initialize_copy)
  end

  def test_min
    omit 'todo'
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

  def test_prepend
    omit 'todo'
  end

  def test_rassoc
    with_untyped.and 1r, :a, 'b' do |object|
      next unless defined? object.==
      assert_send_type  '(untyped) -> Array[untyped]?',
                        [{foo: 3}, [1r, 1i], [:a, :b, :c], ['b']], :rassoc, object
    end
  end

  def test_reject
    omit 'todo'
  end
end
