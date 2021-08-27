require_relative "test_helper"
require 'monitor'

class MonitorInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'monitor'
  testing "::Monitor"

  def test_enter
    assert_send_type "() -> nil",
                     Monitor.new, :enter
  end

  def test_exit
    m = Monitor.new
    m.enter
    assert_send_type "() -> nil",
                     m, :exit
  end

  def test_new_cond
    m = Monitor.new
    assert_send_type '() -> ::MonitorMixin::ConditionVariable',
                     m, :new_cond
  end

  def test_synchronize
    m = Monitor.new
    assert_send_type '() { () -> String } -> String',
                     m, :synchronize do 'foo' end
  end

  def test_try_enter
    m = Monitor.new
    assert_send_type '() -> bool',
                     m, :try_enter
  end
end

class MonitorMixinInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'monitor'
  testing "::MonitorMixin"

  class C
    include MonitorMixin
  end

  def test_mon_enter
    obj = C.new
    assert_send_type '() -> nil',
                     obj, :mon_enter
  end

  def test_mon_exit
    obj = C.new
    obj.mon_enter
    assert_send_type '() -> nil',
                     obj, :mon_exit
  end

  def test_mon_locked?
    obj = C.new
    assert_send_type '() -> bool',
                     obj, :mon_locked?
  end

  def test_mon_owned?
    obj = C.new
    assert_send_type '() -> bool',
                     obj, :mon_owned?
  end

  def test_mon_synchronize
    obj = C.new
    assert_send_type '() { () -> String } -> String',
                     obj, :mon_synchronize do 'foo' end
  end

  def test_mon_try_enter
    obj = C.new
    assert_send_type '() -> bool',
                     obj, :mon_try_enter
  end

  def test_new_cond
    obj = C.new
    assert_send_type '() -> ::MonitorMixin::ConditionVariable',
                     obj, :new_cond
  end
end

class MonitorMixinConditionVariableInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'monitor'
  testing "::MonitorMixin::ConditionVariable"

  def test_broadcast
    m, v = cond_var
    m.enter
    assert_send_type '() -> Thread::ConditionVariable',
                     v, :broadcast
  end

  def test_signal
    m, v = cond_var
    m.enter
    assert_send_type '() -> Thread::ConditionVariable',
                     v, :signal
  end

  def test_wait_1
    m, v = cond_var
    m.enter
    Thread.new { sleep 0.01; m.enter; v.signal } # to wake up main thread
    assert_send_type '() -> untyped',
                     v, :wait
  end

  def test_wait_2
    m, v = cond_var
    m.enter
    assert_send_type '(Float) -> untyped',
                     v, :wait, 0.01
  end

  def test_wait_until
    m, v = cond_var
    m.enter

    assert_send_type '() { () -> true } -> untyped',
                     v, :wait_until do true end
  end

  def test_wait_while
    m, v = cond_var
    m.enter

    assert_send_type '() { () -> false } -> untyped',
                     v, :wait_while do false end
  end

  def cond_var
    m = Monitor.new
    return m, MonitorMixin::ConditionVariable.new(m)
  end
end
