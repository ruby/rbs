require_relative "test_helper"

class NilClassTest < StdlibTest
  target NilClass
  using hook.refinement

  def test_and
    nil & true
  end

  def test_eqq
    nil === nil
    nil === false
  end

  def test_match
    nil =~ 42
  end

  def test_to_i
    nil.to_i
  end

  def test_nil?
    nil.nil?
  end
end
