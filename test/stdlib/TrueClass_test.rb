require_relative "test_helper"

class TrueClassTest < StdlibTest
  target TrueClass

  def test_not
    !true
  end

  def test_and
    true.&(nil)
    true.&(false)
    true.&(42)
  end

  def test_eqq
    true === true
    true === false
  end

  def test_xor
    true.^(nil)
    true.^(false)
    true.^(42)
  end

  def test_inspect
    true.inspect
  end

  def test_to_s
    true.to_s
  end

  def test_or
    true.|(nil)
  end
end
