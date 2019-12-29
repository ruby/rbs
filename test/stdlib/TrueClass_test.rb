require_relative "test_helper"

class TrueClassTest < StdlibTest
  target TrueClass
  using hook.refinement

  def test_eqq
    true === true
    true === false
  end

  def test_inspect
    true.inspect
  end

  def test_to_s
    true.to_s
  end
end
