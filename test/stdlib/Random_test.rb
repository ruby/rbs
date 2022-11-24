require_relative "test_helper"

class RandomSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Random)"

  def test_srand
    assert_send_type  "(?::Integer number) -> ::Integer",
                      Random, :srand
  end

  def test_rand
    assert_send_type  "() -> ::Float",
                      Random, :rand
    assert_send_type  "(::Integer | ::Range[::Integer] max) -> ::Integer",
                      Random, :rand, 100
    assert_send_type  "(::Float | ::Range[::Float] max) -> ::Float",
                      Random, :rand, 100.0
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

class RandomTest < Test::Unit::TestCase
  include TypeAssertions

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
                      Random.new, :rand, 100
    assert_send_type  "(::Float | ::Range[::Float] max) -> ::Float",
                      Random.new, :rand, 100.0
  end

  def test_bytes
    assert_send_type  "(::Integer size) -> ::String",
                      Random.new, :bytes, 8
  end

  def test_seed
    assert_send_type  "() -> ::Integer",
                      Random.new, :seed
  end
end
