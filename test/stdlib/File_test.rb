require_relative "test_helper"
require "ruby/signature/test/test_helper"

class FileSingletonTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "singleton(::File)"

  def test_absolute_path
    assert_send_type "(String) -> String",
                     File, :absolute_path, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :absolute_path, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :absolute_path, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :absolute_path, __FILE__, __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :absolute_path, __FILE__, ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :absolute_path, __FILE__, ToPath.new(__dir__)
  end

  def test_absolute_path?
    assert_send_type "(String) -> bool",
                     File, :absolute_path?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :absolute_path?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :absolute_path?, ToPath.new(__FILE__)
  end
end
