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

  def test_euid=
    require "etc"
    user = Etc.getpwuid(Process.euid).name

    assert_send_type "(Integer) -> Integer",
                     Process, :euid=, Process.euid
    assert_send_type "(String) -> String",
                     Process, :euid=, user
  end

  def test_uid=
    require "etc"
    user = Etc.getpwuid(Process.uid).name

    assert_send_type "(Integer) -> Integer",
                     Process, :uid=, Process.uid
    assert_send_type "(String) -> String",
                     Process, :uid=, user
  end

  def test_egid=
    require "etc"
    group = Etc.getgrgid(Process.egid).name

    assert_send_type "(Integer) -> Integer",
                     Process, :egid=, Process.egid
    assert_send_type "(String) -> String",
                     Process, :egid=, group
  end

  def test_gid=
    require "etc"
    group = Etc.getgrgid(Process.gid).name

    assert_send_type "(Integer) -> Integer",
                     Process, :gid=, Process.gid
    assert_send_type "(String) -> Integer",
                     Process, :gid=, group
  end

  def test_kill
    with_int(Process.pid) do |pid|
      assert_send_type "(Integer, *int) -> Integer",
                       Process, :kill, 0, pid
    end
  end

  def test_wait
    %i[wait waitpid].each do |method|
      with_int(0) do |flags|
        pid = spawn_child
        assert_send_type "(int, int) -> Integer",
                         Process, method, ToInt.new(pid), flags
      end
    end
  end

  def test_wait2
    %i[wait2 waitpid2].each do |method|
      with_int(0) do |flags|
        pid = spawn_child
        assert_send_type "(int, int) -> [Integer, Process::Status]",
                         Process, method, ToInt.new(pid), flags
      end
    end
  end

  def test_getpgid
    with_int(Process.pid) do |pid|
      assert_send_type "(int) -> Integer",
                       Process, :getpgid, pid
    end
  end

  def test_setpgid
    # Moving the current process into its own process group is a no-op.
    with_int(0) do |pid|
      with_int(Process.getpgrp) do |pgid|
        assert_send_type "(int, int) -> Integer",
                         Process, :setpgid, pid, pgid
      end
    end
  end

  def test_getpriority
    with_int(Process::PRIO_PROCESS) do |kind|
      with_int(0) do |who|
        assert_send_type "(int, int) -> Integer",
                         Process, :getpriority, kind, who
      end
    end
  end

  def test_setrlimit
    cur, max = Process.getrlimit(:CORE)
    # Setting the current limits again is a no-op.
    with_int(Process::RLIMIT_CORE) do |resource|
      assert_send_type "(int, int, int) -> nil",
                       Process, :setrlimit, resource, ToInt.new(cur), ToInt.new(max)
    end
    assert_send_type "(Symbol, int) -> nil",
                     Process, :setrlimit, :CORE, ToInt.new(cur)
  end

  private

  def spawn_child(script = "exit", **opts)
    Process.spawn(RUBY_EXECUTABLE, "--disable=all", "-e", script, **opts)
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

class Process_StatusInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Process::Status"

  def test_success?
    assert_send_type "() -> true",
                     status_of("exit"), :success?
    assert_send_type "() -> false",
                     status_of("exit 1"), :success?

    # A child killed by a signal has not exited, so `success?` returns `nil`.
    pid = Process.spawn(RUBY_EXECUTABLE, "--disable=all", "-e", "sleep")
    Process.kill(:KILL, pid)
    _, status = Process.wait2(pid)
    assert_send_type "() -> nil",
                     status, :success?
  end

  private

  def status_of(script)
    _, status = Process.wait2(Process.spawn(RUBY_EXECUTABLE, "--disable=all", "-e", script))
    status
  end
end
