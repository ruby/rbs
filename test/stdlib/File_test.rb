require_relative "test_helper"
require "socket"

class FileSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::File)"

  def test_new
    assert_send_type "(String) -> File",
                     File, :new, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> File",
                     File, :new, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> File",
                     File, :new, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(Integer) -> File",
                     File, :new, IO.sysopen(File.expand_path(__FILE__))
    assert_send_type "(ToInt) -> File",
                     File, :new, ToInt.new(IO.sysopen(File.expand_path(__FILE__)))
    assert_send_type "(String, String) -> File",
                     File, :new, File.expand_path(__FILE__), "r"
    assert_send_type "(String, ToStr) -> File",
                     File, :new, File.expand_path(__FILE__), ToStr.new("r")
    assert_send_type "(String, Integer) -> File",
                     File, :new, File.expand_path(__FILE__), File::RDONLY
    assert_send_type "(String, ToInt) -> File",
                     File, :new, File.expand_path(__FILE__), ToInt.new(File::RDONLY)
    assert_send_type "(String, String, Integer) -> File",
                     File, :new, File.expand_path(__FILE__), "r", 0644
    assert_send_type "(String, String, ToInt) -> File",
                     File, :new, File.expand_path(__FILE__), "r", ToInt.new(0644)
  end

  def test_open
    assert_send_type "(String) -> File",
                     File, :open, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> File",
                     File, :open, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> File",
                     File, :open, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(Integer) -> File",
                     File, :open, IO.sysopen(File.expand_path(__FILE__))
    assert_send_type "(ToInt) -> File",
                     File, :open, ToInt.new(IO.sysopen(File.expand_path(__FILE__)))
    assert_send_type "(String, String) -> File",
                     File, :open, File.expand_path(__FILE__), "r"
    assert_send_type "(String, ToStr) -> File",
                     File, :open, File.expand_path(__FILE__), ToStr.new("r")
    assert_send_type "(String, Integer) -> File",
                     File, :open, File.expand_path(__FILE__), File::RDONLY
    assert_send_type "(String, ToInt) -> File",
                     File, :open, File.expand_path(__FILE__), ToInt.new(File::RDONLY)
    assert_send_type "(String, String, Integer) -> File",
                     File, :open, File.expand_path(__FILE__), "r", 0644
    assert_send_type "(String, String, ToInt) -> File",
                     File, :open, File.expand_path(__FILE__), "r", ToInt.new(0644)
    assert_send_type "(String) { (File) -> String } -> String",
                     File, :open, File.expand_path(__FILE__) do |file| file.read end
  end

  def test_absolute_path
    assert_send_type "(String) -> String",
                     File, :absolute_path, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :absolute_path, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :absolute_path, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String) -> String",
                     File, :absolute_path, File.expand_path(__FILE__), __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :absolute_path, File.expand_path(__FILE__), ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :absolute_path, File.expand_path(__FILE__), ToPath.new(__dir__)
  end

  def test_absolute_path?
    assert_send_type "(String) -> bool",
                     File, :absolute_path?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :absolute_path?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :absolute_path?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_atime
    assert_send_type "(String) -> Time",
                     File, :atime, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Time",
                     File, :atime, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Time",
                     File, :atime, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Time",
                     File, :atime, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_basename
    assert_send_type "(String) -> String",
                     File, :basename, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :basename, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :basename, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String) -> String",
                     File, :basename, File.expand_path(__FILE__), ".rb"
    assert_send_type "(String, ToStr) -> String",
                     File, :basename, File.expand_path(__FILE__), ToStr.new(".rb")
  end

  def test_blockdev?
    assert_send_type "(String) -> bool",
                     File, :blockdev?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :blockdev?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :blockdev?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :blockdev?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_chardev?
    assert_send_type "(String) -> bool",
                     File, :chardev?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :chardev?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :chardev?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :chardev?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_chmod
    Dir.mktmpdir do |dir|
      File.open("#{dir}/chmod", "w"){}
      assert_send_type "(Integer, String) -> Integer",
                       File, :chmod, 0644, "#{dir}/chmod"
      assert_send_type "(ToInt, String) -> Integer",
                       File, :chmod, ToInt.new(0644), "#{dir}/chmod"
      assert_send_type "(Integer, ToStr) -> Integer",
                       File, :chmod, 0644, ToStr.new("#{dir}/chmod")
      assert_send_type "(Integer, ToPath) -> Integer",
                       File, :chmod, 0644, ToPath.new("#{dir}/chmod")
      assert_send_type "(Integer, String, String) -> Integer",
                       File, :chmod, 0644, "#{dir}/chmod", "#{dir}/chmod"
    end
  end

  def test_chown
    assert_send_type "(Integer, Integer, String) -> Integer",
                     File, :chown, Process.uid, Process.gid, File.expand_path(__FILE__)
    assert_send_type "(ToInt, Integer, String) -> Integer",
                     File, :chown, ToInt.new(Process.uid), Process.gid, File.expand_path(__FILE__)
    assert_send_type "(nil, Integer, String) -> Integer",
                     File, :chown, nil, Process.gid, File.expand_path(__FILE__)
    assert_send_type "(Integer, ToInt, String) -> Integer",
                     File, :chown, Process.uid, ToInt.new(Process.gid), File.expand_path(__FILE__)
    assert_send_type "(Integer, nil, String) -> Integer",
                     File, :chown, Process.uid, nil, File.expand_path(__FILE__)
    assert_send_type "(Integer, Integer, ToStr) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(Integer, Integer, ToPath) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(Integer, nil, String, String) -> Integer",
                     File, :chown, Process.uid, nil, File.expand_path(__FILE__), File.expand_path(__FILE__)
  end

  def test_ctime
    assert_send_type "(String) -> Time",
                     File, :ctime, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Time",
                     File, :ctime, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Time",
                     File, :ctime, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Time",
                     File, :ctime, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_delete
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(String) -> Integer",
                       File, :delete, "#{dir}/a"

      File.open("#{dir}/b", "w"){}
      assert_send_type "(ToStr) -> Integer",
                       File, :delete, ToStr.new("#{dir}/b")

      File.open("#{dir}/c", "w"){}
      assert_send_type "(ToPath) -> Integer",
                       File, :delete, ToPath.new("#{dir}/c")

      File.open("#{dir}/d", "w"){}
      File.open("#{dir}/e", "w"){}
      assert_send_type "(String, String) -> Integer",
                       File, :delete, "#{dir}/d", "#{dir}/e"
    end
  end

  def test_directory?
    assert_send_type "(String) -> bool",
                     File, :directory?, __dir__
    assert_send_type "(ToStr) -> bool",
                     File, :directory?, ToStr.new(__dir__)
    assert_send_type "(ToPath) -> bool",
                     File, :directory?, ToPath.new(__dir__)
    assert_send_type "(IO) -> bool",
                     File, :directory?, IO.new(IO.sysopen(__dir__))
  end

  def test_dirname
    assert_send_type "(String) -> String",
                     File, :dirname, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :dirname, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :dirname, ToPath.new(File.expand_path(__FILE__))

    assert_send_type(
      "(String, Integer) -> String",
      File, :dirname, File.expand_path(__FILE__), 2
    )
  end

  def test_empty?
    assert_send_type "(String) -> bool",
                     File, :empty?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :empty?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :empty?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :empty?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_executable?
    assert_send_type "(String) -> bool",
                     File, :executable?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :executable?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :executable?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_executable_real?
    assert_send_type "(String) -> bool",
                     File, :executable_real?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :executable_real?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :executable_real?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_exist?
    assert_send_type "(String) -> bool",
                     File, :exist?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :exist?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :exist?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :exist?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_expand_path
    assert_send_type "(String) -> String",
                     File, :expand_path, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :expand_path, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :expand_path, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String) -> String",
                     File, :expand_path, File.expand_path(__FILE__), __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :expand_path, File.expand_path(__FILE__), ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :expand_path, File.expand_path(__FILE__), ToPath.new(__dir__)
  end

  def test_extname
    assert_send_type "(String) -> String",
                     File, :extname, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :extname, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :extname, ToPath.new(File.expand_path(__FILE__))
  end

  def test_file?
    assert_send_type "(String) -> bool",
                     File, :file?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :file?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :file?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :file?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_fnmatch
    assert_send_type "(String, String) -> bool",
                     File, :fnmatch, "File_test", File.expand_path(__FILE__)
    assert_send_type "(ToStr, String) -> bool",
                     File, :fnmatch, ToStr.new("File_test"), File.expand_path(__FILE__)
    assert_send_type "(String, ToStr) -> bool",
                     File, :fnmatch, "File_test", ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(String, ToPath) -> bool",
                     File, :fnmatch, "File_test", ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String, Integer) -> bool",
                     File, :fnmatch, "File_test", File.expand_path(__FILE__), File::FNM_CASEFOLD
    assert_send_type "(String, String, ToInt) -> bool",
                     File, :fnmatch, "File_test", File.expand_path(__FILE__), ToInt.new(File::FNM_CASEFOLD)
  end

  def test_fnmatch?
    assert_send_type "(String, String) -> bool",
                     File, :fnmatch?, "File_test", File.expand_path(__FILE__)
  end

  def test_ftype
    assert_send_type "(String) -> String",
                     File, :ftype, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :ftype, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :ftype, ToPath.new(File.expand_path(__FILE__))
  end

  def test_grpowned?
    assert_send_type "(String) -> bool",
                     File, :grpowned?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :grpowned?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :grpowned?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :grpowned?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_identical?
    assert_send_type "(String, String) -> bool",
                     File, :identical?, File.expand_path(__FILE__), File.expand_path(__FILE__)
    assert_send_type "(ToStr, String) -> bool",
                     File, :identical?, ToStr.new(File.expand_path(__FILE__)), File.expand_path(__FILE__)
    assert_send_type "(ToPath, String) -> bool",
                     File, :identical?, ToPath.new(File.expand_path(__FILE__)), File.expand_path(__FILE__)
    assert_send_type "(IO, String) -> bool",
                     File, :identical?, IO.new(IO.sysopen(File.expand_path(__FILE__))), File.expand_path(__FILE__)
    assert_send_type "(String, ToStr) -> bool",
                     File, :identical?, File.expand_path(__FILE__), ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(String, ToPath) -> bool",
                     File, :identical?, File.expand_path(__FILE__), ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, IO) -> bool",
                     File, :identical?, File.expand_path(__FILE__), IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_join
    assert_send_type "(String) -> String",
                     File, :join, "foo"
    assert_send_type "(ToStr) -> String",
                     File, :join, ToStr.new("foo")
    assert_send_type "(String, String) -> String",
                     File, :join, "foo", "bar"
  end

  def test_lchown
    assert_send_type "(Integer, Integer, String) -> Integer",
                     File, :lchown, Process.uid, Process.gid, File.expand_path(__FILE__)
    assert_send_type "(ToInt, Integer, String) -> Integer",
                     File, :lchown, ToInt.new(Process.uid), Process.gid, File.expand_path(__FILE__)
    assert_send_type "(nil, Integer, String) -> Integer",
                     File, :lchown, nil, Process.gid, File.expand_path(__FILE__)
    assert_send_type "(Integer, ToInt, String) -> Integer",
                     File, :lchown, Process.uid, ToInt.new(Process.gid), File.expand_path(__FILE__)
    assert_send_type "(Integer, nil, String) -> Integer",
                     File, :lchown, Process.uid, nil, File.expand_path(__FILE__)
    assert_send_type "(Integer, Integer, ToStr) -> Integer",
                     File, :lchown, Process.uid, Process.gid, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(Integer, Integer, ToPath) -> Integer",
                     File, :lchown, Process.uid, Process.gid, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(Integer, nil, String, String) -> Integer",
                     File, :lchown, Process.uid, nil, File.expand_path(__FILE__), File.expand_path(__FILE__)
  end

  def test_link
    assert_send_type "(String, String) -> 0",
                     File, :link, File.expand_path(__FILE__), "new_name"
    File.unlink("new_name")

    assert_send_type "(ToStr, ToStr) -> 0",
                     File, :link, ToStr.new(File.expand_path(__FILE__)), ToStr.new("new_name")
    File.unlink("new_name")

    assert_send_type "(ToPath, ToPath) -> 0",
                     File, :link, ToPath.new(File.expand_path(__FILE__)), ToPath.new("new_name")
    File.unlink("new_name")
  end

  def test_lstat
    assert_send_type "(String) -> File::Stat",
                     File, :lstat, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> File::Stat",
                     File, :lstat, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> File::Stat",
                     File, :lstat, ToPath.new(File.expand_path(__FILE__))
  end

  def test_lutime
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(Time, Time, String) -> Integer",
                       File, :lutime, File.atime(File.expand_path(__FILE__)), File.atime(File.expand_path(__FILE__)), "#{dir}/a"
      assert_send_type "(Numeric, Numeric, ToStr) -> Integer",
                       File, :lutime, 1, 2, ToStr.new("#{dir}/a")
      assert_send_type "(Numeric, Numeric, ToPath) -> Integer",
                       File, :lutime, 2.5, 3/2r, ToPath.new("#{dir}/a")

      File.open("#{dir}/b", "w"){}
      assert_send_type "(Time, Time, String, String) -> Integer",
                       File, :lutime, File.atime(File.expand_path(__FILE__)), File.atime(File.expand_path(__FILE__)), "#{dir}/a", "#{dir}/b"
    end
  end

  def test_mkfifo
    Dir.mktmpdir do |dir|
      assert_send_type "(String) -> 0",
                       File, :mkfifo, "#{dir}/a"
      assert_send_type "(ToPath) -> 0",
                       File, :mkfifo, ToPath.new("#{dir}/b")
      assert_send_type "(String, Integer) -> 0",
                       File, :mkfifo, "#{dir}/c", 0666
      assert_send_type "(String, ToInt) -> 0",
                       File, :mkfifo, "#{dir}/d", ToInt.new(0666)
    end
  end

  def test_mtime
    assert_send_type "(String) -> Time",
                     File, :mtime, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Time",
                     File, :mtime, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Time",
                     File, :mtime, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Time",
                     File, :mtime, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_owned?
    assert_send_type "(String) -> bool",
                     File, :owned?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :owned?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :owned?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :owned?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_path
    assert_send_type "(String) -> String",
                     File, :path, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :path, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :path, ToPath.new(File.expand_path(__FILE__))
  end

  def test_pipe?
    assert_send_type "(String) -> bool",
                     File, :pipe?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :pipe?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :pipe?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :pipe?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_readable?
    assert_send_type "(String) -> bool",
                     File, :readable?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :readable?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :readable?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_readable_real?
    assert_send_type "(String) -> bool",
                     File, :readable_real?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :readable_real?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :readable_real?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_readlink
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      File.symlink("#{dir}/a", "#{dir}/readlink")

      assert_send_type "(String) -> String",
                       File, :readlink, "#{dir}/readlink"
      assert_send_type "(ToStr) -> String",
                       File, :readlink, ToStr.new("#{dir}/readlink")
      assert_send_type "(ToPath) -> String",
                       File, :readlink, ToPath.new("#{dir}/readlink")
    end
  end

  def test_realdirpath
    assert_send_type "(String) -> String",
                     File, :realdirpath , File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :realdirpath, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :realdirpath, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String) -> String",
                     File, :realdirpath, "..", __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :realdirpath, "..", ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :realdirpath, "..", ToPath.new(__dir__)
  end

  def test_realpath
    assert_send_type "(String) -> String",
                     File, :realpath , File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> String",
                     File, :realpath, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> String",
                     File, :realpath, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(String, String) -> String",
                     File, :realpath, "..", __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :realpath, "..", ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :realpath, "..", ToPath.new(__dir__)
  end

  def test_rename
    Dir.mktmpdir do |dir|
      File.open("#{dir}/rename1", "w"){}
      assert_send_type "(String, String) -> 0",
                       File, :rename, "#{dir}/rename1", "#{dir}/new_rename1"

      File.open("#{dir}/rename2", "w"){}
      assert_send_type "(ToStr, ToStr) -> 0",
                       File, :rename, ToStr.new("#{dir}/rename2"), ToStr.new("#{dir}/new_rename2")

      File.open("#{dir}/rename3", "w"){}
      assert_send_type "(ToPath, ToPath) -> 0",
                       File, :rename, ToPath.new("#{dir}/rename3"), ToPath.new("#{dir}/new_rename3")
    end
  end

  def test_setgid?
    Dir.mktmpdir do |dir|
      File.open("#{dir}/setgid", "w"){}
      system "chmod g+s #{dir}/setgid"

      assert_send_type "(String) -> true",
                       File, :setgid?, "#{dir}/setgid"
      assert_send_type "(ToStr) -> true",
                       File, :setgid?, ToStr.new("#{dir}/setgid")
      assert_send_type "(ToPath) -> true",
                       File, :setgid?, ToPath.new("#{dir}/setgid")
      assert_send_type "(IO) -> true",
                       File, :setgid?, IO.new(IO.sysopen("#{dir}/setgid"))
    end

    assert_send_type "(String) -> false",
                     File, :setgid?, File.expand_path(__FILE__)
  end

  def test_setuid?
    Dir.mktmpdir do |dir|
      File.open("#{dir}/setuid", "w"){}
      system "chmod u+s #{dir}/setuid"

      assert_send_type "(String) -> true",
                       File, :setuid?, "#{dir}/setuid"
      assert_send_type "(ToStr) -> true",
                       File, :setuid?, ToStr.new("#{dir}/setuid")
      assert_send_type "(ToPath) -> true",
                       File, :setuid?, ToPath.new("#{dir}/setuid")
      assert_send_type "(IO) -> true",
                       File, :setuid?, IO.new(IO.sysopen("#{dir}/setuid"))
    end

    assert_send_type "(String) -> false",
                     File, :setuid?, File.expand_path(__FILE__)
  end

  def test_size
    assert_send_type "(String) -> Integer",
                     File, :size, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Integer",
                     File, :size, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Integer",
                     File, :size, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Integer",
                     File, :size, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end

  def test_size?
    assert_send_type "(String) -> Integer",
                     File, :size?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Integer",
                     File, :size?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Integer",
                     File, :size?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Integer",
                     File, :size?, IO.new(IO.sysopen(File.expand_path(__FILE__)))

    Dir.mktmpdir do |dir|
      File.open("#{dir}/size", "w"){}
      assert_send_type "(String) -> nil",
                       File, :size?, "#{dir}/size"
    end
  end

  def test_socket?
    assert_send_type "(String) -> false",
                     File, :socket?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> false",
                     File, :socket?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> false",
                     File, :socket?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> false",
                     File, :socket?, IO.new(IO.sysopen(File.expand_path(__FILE__)))

    Socket.unix_server_socket("testsocket") do
      assert_send_type "(String) -> true",
                       File, :socket?, "testsocket"
    end
  end

  def test_split
    assert_send_type "(String) -> [String, String]",
                     File, :split, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> [String, String]",
                     File, :split, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> [String, String]",
                     File, :split, ToPath.new(File.expand_path(__FILE__))
  end

  def test_stat
    assert_send_type "(String) -> File::Stat",
                     File, :stat, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> File::Stat",
                     File, :stat, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> File::Stat",
                     File, :stat, ToPath.new(File.expand_path(__FILE__))
  end

  def test_sticky?
    Dir.mktmpdir do |dir|
      File.open("#{dir}/sticky", "w"){}
      system "chmod +t #{dir}/sticky"

      assert_send_type "(String) -> true",
                       File, :sticky?, "#{dir}/sticky"
      assert_send_type "(ToStr) -> true",
                       File, :sticky?, ToStr.new("#{dir}/sticky")
      assert_send_type "(ToPath) -> true",
                       File, :sticky?, ToPath.new("#{dir}/sticky")
      assert_send_type "(IO) -> true",
                       File, :sticky?, IO.new(IO.sysopen("#{dir}/sticky"))
    end

    assert_send_type "(String) -> false",
                     File, :sticky?, File.expand_path(__FILE__)
  end

  def test_symlink
    Dir.mktmpdir do |dir|
      assert_send_type "(String, String) -> 0",
                       File, :symlink, File.expand_path(__FILE__), "#{dir}/symlink_a"
      assert_send_type "(ToStr, String) -> 0",
                       File, :symlink, ToStr.new(File.expand_path(__FILE__)), "#{dir}/symlink_b"
      assert_send_type "(ToPath, String) -> 0",
                       File, :symlink, ToPath.new(File.expand_path(__FILE__)), "#{dir}/symlink_c"
      assert_send_type "(String, ToStr) -> 0",
                       File, :symlink, File.expand_path(__FILE__), ToStr.new("#{dir}/symlink_d")
      assert_send_type "(String, ToPath) -> 0",
                       File, :symlink, File.expand_path(__FILE__), ToPath.new("#{dir}/symlink_e")
    end
  end

  def test_symlink?
    Dir.mktmpdir do |dir|
      File.symlink(File.expand_path(__FILE__), "#{dir}/symlink")

      assert_send_type "(String) -> true",
                       File, :symlink?, "#{dir}/symlink"
      assert_send_type "(ToStr) -> true",
                       File, :symlink?, ToStr.new("#{dir}/symlink")
      assert_send_type "(ToPath) -> true",
                       File, :symlink?, ToPath.new("#{dir}/symlink")
    end

    assert_send_type "(String) -> false",
                     File, :symlink?, File.expand_path(__FILE__)
  end

  def test_truncate
    Dir.mktmpdir do |dir|
      File.open("#{dir}/truncate", "w") do |f|
        f.write("1234567890")
      end

      assert_send_type "(String, Integer) -> 0",
                       File, :truncate, "#{dir}/truncate", 1
      assert_send_type "(ToStr, Integer) -> 0",
                       File, :truncate, ToStr.new("#{dir}/truncate"), 1
      assert_send_type "(ToPath, Integer) -> 0",
                       File, :truncate, ToPath.new("#{dir}/truncate"), 1
      assert_send_type "(String, ToInt) -> 0",
                       File, :truncate, "#{dir}/truncate", ToInt.new(1)
    end
  end

  def test_umask
    assert_send_type "() -> Integer",
                     File, :umask

    umask = File.umask
    assert_send_type "(Integer) -> Integer",
                     File, :umask, umask
    assert_send_type "(ToInt) -> Integer",
                     File, :umask, ToInt.new(umask)
  end

  def test_unlink
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(String) -> Integer",
                       File, :unlink, "#{dir}/a"

      File.open("#{dir}/b", "w"){}
      assert_send_type "(ToStr) -> Integer",
                       File, :unlink, ToStr.new("#{dir}/b")

      File.open("#{dir}/c", "w"){}
      assert_send_type "(ToPath) -> Integer",
                       File, :unlink, ToPath.new("#{dir}/c")

      File.open("#{dir}/d", "w"){}
      File.open("#{dir}/e", "w"){}
      assert_send_type "(String, String) -> Integer",
                       File, :unlink, "#{dir}/d", "#{dir}/e"
    end
  end

  def test_utime
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(Time, Time, String) -> Integer",
                       File, :utime, File.atime(File.expand_path(__FILE__)), File.atime(File.expand_path(__FILE__)), "#{dir}/a"
      assert_send_type "(Numeric, Numeric, ToStr) -> Integer",
                       File, :utime, 1, 2, ToStr.new("#{dir}/a")
      assert_send_type "(Numeric, Numeric, ToPath) -> Integer",
                       File, :utime, 2.5, 3/2r, ToPath.new("#{dir}/a")

      File.open("#{dir}/b", "w"){}
      assert_send_type "(Time, Time, String, String) -> Integer",
                       File, :utime, File.atime(File.expand_path(__FILE__)), File.atime(File.expand_path(__FILE__)), "#{dir}/a", "#{dir}/b"
    end
  end

  def test_world_readable?
    assert_send_type "(String) -> Integer",
                     File, :world_readable?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> Integer",
                     File, :world_readable?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> Integer",
                     File, :world_readable?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> Integer",
                     File, :world_readable?, IO.new(IO.sysopen(File.expand_path(__FILE__)))

    Dir.mktmpdir do |dir|
      File.open("#{dir}/unreadable", "w"){}
      system "chmod o-r #{dir}/unreadable"

      assert_send_type "(String) -> nil",
                       File, :world_readable?, "#{dir}/unreadable"
    end
  end

  def test_world_writable?
    Dir.mktmpdir do |dir|
      File.open("#{dir}/writable", "w"){}
      system "chmod a+w #{dir}/writable"

      assert_send_type "(String) -> Integer",
                       File, :world_writable?, "#{dir}/writable"
      assert_send_type "(ToStr) -> Integer",
                       File, :world_writable?, ToStr.new("#{dir}/writable")
      assert_send_type "(ToPath) -> Integer",
                       File, :world_writable?, ToPath.new("#{dir}/writable")
      assert_send_type "(IO) -> Integer",
                       File, :world_writable?, IO.new(IO.sysopen("#{dir}/writable"))

      File.open("#{dir}/unwritable", "w"){}
      system "chmod o-w #{dir}/unwritable"

      assert_send_type "(String) -> nil",
                       File, :world_writable?, "#{dir}/unwritable"
    end
  end

  def test_writable?
    assert_send_type "(String) -> bool",
                     File, :writable?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :writable?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :writable?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_writable_real?
    assert_send_type "(String) -> bool",
                     File, :writable_real?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :writable_real?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :writable_real?, ToPath.new(File.expand_path(__FILE__))
  end

  def test_zero?
    assert_send_type "(String) -> bool",
                     File, :zero?, File.expand_path(__FILE__)
    assert_send_type "(ToStr) -> bool",
                     File, :zero?, ToStr.new(File.expand_path(__FILE__))
    assert_send_type "(ToPath) -> bool",
                     File, :zero?, ToPath.new(File.expand_path(__FILE__))
    assert_send_type "(IO) -> bool",
                     File, :zero?, IO.new(IO.sysopen(File.expand_path(__FILE__)))
  end
end

class FileInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::File"

  def test_atime
    assert_send_type "() -> Time",
                     File.open(File.expand_path(__FILE__)), :atime
  end

  def test_chmod
    Dir.mktmpdir do |dir|
      File.open("#{dir}/chmod", "w"){}
      assert_send_type "(Integer) -> 0",
                       File.open("#{dir}/chmod"), :chmod, 0644
      assert_send_type "(ToInt) -> 0",
                       File.open("#{dir}/chmod"), :chmod, ToInt.new(0644)
    end
  end

  def test_chown
    assert_send_type "(Integer, Integer) -> 0",
                     File.open(File.expand_path(__FILE__)), :chown, Process.uid, Process.gid
    assert_send_type "(ToInt, Integer) -> 0",
                     File.open(File.expand_path(__FILE__)), :chown, ToInt.new(Process.uid), Process.gid
    assert_send_type "(nil, Integer) -> 0",
                     File.open(File.expand_path(__FILE__)), :chown, nil, Process.gid
    assert_send_type "(Integer, ToInt) -> 0",
                     File.open(File.expand_path(__FILE__)), :chown, Process.uid, ToInt.new(Process.gid)
    assert_send_type "(Integer, nil) -> 0",
                     File.open(File.expand_path(__FILE__)), :chown, Process.uid, nil
  end

  def test_ctime
    assert_send_type "() -> Time",
                     File.open(File.expand_path(__FILE__)), :ctime
  end

  def test_flock
    Dir.mktmpdir do |dir|
      File.open("#{dir}/flock", "w+") do |f|
        assert_send_type "(Integer) -> 0",
                         f, :flock, File::LOCK_EX
        f.flock(File::LOCK_UN)

        assert_send_type "(ToInt) -> 0",
                         f, :flock, ToInt.new(File::LOCK_SH)
        f.flock(File::LOCK_UN)
      end
    end
  end

  def test_lstat
    assert_send_type "() -> File::Stat",
                     File.open(File.expand_path(__FILE__)), :lstat
  end

  def test_mtime
    assert_send_type "() -> Time",
                     File.open(File.expand_path(__FILE__)), :mtime
  end

  def test_path
    assert_send_type "() -> String",
                     File.open(File.expand_path(__FILE__)), :path
  end

  def test_size
    assert_send_type "() -> Integer",
                     File.open(File.expand_path(__FILE__)), :size
  end

  def test_to_path
    assert_send_type "() -> String",
                     File.open(File.expand_path(__FILE__)), :to_path
  end

  def test_truncate
    Dir.mktmpdir do |dir|
      File.open("#{dir}/truncate", "w") do |f|
        f.write("1234567890")
      end

      assert_send_type "(Integer) -> 0",
                       File.open("#{dir}/truncate", "w"), :truncate, 1
      assert_send_type "(ToInt) -> 0",
                       File.open("#{dir}/truncate", "w"), :truncate, ToInt.new(1)
    end
  end
end
