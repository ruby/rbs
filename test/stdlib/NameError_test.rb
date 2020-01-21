require_relative "test_helper"

class NameErrorTest < StdlibTest
  target NameError
  using hook.refinement

  def test_initialize
    NameError.new
    NameError.new('')
    NameError.new('', receiver: 42)
  end

  def test_receiver
    begin
      1.foo
    rescue NameError => error
      error.receiver
    end
  end
end
