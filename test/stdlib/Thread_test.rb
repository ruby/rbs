require_relative "test_helper"

class ThreadSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Thread)"

  def test_new
    assert_send_type  "() { () -> untyped } -> Thread",
                      Thread, :new do 1 end
    assert_send_type  "(Integer, nil) { (Integer, nil) -> untyped } -> Thread",
                      Thread, :new, 1, nil do |a, b| [a, b] end

    a_proc = proc { "do something..." }
    assert_send_type  "() { () -> untyped } -> Thread",
                      Thread, :new, &a_proc
  end

  def test_start
    assert_send_type  "() { () -> Integer } -> Thread",
                      Thread, :start do 1 end

    assert_send_type "() { () -> Integer } -> untyped",
                     Class.new(Thread), :start do 1 end
  end

  def test_each_caller_location
    assert_send_type(
      "() { (Thread::Backtrace::Location) -> Integer } -> nil",
      Thread, :each_caller_location, &-> (loc) { 3 }
    )
  end
end

class ThreadTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Thread"

  def test_native_thread_id
    assert_send_type(
      "() -> Integer",
      Thread.current, :native_thread_id
    )
  end
end
