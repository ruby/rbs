require_relative "test_helper"

class RandomSingletonTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "singleton(::Random)"


  def test_srand
    assert_send_type  "(?::Integer number) -> ::Numeric",
                      Random, :srand
    assert_send_type  "(?::Integer number) -> ::Numeric",
                      Random, :srand, 0
  end

  def test_rand
    assert_send_type  "() -> ::Float",
                      Random, :rand
    assert_send_type  "(::Integer) -> ::Integer",
                      Random, :rand, 1
    assert_send_type  "(::Range[Integer]) -> ::Integer",
                      Random, :rand, 1..10
    assert_send_type  "(::Numeric) -> ::Integer",
                      Random, :rand, Rational(7,6)
    assert_send_type  "(::Float) -> ::Float",
                      Random, :rand, 1.5
    assert_send_type  "(::Range[Float]) -> ::Float",
                      Random, :rand, 1.5..5.5
    assert_send_type  "(::Range[Numeric]) -> ::Numeric",
                      Random, :rand, Rational(1/6)..Rational(13/6)
  end

  def test_new
    assert_send_type  "(?::Integer seed) -> ::Random",
                      Random, :new
  end

  def test_bytes
    assert_send_type  "(::Integer size) -> ::String",
                      Random, :bytes, 0
  end

  def test_new_seed
    assert_send_type  "() -> ::Integer",
                      Random, :new_seed
  end

  def test_urandom
    assert_send_type  "(::Integer) -> ::String",
                      Random, :urandom, 0
  end
end

class RandomTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::Random"

  def test_double_equal
    assert_send_type  "(untyped arg0) -> bool",
                      Random.new, :==, Random.new
  end

  def test_initialize
    assert_send_type  "(?::Integer seed) -> void",
                      Random.new, :initialize
  end

  def test_rand
    assert_send_type  "() -> ::Float",
                      Random.new, :rand
    assert_send_type  "(::Integer | ::Range[::Integer] max) -> ::Integer",
                      Random.new, :rand, 10
    assert_send_type  "(::Integer | ::Range[::Integer] max) -> ::Integer",
                      Random.new, :rand, 0..10
    assert_send_type  "(::Numeric) -> ::Integer",
                      Random.new, :rand, Rational(7,6)
    assert_send_type  "(::Float | ::Range[::Float] max) -> ::Float",
                      Random.new, :rand, 0.9
    assert_send_type  "(::Float | ::Range[::Float] max) -> ::Float",
                      Random.new, :rand, 0.1..0.9
    assert_send_type  "(::Range[Numeric]) -> ::Numeric",
                      Random.new, :rand, Rational(1/6)..Rational(13/6)
  end

  def test_bytes
    assert_send_type  "(::Integer size) -> ::String",
                      Random.new, :bytes, 1
  end

  def test_seed
    assert_send_type  "() -> ::Integer",
                      Random.new, :seed
  end
end
