require_relative "test_helper"

class ThreadMutexTest < StdlibTest
  target Thread::Mutex

  def test_lock
    m = Thread::Mutex.new
    m.lock
  end

  def test_locked?
    m = Mutex.new
    m.locked?
    m.lock
    m.locked?
  end

  def test_owned?
    m = Mutex.new
    m.owned?
    m.lock
    Thread.new do
      m.owned?
    end.join
    m.owned?
  end

  def test_synchronize
    m = Mutex.new

    m.synchronize do
      "result"
    end

    m.synchronize do
      :result
    end

    m.synchronize do
    end
  end

  def test_try_lock
    m = Mutex.new
    m.try_lock
    m.try_lock
  end

  def test_unlock
    m = Mutex.new
    m.lock
    m.unlock
  end
end

class ThreadMutexInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Thread::Mutex"

  def test_sleep
    mutex = Thread::Mutex.new

    mutex.synchronize do
      with_timeout(seconds: 0, nanoseconds: 1_000_000) do |timeout|
        assert_send_type "(Time::_Timeout) -> nil",
                         mutex, :sleep, timeout
      end
    end

    sleep_until_woken(mutex) do
      assert_send_type "() -> Integer",
                       mutex, :sleep
    end

    sleep_until_woken(mutex) do
      assert_send_type "(nil) -> Integer",
                       mutex, :sleep, nil
    end

    sleep_until_woken(mutex) do
      assert_send_type "(Time::_Timeout) -> Integer",
                       mutex, :sleep, 60
    end
  end

  private

  def sleep_until_woken(mutex)
    thread = Thread.new do
      mutex.synchronize { yield }
    end

    Thread.pass until thread.stop?
    thread.wakeup
    thread.join
  end
end
