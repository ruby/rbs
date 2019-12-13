require_relative "test_helper"

class KeyErrorTest < StdlibTest
  target KeyError
  using hook.refinement

  def test_key
    begin
      {}.fetch(:foo)
    rescue KeyError => error
      error.key
    end
  end
end
