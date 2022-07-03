require_relative "test_helper"

class WarningTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Warning"

  class TestClass
    include Warning
  end

  def test_warn
    $stderr = StringIO.new

    assert_send_type "(::String) -> nil",
        Warning, :warn, 'message'

    refute_send_type "(::_ToStr) -> nil",
        Warning, :warn, ToStr.new

    assert_send_type "(::String) -> nil",
        TestClass.new, :warn, 'message'

    omit_if(RUBY_VERSION < "3.0")

    assert_send_type "(::String, category: :deprecated) -> nil",
        Warning, :warn, 'message', category: :deprecated

    assert_send_type "(::String, category: :experimental) -> nil",
        Warning, :warn, 'message', category: :experimental

    assert_send_type "(::String, category: nil) -> nil",
        Warning, :warn, 'message', category: nil

    refute_send_type "(::String, category: ::Symbol) -> nil",
        Warning, :warn, 'message', category: :unknown_category
  ensure
    $stderr = STDERR
  end
end
