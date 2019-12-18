require_relative "test_helper"

class ExceptionTest < StdlibTest
  target Exception
  using hook.refinement

  def test_full_message
    Exception.new.full_message
    Exception.new.full_message(highlight: true)
    Exception.new.full_message(highlight: false)
    Exception.new.full_message(order: :top)
    Exception.new.full_message(order: :bottom)
  end
end
