require_relative "test_helper"

class FalseClassTest < StdlibTest
  target FalseClass
  using hook.refinement

  def test_not
    !false
  end

  def test_and
    false & true
  end
end
