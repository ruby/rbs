require_relative "test_helper"

class RandomSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "singleton(::Random)"


  def test_srand
    assert_send_type  "(?::Integer number) -> ::Integer",
                      Random, :srand
    assert_send_type  "(?::Integer number) -> ::Integer",
                      Random, :srand, 123456789
  end

  def test_rand
    assert_send_type  "() -> ::Float",
                      Random, :rand
    assert_send_type  "(::Integer max) -> ::Integer",
                      Random, :rand, 10
    assert_send_type  "(::Float max) -> ::Float",
                      Random, :rand, 0.5
    assert_send_type  "(::Range[::Integer] range) -> ::Integer",
                      Random, :rand, (1..10)
    assert_send_type  "(::Range[::Float] range) -> ::Float",
                      Random, :rand, (0.1..0.5)
  end

  def test_bytes
    assert_send_type  "(::Integer) -> ::String",
                      Random, :bytes, 1
  end

  def test_new_seed
    assert_send_type  "() -> ::Integer",
                      Random, :new_seed
  end

  def test_seed
    assert_send_type  "() -> Integer",
                      Random, :seed
  end

  def test_urandom
    assert_send_type  "(untyped) -> String",
                      Random, :urandom, 12
  end
end

class RandomTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::Random"


  def test_double_equal
    assert_send_type  "(self other) -> bool",
                      Random.new, :==, Random.new
  end

  def test_initialize_copy
    assert_send_type  "(self object) -> self",
                      Random.new, :initialize_copy, Random.new
  end

  def test_left
    assert_send_type  "() -> Integer",
                      Random.new, :left
  end

  def test_marshal_dump
    assert_send_type  "() -> Array[Integer]",
                      Random.new, :marshal_dump
  end

  def test_marshal_load
    assert_send_type  "(Array[Integer]) -> self",
                      Random.new, :marshal_load, [1, 2, 3]
  end

  def test_state
    assert_send_type  "() -> Integer",
                      Random.new, :state
  end
end
