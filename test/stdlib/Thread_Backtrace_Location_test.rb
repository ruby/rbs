require_relative "test_helper"

class Thread::Backtrace::LocationTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Thread::Backtrace::Location"

  def test_absolute_path
    assert_send_type  "() -> ::String?",
                      caller_locations[0], :absolute_path
  end

  def test_base_label
    assert_send_type  "() -> ::String?",
                      caller_locations[0], :base_label
  end

  def test_label
    assert_send_type  "() -> ::String?",
                      caller_locations[0], :label
  end

  def test_lineno
    assert_send_type  "() -> ::Integer",
                      caller_locations[0], :lineno
  end

  def test_path
    assert_send_type  "() -> ::String?",
                      caller_locations[0], :path
  end
end
