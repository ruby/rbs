require_relative "test_helper"

class SignalExceptionTest < StdlibTest
  target SignalException
  using hook.refinement

  def test_signm
    SignalException.new("INT").signm
  end
end
