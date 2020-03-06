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

  def test_atime
    assert_send_type "(String) -> Time",
                     File, :atime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :atime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :atime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :atime, IO.new(IO.sysopen(__FILE__))
  end

  def test_basename
    assert_send_type "(String) -> String",
                     File, :basename, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :basename, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :basename, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :basename, __FILE__, '.rb'
    assert_send_type "(String, ToStr) -> String",
                     File, :basename, __FILE__, ToStr.new('.rb')
  end

  def test_birthtime
    assert_send_type "(String) -> Time",
                     File, :birthtime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :birthtime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :birthtime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :birthtime, IO.new(IO.sysopen(__FILE__))
  end
end
