require_relative "test_helper"

require "prime"

class PrimeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "singleton", "prime"
  testing "singleton(::Prime)"

  def test_each
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime, :each do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime, :each, 10 do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime, :each, 10, Prime::TrialDivisionGenerator.new do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) -> ::Prime::PseudoPrimeGenerator",
                      Prime, :each
  end

  def test_int_from_prime_division
    assert_send_type  "(::Array[[ ::Integer, ::Integer ]]) -> ::Integer",
                      Prime, :int_from_prime_division, [[3, 1], [19, 1]]
  end

  def test_prime?
    assert_send_type  "(::Integer value, ?::Prime::PseudoPrimeGenerator generator) -> bool",
                      Prime, :prime?, 57
  end

  def test_prime_division
    assert_send_type  "(::Integer, ?::Prime::PseudoPrimeGenerator generator) -> ::Array[[ ::Integer, ::Integer ]]",
                      Prime, :prime_division, 57
  end

  def test_instance
    assert_send_type  "() -> ::Prime",
                      Prime, :instance
  end
end

class PrimeTest < Test::Unit::TestCase
  include TypeAssertions

  library "singleton", "prime"
  testing "::Prime"


  def test_each
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime.instance, :each do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime.instance, :each, 10 do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) { (::Integer) -> void } -> void",
                      Prime.instance, :each, 10, Prime::TrialDivisionGenerator.new do break end
    assert_send_type  "(?::Integer? ubound, ?::Prime::PseudoPrimeGenerator generator) -> ::Prime::PseudoPrimeGenerator",
                      Prime.instance, :each
  end

  def test_int_from_prime_division
    assert_send_type  "(::Array[[ ::Integer, ::Integer ]]) -> ::Integer",
                      Prime.instance, :int_from_prime_division, [[3, 1], [19, 1]]
  end

  def test_prime?
    assert_send_type  "(::Integer value, ?::Prime::PseudoPrimeGenerator generator) -> bool",
                      Prime.instance, :prime?, 57
  end

  def test_prime_division
    assert_send_type  "(::Integer, ?::Prime::PseudoPrimeGenerator generator) -> ::Array[[ ::Integer, ::Integer ]]",
                      Prime.instance, :prime_division, 57
  end
end
