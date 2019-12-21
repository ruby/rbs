require_relative "test_helper"

class FrozenErrorTest < StdlibTest
  target FrozenError
  using hook.refinement

  def test_initialize
    FrozenError.new
    FrozenError.new('')
    if RUBY_27_OR_LATER
      FrozenError.new('', receiver: 42)
    end
  end

  if RUBY_27_OR_LATER
    def test_receiver
      begin
        ''.freeze.strip!
        raise
      rescue FrozenError => error
        error.receiver
      end
    end
  end
end
