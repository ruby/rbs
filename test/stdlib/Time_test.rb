require_relative "test_helper"

class TimeTest < StdlibTest
  target Time
  using hook.refinement

  if RUBY_27_OR_LATER
    def test_floor
      Time.new.floor
      Time.new.floor(1)
    end

    def test_ceil
      Time.new.ceil
      Time.new.ceil(1)
    end
  end
end
