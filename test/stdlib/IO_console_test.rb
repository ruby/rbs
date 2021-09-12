require_relative "test_helper"
require "io/console"
require "io/console/size"
require 'pty'

class IOConsoleSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library 'io-console'
  testing "singleton(::IO)"

  def test_io_console
    assert_send_type "() -> File?",
                     IO, :console
    assert_send_type "(:close) -> nil",
                     IO, :console, :close
  end

  def test_io_console_size
    assert_send_type "() -> [Integer, Integer]",
                     IO, :console_size
  end

  def test_io_default_console_size
    assert_send_type "() -> [Integer, Integer]",
                     IO, :default_console_size
  end
end

class IOConsoleTest < Test::Unit::TestCase
  include TypeAssertions

  library 'io-console'
  testing "::IO"

  private def helper
    m, s = PTY.open
  rescue RuntimeError
    omit $!
  else
    yield m, s
  ensure
    m.close if m
    s.close if s
  end

  def test_io_console_mode
    helper { |m, s|
      assert_send_type "() -> IO::ConsoleMode",
                       s, :console_mode
    }
  end

  def test_io_console_mode_set
    helper { |m, s|
      assert_send_type "(IO::ConsoleMode mode) -> IO::ConsoleMode",
                       s, :console_mode=, s.console_mode
    }
  end

  def test_io_cooked
    helper { |m, s|
      assert_send_type "() { (self) -> void } -> void",
                       s, :cooked do end
    }
  end

  def test_io_echo_p
    helper { |m, s|
      assert_send_type "() -> bool",
                       s, :echo?
    }
  end

  def test_io_noecho
    helper { |m, s|
      assert_send_type "() { (self) -> void } -> void",
                       s, :noecho do end
    }
  end

  def test_io_raw
    helper { |m, s|
      assert_send_type "() { (self) -> void } -> void",
                       s, :raw do end
    }
  end

  def test_io_winsize
    helper { |m, s|
      assert_send_type "() -> [Integer, Integer]",
                       s, :winsize
    }
  end
end
