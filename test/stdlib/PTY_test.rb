require_relative "test_helper"
require "pty"

class PTYSingletonTest < Minitest::Test
  include TypeAssertions

   library "pty"
  testing "singleton(::PTY)"


  def test_open
    assert_send_type  "() -> [ ::IO, ::File ]",
                      PTY, :open
    assert_send_type  "() { ([ ::IO, ::File ]) -> untyped } -> untyped",
                      PTY, :open do |master, slave| 1 end
  end

  def test_check
    r, w, pid = PTY.spawn("echo")
    assert_send_type  "(::Integer pid) -> (::Process::Status | nil)",
                      PTY, :check, pid
    assert_send_type  "(::Integer pid, ::FalseClass raise) -> (::Process::Status | nil)",
                      PTY, :check, pid, false
    assert_send_type  "(::Integer pid, ::TrueClass raise) -> nil",
                      PTY, :check, pid, true
  end

  def test_getpty
    assert_send_type  "(*::String command) -> [ ::IO, ::IO, ::Integer ]",
                      PTY, :getpty, "echo"
    assert_send_type  "(*String command) { ([ ::IO, ::IO, ::Integer ]) -> untyped } -> untyped",
                      PTY, :getpty, "echo" do |r, w, pid| 1 end
  end

  def test_spawn
    assert_send_type  "(*::String command) -> [ ::IO, ::IO, ::Integer ]",
                      PTY, :spawn, "echo"
    assert_send_type  "(*::String command) { ([ ::IO, ::IO, ::Integer ]) -> untyped } -> untyped",
                      PTY, :spawn, "echo" do |r, w, pid| 1 end
  end
end

