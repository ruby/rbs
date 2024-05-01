require_relative "test_helper"

class Thread::BacktraceSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Thread::Backtrace)"

  def test_limit
    assert_send_type  "() -> ::Integer",
                      Thread::Backtrace, :limit
  end
end
