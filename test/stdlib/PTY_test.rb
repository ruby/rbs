require_relative "test_helper"
begin
  require "pty"
rescue LoadError
  # Skip the tests if the library is not available like Windows platform
end

class PTYSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "pty"
  testing "singleton(::PTY)"

  def test_open
    assert_send_type  "() -> [ ::IO, ::File ]",
                      PTY, :open
    assert_send_type  "() { ([ ::IO, ::File ]) -> ::Integer } -> ::Integer",
                      PTY, :open do |master, slave| 1 end
  end

  def test_check
    r, w, pid = PTY.spawn("sleep 5")

    assert_send_type  "(::Integer pid) -> (::Process::Status | nil)",
                      PTY, :check, pid
    assert_send_type  "(::Integer pid, Symbol) -> (::Process::Status | nil)",
                      PTY, :check, pid, :true
    assert_send_type  "(::Integer pid, ::FalseClass raise) -> nil",
                      PTY, :check, pid, false
    assert_send_type  "(::Integer pid, ::TrueClass raise) -> nil",
                      PTY, :check, pid, true

    Process.kill(:INT, pid)
    Process.waitpid(pid)
  end

  def test_getpty
    assert_send_type  "(*::String command) -> [ ::IO, ::IO, ::Integer ]",
                      PTY, :getpty, "echo"
    assert_send_type  "(*String command) { ([ ::IO, ::IO, ::Integer ]) -> ::Integer } -> nil",
                      PTY, :getpty, "echo" do |r, w, pid| 1 end
  end

  def test_spawn
    _, _, pid = assert_send_type "(*::String command) -> [ ::IO, ::IO, ::Integer ]",
                                 PTY, :spawn, "echo"
    Process.waitpid(pid)

    assert_send_type "(*::String command) { ([ ::IO, ::IO, ::Integer ]) -> ::Integer } -> nil",
                     PTY, :spawn, "echo" do |r, w, pid| 1 end
  end
end if defined?(PTY)

class PTYChildExitedTest < Test::Unit::TestCase
  include TestHelper

  library "pty"
  testing "::PTY::ChildExited"

  def test_child_exited
    assert_const_type "Class", "PTY::ChildExited"
  end

  def test_status
    _r, _w, pid = PTY.spawn("sleep 0.05")
    sleep 0.1
    begin
      PTY.check(pid, true)
    rescue PTY::ChildExited => ex
      assert_send_type "() -> ::Process::Status",
                       ex, :status
    end
  end
end if defined?(PTY)
