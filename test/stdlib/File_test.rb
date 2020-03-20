require_relative "test_helper"
require "ruby/signature/test/test_helper"

class FileSingletonTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "singleton(::File)"

  def test_absolute_path
    assert_send_type "(String) -> String",
                     File, :absolute_path, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :absolute_path, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :absolute_path, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :absolute_path, __FILE__, __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :absolute_path, __FILE__, ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :absolute_path, __FILE__, ToPath.new(__dir__)
  end

  def test_absolute_path?
    assert_send_type "(String) -> bool",
                     File, :absolute_path?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :absolute_path?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :absolute_path?, ToPath.new(__FILE__)
  end

  def test_atime
    assert_send_type "(String) -> Time",
                     File, :atime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :atime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :atime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :atime, IO.new(IO.sysopen(__FILE__))
  end

  def test_basename
    assert_send_type "(String) -> String",
                     File, :basename, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :basename, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :basename, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :basename, __FILE__, '.rb'
    assert_send_type "(String, ToStr) -> String",
                     File, :basename, __FILE__, ToStr.new('.rb')
  end

  def test_blockdev?
    assert_send_type "(String) -> bool",
                     File, :blockdev?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :blockdev?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :blockdev?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :blockdev?, IO.new(IO.sysopen(__FILE__))
  end

  def test_chardev?
    assert_send_type "(String) -> bool",
                     File, :chardev?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :chardev?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :chardev?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :chardev?, IO.new(IO.sysopen(__FILE__))
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
                     File, :chown, Process.uid, Process.gid, __FILE__
    assert_send_type "(ToInt, Integer, String) -> Integer",
                     File, :chown, ToInt.new(Process.uid), Process.gid, __FILE__
    assert_send_type "(nil, Integer, String) -> Integer",
                     File, :chown, nil, Process.gid, __FILE__
    assert_send_type "(Integer, ToInt, String) -> Integer",
                     File, :chown, Process.uid, ToInt.new(Process.gid), __FILE__
    assert_send_type "(Integer, nil, String) -> Integer",
                     File, :chown, Process.uid, nil, __FILE__
    assert_send_type "(Integer, Integer, ToStr) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToStr.new(__FILE__)
    assert_send_type "(Integer, Integer, ToPath) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToPath.new(__FILE__)
    assert_send_type "(Integer, nil, String, String) -> Integer",
                     File, :chown, Process.uid, nil, __FILE__, __FILE__
  end

  def test_ctime
    assert_send_type "(String) -> Time",
                     File, :ctime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :ctime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :ctime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :ctime, IO.new(IO.sysopen(__FILE__))
  end

  def test_delete
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(String) -> Integer", File, :delete, "#{dir}/a"

      File.open("#{dir}/b", "w"){}
      assert_send_type "(ToStr) -> Integer", File, :delete, ToStr.new("#{dir}/b")

      File.open("#{dir}/c", "w"){}
      assert_send_type "(ToPath) -> Integer", File, :delete, ToPath.new("#{dir}/c")

      File.open("#{dir}/d", "w"){}
      File.open("#{dir}/e", "w"){}
      assert_send_type "(String, String) -> Integer", File, :delete, "#{dir}/d", "#{dir}/e"
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
    assert_send_type "(String) -> bool",
                     File, :dirname, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :dirname, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :dirname, ToPath.new(__FILE__)
  end

  def test_empty?
    assert_send_type "(String) -> bool",
                     File, :empty?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :empty?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :empty?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :empty?, IO.new(IO.sysopen(__FILE__))
  end

  def test_executable?
    assert_send_type "(String) -> bool",
                     File, :executable?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :executable?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :executable?, ToPath.new(__FILE__)
  end

  def test_executable_real?
    assert_send_type "(String) -> bool",
                     File, :executable_real?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :executable_real?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :executable_real?, ToPath.new(__FILE__)
  end

  def test_exist?
    assert_send_type "(String) -> bool",
                     File, :exist?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :exist?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :exist?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :exist?, IO.new(IO.sysopen(__FILE__))
  end

  def test_exists?
    assert_send_type "(String) -> bool",
                     File, :exists?, __FILE__
  end

  def test_expand_path
    assert_send_type "(String) -> String",
                     File, :expand_path, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :expand_path, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :expand_path, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :expand_path, __FILE__, __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :expand_path, __FILE__, ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :expand_path, __FILE__, ToPath.new(__dir__)
  end

  def test_extname
    assert_send_type "(String) -> String",
                     File, :extname, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :extname, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :extname, ToPath.new(__FILE__)
  end

  def test_file?
    assert_send_type "(String) -> bool",
                     File, :file?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :file?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :file?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :file?, IO.new(IO.sysopen(__FILE__))
  end

  def test_fnmatch
    assert_send_type "(String, String) -> bool",
                     File, :fnmatch, 'File_test', __FILE__
    assert_send_type "(ToStr, String) -> bool",
                     File, :fnmatch, ToStr.new('File_test'), __FILE__
    assert_send_type "(String, ToStr) -> bool",
                     File, :fnmatch, 'File_test', ToStr.new(__FILE__)
    assert_send_type "(String, ToPath) -> bool",
                     File, :fnmatch, 'File_test', ToPath.new(__FILE__)
    assert_send_type "(String, String, Integer) -> bool",
                     File, :fnmatch, 'File_test', __FILE__, File::FNM_CASEFOLD
    assert_send_type "(String, String, ToInt) -> bool",
                     File, :fnmatch, 'File_test', __FILE__, ToInt.new(File::FNM_CASEFOLD)
  end

  def test_fnmatch?
    assert_send_type "(String, String) -> bool",
                     File, :fnmatch?, "File_test", __FILE__
  end

  def test_ftype
    assert_send_type "(String) -> String",
                     File, :ftype, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :ftype, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :ftype, ToPath.new(__FILE__)
  end

  def test_grpowned?
    assert_send_type "(String) -> bool",
                     File, :grpowned?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :grpowned?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :grpowned?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :grpowned?, IO.new(IO.sysopen(__FILE__))
  end

  def test_identical?
    assert_send_type "(String, String) -> bool",
                     File, :identical?, __FILE__, __FILE__
    assert_send_type "(ToStr, String) -> bool",
                     File, :identical?, ToStr.new(__FILE__), __FILE__
    assert_send_type "(ToPath, String) -> bool",
                     File, :identical?, ToPath.new(__FILE__), __FILE__
    assert_send_type "(IO, String) -> bool",
                     File, :identical?, IO.new(IO.sysopen(__FILE__)), __FILE__
    assert_send_type "(String, ToStr) -> bool",
                     File, :identical?, __FILE__, ToStr.new(__FILE__)
    assert_send_type "(String, ToPath) -> bool",
                     File, :identical?, __FILE__, ToPath.new(__FILE__)
    assert_send_type "(String, IO) -> bool",
                     File, :identical?, __FILE__, IO.new(IO.sysopen(__FILE__))
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
                     File, :lchown, Process.uid, Process.gid, __FILE__
    assert_send_type "(ToInt, Integer, String) -> Integer",
                     File, :lchown, ToInt.new(Process.uid), Process.gid, __FILE__
    assert_send_type "(nil, Integer, String) -> Integer",
                     File, :lchown, nil, Process.gid, __FILE__
    assert_send_type "(Integer, ToInt, String) -> Integer",
                     File, :lchown, Process.uid, ToInt.new(Process.gid), __FILE__
    assert_send_type "(Integer, nil, String) -> Integer",
                     File, :lchown, Process.uid, nil, __FILE__
    assert_send_type "(Integer, Integer, ToStr) -> Integer",
                     File, :lchown, Process.uid, Process.gid, ToStr.new(__FILE__)
    assert_send_type "(Integer, Integer, ToPath) -> Integer",
                     File, :lchown, Process.uid, Process.gid, ToPath.new(__FILE__)
    assert_send_type "(Integer, nil, String, String) -> Integer",
                     File, :lchown, Process.uid, nil, __FILE__, __FILE__
  end

  def test_link
    assert_send_type "(String, String) -> 0",
                     File, :link, __FILE__, "new_name"
    File.unlink("new_name")

    assert_send_type "(ToStr, ToStr) -> 0",
                     File, :link, ToStr.new(__FILE__), ToStr.new("new_name")
    File.unlink("new_name")

    assert_send_type "(ToPath, ToPath) -> 0",
                     File, :link, ToPath.new(__FILE__), ToPath.new("new_name")
    File.unlink("new_name")
  end

  def test_lstat
    assert_send_type "(String) -> File::Stat",
                     File, :lstat, __FILE__
    assert_send_type "(ToStr) -> File::Stat",
                     File, :lstat, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> File::Stat",
                     File, :lstat, ToPath.new(__FILE__)
  end

  def test_lutime
    Dir.mktmpdir do |dir|
      File.open("#{dir}/a", "w"){}
      assert_send_type "(Time, Time, String) -> Integer",
                       File, :lutime, File.atime(__FILE__), File.atime(__FILE__), "#{dir}/a"
      assert_send_type "(Numeric, Numeric, ToStr) -> Integer",
                       File, :lutime, 1, 2, ToStr.new("#{dir}/a")
      assert_send_type "(Numeric, Numeric, ToPath) -> Integer",
                       File, :lutime, 2.5, 3/2r, ToPath.new("#{dir}/a")

      File.open("#{dir}/b", "w"){}
      assert_send_type "(Time, Time, String, String) -> Integer",
                       File, :lutime, File.atime(__FILE__), File.atime(__FILE__), "#{dir}/a", "#{dir}/b"
    end
  end

  def test_mkfifo
    Dir.mktmpdir do |dir|
      assert_send_type "(String) -> 0", File, :mkfifo, "#{dir}/a"
      assert_send_type "(ToPath) -> 0", File, :mkfifo, ToPath.new("#{dir}/b")
      assert_send_type "(String, Integer) -> 0", File, :mkfifo, "#{dir}/c", 0666
      assert_send_type "(String, ToInt) -> 0", File, :mkfifo, "#{dir}/d", ToInt.new(0666)
    end
  end

  def test_mtime
    assert_send_type "(String) -> Time",
                     File, :mtime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :mtime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :mtime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :mtime, IO.new(IO.sysopen(__FILE__))
  end

  def test_owned?
    assert_send_type "(String) -> bool",
                     File, :owned?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :owned?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :owned?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :owned?, IO.new(IO.sysopen(__FILE__))
  end

  def test_path
    assert_send_type "(String) -> String",
                     File, :path, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :path, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :path, ToPath.new(__FILE__)
  end

  def test_pipe?
    assert_send_type "(String) -> bool",
                     File, :pipe?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :pipe?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :pipe?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :pipe?, IO.new(IO.sysopen(__FILE__))
  end

  def test_readable?
    assert_send_type "(String) -> bool",
                     File, :readable?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :readable?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :readable?, ToPath.new(__FILE__)
  end

  def test_readable_real?
    assert_send_type "(String) -> bool",
                     File, :readable_real?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :readable_real?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :readable_real?, ToPath.new(__FILE__)
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
                     File, :realdirpath , __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :realdirpath, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :realdirpath, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :realdirpath, "..", __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :realdirpath, "..", ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :realdirpath, "..", ToPath.new(__dir__)
  end

  def test_realpath
    assert_send_type "(String) -> String",
                     File, :realpath , __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :realpath, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :realpath, ToPath.new(__FILE__)
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
                File, :setgid?, __FILE__
  end
end
