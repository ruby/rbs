require_relative "test_helper"

# Currently, require "prime" fails due to .new handling
return

require "prime"

class PrimeTest < StdlibTest
  target Prime
  library "prime"

  using hook.refinement

  def test_each
    Prime.each { break }
    Prime.each(10) { }
  end

  def test_prime?
    Prime.prime?(10)
    Prime.prime?(11)
  end

  def test_int_from_prime_division
    Prime.int_from_prime_division([[2, 3], [3, 4]])
  end

  def test_prime_division
    Prime.prime_division(6)
  end
end
