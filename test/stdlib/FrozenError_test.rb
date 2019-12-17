require_relative "test_helper"

class FrozenErrorTest < StdlibTest
  target FrozenError
  using hook.refinement

  def test_receiver
    begin
      ''.freeze.strip!
      raise
    rescue FrozenError => error
      error.receiver
    end
  end
end
