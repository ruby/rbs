require_relative "test_helper"

class FileTestSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::FileTest)"


  def with_path_io(path: __FILE__, io: default=IO.open(IO.sysopen(File.expand_path(__FILE__))), &block)
    with_path(path, &block)
    with_io(io, &block)
  ensure
    io.close if default
  end

  def test_blockdev?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :blockdev?, path_or_io
    end
  end

  def test_chardev?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :chardev?, path_or_io
    end
  end

  def test_directory?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :directory?, path_or_io
    end
  end

  def test_empty?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :empty?, path_or_io
    end
  end

  def test_executable?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :executable?, path
    end
  end

  def test_executable_real?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :executable_real?, path
    end
  end

  def test_exist?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :exist?, path_or_io
    end
  end

  def test_file?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :file?, path_or_io
    end
  end

  def test_grpowned?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :grpowned?, path_or_io
    end
  end

  def test_identical?
    with_path_io do |path_or_io1|
      with_path_io do |path_or_io2|
        assert_send_type  "(::path | ::io, ::path | ::io) -> bool",
                          FileTest, :identical?, path_or_io1, path_or_io2
      end
    end
  end

  def test_owned?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :owned?, path_or_io
    end
  end

  def test_pipe?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :pipe?, path_or_io
    end
  end

  def test_readable?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :readable?, path
    end
  end

  def test_readable_real?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :readable_real?, path
    end
  end

  def test_setgid?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :setgid?, path_or_io
    end
  end

  def test_setuid?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :setuid?, path_or_io
    end
  end

  def test_size
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> Integer",
                        FileTest, :size, path_or_io
    end
  end

  def test_size?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> Integer?",
                        FileTest, :size?, path_or_io
    end
  end

  def test_socket?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :socket?, path_or_io
    end
  end

  def test_sticky?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :sticky?, path_or_io
    end
  end

  def test_symlink?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :symlink?, path
    end
  end

  def test_world_readable?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> Integer?",
                        FileTest, :world_readable?, path_or_io
    end
  end

  def test_world_writable?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> Integer?",
                        FileTest, :world_writable?, path_or_io
    end
  end

  def test_writable?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :writable?, path
    end
  end

  def test_writable_real?
    with_path do |path|
      assert_send_type  "(::path) -> bool",
                        FileTest, :writable_real?, path
    end
  end

  def test_zero?
    with_path_io do |path_or_io|
      assert_send_type  "(::path | ::io) -> bool",
                        FileTest, :zero?, path_or_io
    end
  end
end
