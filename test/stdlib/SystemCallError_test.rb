require_relative "test_helper"

class SystemCallErrorSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::SystemCallError)'

  def test_new
    assert_send_type '(Integer) -> SystemCallError',
                     SystemCallError, :new, Errno::ENOENT::Errno

    with_string do |message|
      assert_send_type '(string) -> SystemCallError',
                       SystemCallError, :new, message
      assert_send_type '(string, Integer) -> SystemCallError',
                       SystemCallError, :new, message, 0
      assert_send_type '(string, Integer, _ToS) -> SystemCallError',
                       SystemCallError, :new, message, Errno::ENOENT::Errno, ToS.new('path')
    end
  end
end

class SystemCallErrorInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::SystemCallError'

  def test_errno
    error = SystemCallError.new(Errno::ENOENT::Errno)
    assert_send_type '() -> Integer', error, :errno

    error = SystemCallError.new('test')
    assert_send_type '() -> nil', error, :errno
  end
end
