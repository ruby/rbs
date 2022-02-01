require_relative "test_helper"

class FileStatSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::File::Stat)"

  def test_new
    assert_send_type "(String) -> void",
                    File::Stat, :new, __FILE__
  end
end

class FileStatInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::File::Stat"

  def test_spaceship
    assert_send_type "(File::Stat) -> Integer",
                      File::Stat.new(__FILE__), :<=>, File::Stat.new(__FILE__)
    assert_send_type "(untyped) -> nil",
                      File::Stat.new(__FILE__), :<=>, "not a File::Stat object"
  end

  def test_atime
    assert_send_type "() -> Time",
                      File::Stat.new(__FILE__), :atime
  end

  def test_birthtime
    assert_send_type "() -> Time",
                      File::Stat.new(__FILE__), :birthtime
  rescue NotImplementedError
  end

  def test_blksize
    assert_send_type "() -> Integer?",
                      File::Stat.new(__FILE__), :blksize
  end

  def test_blockdev?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :blockdev?
  end

  def test_blocks
    assert_send_type "() -> Integer?",
                      File::Stat.new(__FILE__), :blocks
  end

  def test_chardev?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :chardev?
  end

  def test_ctime
    assert_send_type "() -> Time",
                      File::Stat.new(__FILE__), :ctime
  end

  def test_dev
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :dev
  end

  def test_dev_major
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :dev_major
  end

  def test_dev_minor
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :dev_minor
  end

  def test_directory?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :directory?
  end

  def test_executable?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :executable?
  end

  def test_executable_real?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :executable_real?
  end

  def test_file?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :file?
  end

  def test_ftype
    assert_send_type "() -> String",
                      File::Stat.new(__FILE__), :ftype
  end

  def test_gid
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :gid
  end

  def test_grpowned?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :grpowned?
  end

  def test_ino
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :ino
  end

  def test_inspect
    assert_send_type "() -> String",
                      File::Stat.new(__FILE__), :inspect
  end

  def test_mode
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :mode
  end

  def test_mtime
    assert_send_type "() -> Time",
                      File::Stat.new(__FILE__), :mtime
  end

  def test_nlink
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :nlink
  end

  def test_owned?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :owned?
  end

  def test_pipe?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :pipe?
  end

  def test_rdev
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :rdev
  end

  def test_rdev_major
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :rdev_major
  end

  def test_rdev_minor
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :rdev_minor
  end

  def test_readable?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :readable?
  end

  def test_readable_real?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :readable_real?
  end

  def test_setgid?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :setgid?
  end

  def test_setuid?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :setuid?
  end

  def test_size
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :size
  end

  def test_size?
    assert_send_type "() -> Integer?",
                      File::Stat.new(__FILE__), :size?
  end

  def test_socket?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :socket?
  end

  def test_sticky?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :sticky?
  end

  def test_symlink?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :symlink?
  end

  def test_uid
    assert_send_type "() -> Integer",
                      File::Stat.new(__FILE__), :uid
  end

  def test_world_readable?
    assert_send_type "() -> Integer?",
                      File::Stat.new(__FILE__), :world_readable?
  end

  def test_world_writable?
    assert_send_type "() -> Integer?",
                      File::Stat.new(__FILE__), :world_writable?
  end

  def test_writable?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :writable?
  end

  def test_writable_real?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :writable_real?
  end

  def test_zero?
    assert_send_type "() -> bool",
                      File::Stat.new(__FILE__), :zero?
  end
end
