require_relative 'test_helper'

class ExceptionSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(::Exception)'

  def test_to_tty?
    assert_send_type  '() -> bool',
                      Exception, :to_tty?
  end

  class MyException < Exception; end

  def test_exception
    assert_send_type  '() -> ExceptionSingletonTest::MyException',
                      MyException, :exception

    with_string.and(1r) do |message|
      assert_send_type  '(string | _ToS) -> ExceptionSingletonTest::MyException',
                        MyException, :exception, message
    end
  end
end

class ExceptionInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::Exception'

  INSTANCE = Exception.new

  def test_eq
    assert_send_type  '(untyped) -> bool',
                      INSTANCE, :==, INSTANCE
  end

  def test_backtrace
    exception = Exception.new
    exception.set_backtrace nil # it defaults to `nil`, but better safe than sorry.

    assert_send_type  '() -> nil',
                      exception, :backtrace
    
    exception.set_backtrace caller
    assert_send_type  '() -> Array[String]',
                      exception, :backtrace
  end

  def test_backtrace_locations
    assert_send_type  '() -> nil',
                      INSTANCE, :backtrace_locations

    exception = begin
      raise Exception
    rescue Exception => exc
      exc
    end

    assert_send_type  '() -> Array[Thread::Backtrace::Location]',
                      exception, :backtrace_locations
  end

  def test_cause
    assert_send_type  '() -> nil',
                      INSTANCE, :cause
    
    exception = begin
      raise "oops"
    rescue
      begin
        raise Exception
      rescue Exception => exc
        exc
      end
    end

    assert_send_type  '() -> Exception',
                      exception, :cause
  end

  def test_detailed_message
    assert_send_type  '() -> String',
                      INSTANCE, :detailed_message

    with_bool.and_nil do |highlight|
      assert_send_type  '(highlight: bool?) -> String',
                        INSTANCE, :detailed_message, highlight: highlight
      assert_send_type  '(highlight: bool?, **untyped) -> String',
                        INSTANCE, :detailed_message, highlight: highlight, a: 3, yes: Object.new
    end
  end

  class MyException < Exception; end

  def test_exception
    assert_send_type  '() -> self',
                      INSTANCE, :exception
    assert_send_type  '(self) -> self',
                      INSTANCE, :exception, INSTANCE

    with_string.and(Object.new, 1r) do |message|
      assert_send_type  '(string | _ToS) -> ExceptionInstanceTest::MyException',
                        MyException.new, :exception, message
    end
  end

  def test_initialize
    with_string.and(Object.new, 1r) do |message|
      assert_send_type  '(string | _ToS) -> self',
                        Exception.allocate, :initialize, message
    end
  end

  def test_inspect
    assert_send_type  '() -> String',
                      INSTANCE, :inspect
  end

  def test_message
    assert_send_type  '() -> String',
                      INSTANCE, :message
  end

  def test_set_backtrace
    exception = Exception.new

    assert_send_type  '(nil) -> nil',
                      exception, :set_backtrace, nil

    assert_send_type  '(String) -> Array[String]',
                      exception, :set_backtrace, "hello"

    assert_send_type  '(Array[String]) -> Array[String]',
                      exception, :set_backtrace, ["hello", "there"]
  end

  def test_to_s
    assert_send_type  '() -> String',
                      INSTANCE, :to_s
  end

  def test_full_message
    assert_send_type  '() -> String',
                      INSTANCE, :full_message

    with_bool.and_nil do |highlight|
      assert_send_type  '(highlight: bool?) -> String',
                        INSTANCE, :full_message, highlight: highlight
      
      with_string('top').and(nil, with_string('bottom'), :top, :bottom) do |order|
        assert_send_type  '(highlight: bool?, order: (:top | :bottom | string)?) -> String',
                          INSTANCE, :full_message, highlight: highlight, order: order
      end
    end
  end
end
