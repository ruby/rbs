require_relative "test_helper"

class ProcessSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Process)"

  def test_last_status
    Process.wait(Process.spawn(RUBY_EXECUTABLE, "--disable=all", "-e", "exit"))
    assert_send_type "() -> Process::Status",
                     Process, :last_status

    Thread.new do
      assert_send_type "() -> nil",
                       Process, :last_status
    end.join
  end

  def test_setpgrp
    omit "fork/setpgrp is not available" unless Process.respond_to?(:fork) && Process.respond_to?(:setpgrp)

    # Run in a child process so that the test runner's process group is not changed.
    r, w = IO.pipe
    pid = fork do
      r.close
      assert_send_type "() -> Integer",
                       Process, :setpgrp
      exit!(true)
    rescue Exception => e
      w.write(e.full_message(highlight: false))
      exit!(false)
    end
    w.close
    message = r.read
    _, status = Process.wait2(pid)
    assert_predicate status, :success?, message
  ensure
    r&.close
  end
end

class Process_SysSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Process::Sys)"

  def test_getegid
    assert_send_type "() -> Integer",
                     Process::Sys, :getegid
  end
end

class Process_StatusSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Process::Status)"

  def test_wait
    pid = spawn_child
    assert_send_type "() -> Process::Status",
                     Process::Status, :wait
    begin
      Process.wait(pid) # In case `wait` reaped another child
    rescue Errno::ECHILD
    end

    pid = spawn_child
    assert_send_type "(int) -> Process::Status",
                     Process::Status, :wait, pid
    pid = spawn_child
    assert_send_type "(int) -> Process::Status",
                     Process::Status, :wait, ToInt.new(pid)

    with_int(0) do |flags|
      pid = spawn_child
      assert_send_type "(int, int) -> Process::Status",
                       Process::Status, :wait, pid, flags
    end

    # The child blocks reading the pipe, so `WNOHANG` returns `nil`.
    r, w = IO.pipe
    pid = spawn_child("STDIN.read", in: r)
    r.close
    with_int(Process::WNOHANG) do |flags|
      assert_send_type "(int, int) -> nil",
                       Process::Status, :wait, pid, flags
    end
  ensure
    w&.close
    begin
      Process.wait(pid) if pid
    rescue Errno::ECHILD
    end
  end

  private

  def spawn_child(script = "exit", **opts)
    Process.spawn(RUBY_EXECUTABLE, "--disable=all", "-e", script, **opts)
  end
end
