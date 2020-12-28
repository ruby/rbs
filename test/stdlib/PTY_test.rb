require_relative "test_helper"
require "pty"

class PTYSingletonTest < Test::Unit::TestCase
  include TypeAssertions

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
end
