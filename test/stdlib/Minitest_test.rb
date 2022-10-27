if ENV.key?("NO_MINITEST")
  warn "Skip testing for library 'minitest' since enable NO_MINITEST"
  return
end

require_relative "test_helper"
require 'minitest'

class MinitestSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "minitest"
  testing "singleton(::Minitest)"

  def test_clock_time
    assert_send_type  "() -> untyped",
                      Minitest, :clock_time
  end

  def test_filter_backtrace
    assert_send_type  "(untyped bt) -> untyped",
                      Minitest, :filter_backtrace, caller
  end

  def test_process_args
    assert_send_type  "(?untyped args) -> untyped",
                      Minitest, :process_args
  end

  def test_load_plugins
    assert_send_type  "() -> (nil | untyped)",
                      Minitest, :load_plugins
  end

  def test_init_plugins
    assert_send_type  "(untyped options) -> untyped",
                      Minitest, :init_plugins, {}
  end

  def test_after_run
    assert_send_type  "() { () -> untyped } -> untyped",
                      Minitest, :after_run do end
  end
end

