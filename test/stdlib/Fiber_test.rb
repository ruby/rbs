require_relative "test_helper"

class FiberTest < StdlibTest
  target Fiber
  using hook.refinement

  def test_initialize
    Fiber.new {}
  end
end
