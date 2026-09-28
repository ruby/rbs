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

class SystemCallErrorTest < StdlibTest
  target SystemCallError

  def test_initialize
    SystemCallError.new('hi', 0)
    a = SystemCallError.new(ToStr.new('hi'), 0)
    a.errno
    a.message
  end

  def test_errno
    begin
      raise Errno::ENOENT, 'test'
    rescue SystemCallError => exception
      exception.errno
    end

    begin
      raise SystemCallError.new('test', 3)
    rescue SystemCallError => exception
      exception.errno
    end
  end
end
