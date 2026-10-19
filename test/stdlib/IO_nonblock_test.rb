require_relative "test_helper"
require "io/nonblock"

class IONonblockTest < Test::Unit::TestCase
  include TestHelper

  library "io-nonblock"
  testing "::IO"

  def setup
    @r, @w = IO.pipe
  end

  def teardown
    @r.close
    @w.close
  end

  def test_nonblock
    assert_send_type "() { (IO) -> Integer } -> Integer",
                     @r, :nonblock do 1 end
    assert_send_type "(bool) { (IO) -> Integer } -> Integer",
                     @r, :nonblock, false do 1 end
  end

  def test_nonblock_assign
    assert_send_type "(bool) -> IO",
                     @r, :nonblock=, true
    assert_send_type "(bool) -> IO",
                     @r, :nonblock=, false
  end

  def test_nonblock?
    assert_send_type "() -> bool",
                     @r, :nonblock?
  end
end
