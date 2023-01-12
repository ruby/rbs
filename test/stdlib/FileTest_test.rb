require_relative "test_helper"

class FileTestSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::FileTest)"

  def test_blockdev?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :blockdev?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :blockdev?, io_open
  end

  def test_chardev?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :chardev?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :chardev?, io_open
  end

  def test_directory?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :directory?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :directory?, io_open
  end

  def test_empty?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :empty?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :empty?, io_open
  end

  def test_executable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :executable?, File.expand_path(__FILE__, "../..")
  end

  def test_executable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :executable_real?, File.expand_path(__FILE__, "../..")
  end

  def test_exist?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :exist?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :exist?, io_open
  end

  def test_file?
    assert_send_type  "(::String file) -> bool",
                      FileTest, :file?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file) -> bool",
                      FileTest, :file?, io_open
  end

  def test_grpowned?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :grpowned?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :grpowned?, io_open
  end

  def test_identical?
    assert_send_type  "(::String file_1, ::String file_2) -> bool",
                      FileTest, :identical?, File.expand_path(__FILE__, "../.."), File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_1, ::IO file_2) -> bool",
                      FileTest, :identical?, io_open, io_open
  end

  def test_owned?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :owned?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :owned?, io_open
  end

  def test_pipe?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :pipe?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :pipe?, io_open
  end

  def test_readable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :readable?, File.expand_path(__FILE__, "../..")
  end

  def test_readable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :readable_real?, File.expand_path(__FILE__, "../..")
  end

  def test_setgid?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :setgid?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :setgid?, io_open
  end

  def test_setuid?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :setuid?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :setuid?, io_open
  end

  def test_size
    assert_send_type  "(::String file_name) -> ::Integer",
                      FileTest, :size, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> ::Integer",
                      FileTest, :size, io_open
  end

  def test_size?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :size?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :size?, io_open
  end

  def test_socket?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :socket?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :socket?, io_open
  end

  def test_sticky?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :sticky?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :sticky?, io_open
  end

  def test_symlink?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :symlink?, File.expand_path(__FILE__, "../..")
  end

  def test_world_readable?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :world_readable?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :world_readable?, io_open
  end

  def test_world_writable?
    assert_send_type  "(::String file_name) -> ::Integer?",
                      FileTest, :world_writable?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> ::Integer?",
                      FileTest, :world_writable?, io_open
  end

  def test_writable?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :writable?, File.expand_path(__FILE__, "../..")
  end

  def test_writable_real?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :writable_real?, File.expand_path(__FILE__, "../..")
  end

  def test_zero?
    assert_send_type  "(::String file_name) -> bool",
                      FileTest, :zero?, File.expand_path(__FILE__, "../..")
    assert_send_type  "(::IO file_name) -> bool",
                      FileTest, :zero?, io_open
  end

  private

  def io_open
    IO.open(IO.sysopen(File.expand_path(__FILE__, "../..")))
  end
end
