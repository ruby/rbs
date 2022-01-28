require_relative "test_helper"

class FileTestSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::FileTest)"

  def test_blockdev?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :blockdev?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :blockdev?, io_open
  end

  def test_chardev?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :chardev?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :chardev?, io_open
  end

  def test_directory?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :directory?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :directory?, io_open
  end

  def test_empty?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :empty?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :empty?, io_open
  end

  def test_executable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :executable?, __FILE__
  end

  def test_executable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :executable_real?, __FILE__
  end

  def test_exist?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :exist?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :exist?, io_open
  end

  def test_exists?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :exists?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :exists?, io_open
  end

  def test_file?
    assert_send_type  "(::String file) -> bool",
                      FileTest, :file?, __FILE__
    assert_send_type  "(::IO file) -> bool",
                      FileTest, :file?, io_open
  end

  def test_grpowned?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :grpowned?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :grpowned?, io_open
  end

  def test_identical?
    assert_send_type  "(::String file_1, ::String file_2) -> bool",
                      FileTest, :identical?, __FILE__, __FILE__
    assert_send_type  "(::IO file_1, ::IO file_2) -> bool",
                      FileTest, :identical?, io_open, io_open
  end

  def test_owned?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :owned?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :owned?, io_open
  end

  def test_pipe?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :pipe?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :pipe?, io_open
  end

  def test_readable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :readable?, __FILE__
  end

  def test_readable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :readable_real?, __FILE__
  end

  def test_setgid?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :setgid?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :setgid?, io_open
  end

  def test_setuid?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :setuid?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :setuid?, io_open
  end

  def test_size
    assert_send_type  "(::String file_name) -> ::Integer",
                      FileTest, :size, __FILE__
    assert_send_type  "(::IO file_name) -> ::Integer",
                      FileTest, :size, io_open
  end

  def test_size?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :size?, __FILE__
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :size?, io_open
  end

  def test_socket?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :socket?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :socket?, io_open
  end

  def test_sticky?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :sticky?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :sticky?, io_open
  end

  def test_symlink?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :symlink?, __FILE__
  end

  def test_world_readable?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :world_readable?, __FILE__
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :world_readable?, io_open
  end

  def test_world_writable?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :world_writable?, __FILE__
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :world_writable?, io_open
  end

  def test_writable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :writable?, __FILE__
  end

  def test_writable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :writable_real?, __FILE__
  end

  def test_zero?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :zero?, __FILE__
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :zero?, io_open
  end

  private

  def io_open
    IO.open(IO.sysopen(__FILE__))
  end
end
