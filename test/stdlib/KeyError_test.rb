require_relative "test_helper"

class KeyErrorTest < StdlibTest
  target KeyError
  using hook.refinement

  def test_initialize
    KeyError.new
    KeyError.new('')
    KeyError.new('', key: 42)
    KeyError.new('', receiver: 42)
    KeyError.new('', key: 42, receiver: 42)
  end

  def test_key
    begin
      {}.fetch(:foo)
    rescue KeyError => error
      error.key
    end
  end

  def test_receiver
    begin
      {}.fetch(:foo)
    rescue KeyError => error
      error.receiver
    end
  end
end
