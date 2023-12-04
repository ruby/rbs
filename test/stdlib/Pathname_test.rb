require_relative "test_helper"
require 'pathname'

class PathnameSingletonTest < Test::Unit::TestCase
  include TestHelper
  library 'pathname'
  testing 'singleton(::Pathname)'

  def test_getwd
    assert_send_type '() -> Pathname',
                     Pathname, :getwd
  end

  def test_glob
    assert_send_type '(String) -> Array[Pathname]',
                     Pathname, :glob, '*'
    assert_send_type '(Array[String]) -> Array[Pathname]',
                     Pathname, :glob, ['*', 'lib/*']
    assert_send_type '(String, ?Integer) -> Array[Pathname]',
                     Pathname, :glob, '*', File::FNM_NOESCAPE
    assert_send_type '(String) { (Pathname) -> untyped } -> nil',
                     Pathname, :glob, '*' do true end
  end

  def test_pwd
    assert_send_type '() -> Pathname',
                     Pathname, :pwd
  end

  def test_initialize
    assert_send_type '(String) -> Pathname',
                     Pathname, :new, 'foo'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname, :new, ToStr.new('foo')
    assert_send_type '(Pathname) -> Pathname',
                     Pathname, :new, Pathname('foo')
  end
end

class PathnameInstanceTest < Test::Unit::TestCase
  include TestHelper
  library 'pathname'
  testing '::Pathname'

  def test_plus
    assert_send_type '(Pathname) -> Pathname',
                     Pathname('foo'), :+, Pathname('bar')
    assert_send_type '(String) -> Pathname',
                     Pathname('foo'), :+, 'bar'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname('foo'), :+, ToStr.new('bar')
  end

  def test_slash
    assert_send_type '(Pathname) -> Pathname',
                     Pathname('foo'), :/, Pathname('bar')
    assert_send_type '(String) -> Pathname',
                     Pathname('foo'), :/, 'bar'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname('foo'), :/, ToStr.new('bar')
  end

  def test_spaceship
    assert_send_type '(Pathname) -> Integer',
                     Pathname('foo'), :<=>, Pathname('bar')
    assert_send_type '(untyped) -> nil',
                     Pathname('foo'), :<=>, 'foo'
  end

  def test_eqeq
    assert_send_type '(Pathname) -> bool',
                     Pathname('foo'), :==, Pathname('bar')
    assert_send_type '(Pathname) -> bool',
                     Pathname('foo'), :==, Pathname('foo')
  end

  def test_eqeqeq
    assert_send_type '(Pathname) -> bool',
                     Pathname('foo'), :===, Pathname('bar')
    assert_send_type '(Pathname) -> bool',
                     Pathname('foo'), :===, Pathname('foo')
  end

  def test_absolute?
    assert_send_type '() -> bool',
                     Pathname('foo'), :absolute?
    assert_send_type '() -> bool',
                     Pathname('/foo'), :absolute?
  end

  def test_ascend
    assert_send_type '() { (Pathname) -> untyped } -> nil',
                     Pathname('foo'), :ascend do end
    assert_send_type '() -> Enumerator[Pathname, nil]',
                     Pathname('foo'), :ascend
  end

  def test_atime
    assert_send_type '() -> Time',
                     Pathname('/'), :atime
  end

  def test_basename
    assert_send_type '() -> Pathname',
                     Pathname('foo/bar.rb'), :basename
    assert_send_type '(String) -> Pathname',
                     Pathname('foo/bar.rb'), :basename, '.rb'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname('foo/bar.rb'), :basename, ToStr.new('.rb')
  end

  def test_binread
    assert_send_type '() -> String',
                     Pathname(File.expand_path(__FILE__)), :binread
    assert_send_type '(Integer) -> String',
                     Pathname(File.expand_path(__FILE__)), :binread, 42
    assert_send_type '(Integer, Integer) -> String',
                     Pathname(File.expand_path(__FILE__)), :binread, 42, 43
  end

  def test_binwrite
    Tempfile.create('rbs-pathname-binwrite-test') do |f|
      f.close
      path = Pathname(f.path)

      assert_send_type '(String) -> Integer',
                       path, :binwrite, 'foo'
      assert_send_type '(String, Integer) -> Integer',
                       path, :binwrite, 'foo', 42
      assert_send_type '(String, Integer, textmode: String) -> Integer',
                       path, :binwrite, 'foo', 42, textmode: "true"
    end
  end

  def test_birthtime
    assert_send_type '() -> Time',
                     Pathname('/'), :birthtime
  rescue NotImplementedError
  end

  def test_blockdev?
    assert_send_type '() -> bool',
                     Pathname('/'), :blockdev?
    assert_send_type '() -> bool',
                     Pathname('/unknown'), :blockdev?
    assert_send_type '() -> bool',
                     Pathname('/dev/sda1'), :blockdev?
  end

  def test_chardev?
    assert_send_type '() -> bool',
                     Pathname('/'), :chardev?
    assert_send_type '() -> bool',
                     Pathname('/unknown'), :chardev?
    assert_send_type '() -> bool',
                     Pathname('/dev/sda1'), :chardev?
  end

  def test_children
    assert_send_type '() -> Array[Pathname]',
                     Pathname('.'), :children
    assert_send_type '(bool) -> Array[Pathname]',
                     Pathname('.'), :children, false
  end

  def test_chmod
    Tempfile.create('rbs-pathname-chmod-test') do |f|
      path = Pathname(f.path)

      assert_send_type '(Integer) -> Integer',
                       path, :chmod, 0644
    end
  end

  def test_chown
    Tempfile.create('rbs-pathname-chown-test') do |f|
      path = Pathname(f.path)

      assert_send_type '(Integer, Integer) -> Integer',
                       path, :chown, path.stat.uid, path.stat.gid
    end
  end

  def test_cleanpath
    assert_send_type '() -> Pathname',
                     Pathname('foo/../bar'), :cleanpath
    assert_send_type '(bool) -> Pathname',
                     Pathname('foo/../bar'), :cleanpath, true
  end

  def test_ctime
    assert_send_type '() -> Time',
                     Pathname('/'), :ctime
  end

  def test_delete
    Tempfile.create('rbs-pathname-delete-test') do |f|
      path = Pathname(f.path)

      assert_send_type '() -> Integer',
                       path, :delete
    end
  end

  def test_descend
    assert_send_type '() { (Pathname) -> untyped } -> nil',
                     Pathname('foo'), :descend do end
    assert_send_type '() -> Enumerator[Pathname, nil]',
                     Pathname('foo'), :descend
  end

  def test_directory?
    assert_send_type '() -> bool',
                     Pathname('foo'), :directory?
    assert_send_type '() -> bool',
                     Pathname('.'), :directory?
  end

  def test_dirname
    assert_send_type '() -> Pathname',
                     Pathname('foo'), :dirname
  end

  def test_each_child
    assert_send_type '() { (Pathname) -> untyped } -> Array[Pathname]',
                     Pathname('.'), :each_child do end
    assert_send_type '() -> Enumerator[Pathname, Array[Pathname]]',
                     Pathname('.'), :each_child
  end

  def test_each_entry
    assert_send_type '() { (Pathname) -> untyped } -> nil',
                     Pathname('.'), :each_entry do end
  end

  def test_each_filename
    assert_send_type '() { (String) -> untyped } -> nil',
                     Pathname('/usr/bin/ruby'), :each_filename do end
    assert_send_type '() -> Enumerator[String, nil]',
                     Pathname('/usr/bin/ruby'), :each_filename
  end

  def test_each_line
    path = Pathname(File.expand_path(__FILE__))

    assert_send_type '() { (String) -> untyped } -> nil',
                     path, :each_line do end
    assert_send_type '(String) { (String) -> untyped } -> nil',
                     path, :each_line, 'def' do end
    assert_send_type '(String, Integer) { (String) -> untyped } -> nil',
                     path, :each_line, 'def', 42 do end
    assert_send_type '(Integer) { (String) -> untyped } -> nil',
                     path, :each_line, 42 do end
    assert_send_type '() -> Enumerator[String, nil]',
                     path, :each_line
  end

  def test_empty?
    assert_send_type '() -> bool',
                     Pathname('.'), :empty?
  end

  def test_entries
    assert_send_type '() -> Array[Pathname]',
                     Pathname(__dir__), :entries
  end

  def test_eql?
    path = Pathname('.')

    assert_send_type '(untyped) -> bool',
                     path, :eql?, path
    assert_send_type '(untyped) -> bool',
                     path, :eql?, 'foobar'
  end

  def test_executable?
    assert_send_type '() -> bool',
                     Pathname('/usr/bin/env'), :executable?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :executable?
  end

  def test_executable_real?
    assert_send_type '() -> bool',
                     Pathname('/usr/bin/env'), :executable_real?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :executable_real?
  end

  def test_exist?
    assert_send_type '() -> bool',
                     Pathname('/'), :exist?
    assert_send_type '() -> bool',
                     Pathname('/unknown'), :exist?
  end

  def test_expand_path
    assert_send_type '() -> Pathname',
                     Pathname('~/'), :expand_path
    assert_send_type '(String) -> Pathname',
                     Pathname('./foo'), :expand_path, __dir__
  end

  def test_extname
    assert_send_type '() -> String',
                     Pathname('test.rb'), :extname
  end

  def test_file?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :file?
    assert_send_type '() -> bool',
                     Pathname('/unknown'), :file?
  end

  def test_find
    assert_send_type '() { (Pathname) -> untyped } -> nil',
                     Pathname(__dir__), :find do end
    assert_send_type '(ignore_error: bool) -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find, ignore_error: true
    assert_send_type '(ignore_error: Symbol) -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find, ignore_error: :true
    assert_send_type '() -> Enumerator[Pathname, nil]',
                     Pathname(__dir__), :find
  end

  def test_fnmatch
    assert_send_type '(String) -> bool',
                     Pathname('foo'), :fnmatch, 'fo*'
    assert_send_type '(String) -> bool',
                     Pathname('foo'), :fnmatch, 'ba*'
  end

  def test_fnmatch?
    assert_send_type '(String) -> bool',
                     Pathname('foo'), :fnmatch?, 'fo*'
    assert_send_type '(String) -> bool',
                     Pathname('foo'), :fnmatch?, 'ba*'
  end

  def test_freeze
    assert_send_type '() -> Pathname',
                     Pathname('foo'), :freeze
  end

  def test_ftype
    assert_send_type '() -> String',
                     Pathname(File.expand_path(__FILE__)), :ftype
    assert_send_type '() -> String',
                     Pathname(__dir__), :ftype
  end

  def test_glob
    assert_send_type '(String) -> Array[Pathname]',
                     Pathname('.'), :glob, '*'
    assert_send_type '(Array[String]) -> Array[Pathname]',
                     Pathname('.'), :glob, ['*', 'lib/*']
    assert_send_type '(String, ?Integer) -> Array[Pathname]',
                     Pathname('.'), :glob, '*', File::FNM_NOESCAPE
    assert_send_type '(String) { (Pathname) -> untyped } -> nil',
                     Pathname('.'), :glob, '*' do end
  end

  def test_grpowned?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :grpowned?
    assert_send_type '() -> bool',
                     Pathname('/'), :grpowned?
  end

  def test_hash
    assert_send_type '() -> Integer',
                     Pathname('.'), :hash
  end

  def test_inspect
    assert_send_type '() -> String',
                     Pathname('.'), :inspect
  end

  def test_join
    assert_send_type '() -> Pathname',
                     Pathname('.'), :join
    assert_send_type '(String) -> Pathname',
                     Pathname('.'), :join, 'foo'
    assert_send_type '(String, String) -> Pathname',
                     Pathname('.'), :join, 'foo', 'bar'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname('.'), :join, ToStr.new('foo')
    assert_send_type '(Pathname) -> Pathname',
                     Pathname('.'), :join, Pathname('foo')
  end

  def test_lchmod
    Tempfile.create('rbs-pathname-lchmod-test') do |f|
      path = Pathname(f.path)

      assert_send_type '(Integer) -> Integer',
                       path, :lchmod, 0644
    rescue NotImplementedError
    end
  end

  def test_lchown
    Tempfile.create('rbs-pathname-lchown-test') do |f|
      path = Pathname(f.path)

      assert_send_type '(Integer, Integer) -> Integer',
                       path, :lchown, path.stat.uid, path.stat.gid
    end
  end

  def test_lstat
    assert_send_type '() -> ::File::Stat',
                     Pathname(File.expand_path(__FILE__)), :lstat
  end

  def test_make_link
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      src = dir + 'src'
      FileUtils.touch src

      assert_send_type '(String) -> Integer',
                       dir + 'dst1', :make_link, src.to_s
      assert_send_type '(Pathname) -> Integer',
                       dir + 'dst2', :make_link, src
      assert_send_type '(ToStr) -> Integer',
                       dir + 'dst3', :make_link, ToStr.new(src.to_s)
    end
  end

  def test_make_symlink
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      src = dir + 'src'
      FileUtils.touch src

      assert_send_type '(String) -> Integer',
                       dir + 'dst1', :make_symlink, src.to_s
      assert_send_type '(Pathname) -> Integer',
                       dir + 'dst2', :make_symlink, src
      assert_send_type '(ToStr) -> Integer',
                       dir + 'dst3', :make_symlink, ToStr.new(src.to_s)
    end
  end

  def test_mkdir
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      assert_send_type '() -> Integer',
                       dir + 'a', :mkdir
      assert_send_type '(Integer) -> Integer',
                       dir + 'b', :mkdir, 0700
    end
  end

  def test_mkpath
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      assert_send_type '() -> nil',
                       dir + 'a/b/c', :mkpath
    end
  end

  def test_mountpoint?
    assert_send_type '() -> bool',
                     Pathname('/'), :mountpoint?
    assert_send_type '() -> bool',
                     Pathname('/etc'), :mountpoint?
  end

  def test_mtime
    assert_send_type '() -> Time',
                     Pathname('/'), :mtime
  end

  def test_open
    Tempfile.create('rbs-pathname-binwrite-test') do |f|
      path = Pathname(f.path)

      assert_send_type '() -> File',
                       path, :open
      assert_send_type '(String) -> File',
                       path, :open, 'r'
      assert_send_type '(String, Integer) -> File',
                       path, :open, 'r', 0644
      assert_send_type '() { (File) -> true} -> true',
                       path, :open do true end
    end
  end

  def test_opendir
    assert_send_type '() -> Dir',
                     Pathname(__dir__), :opendir
    assert_send_type '() { (Dir) -> true } -> true',
                     Pathname(__dir__), :opendir do true end
    refute_send_type '(encoding: Encoding) -> Dir',
                     Pathname(__dir__), :opendir, encoding: Encoding::UTF_8
  end

  def test_owened?
    assert_send_type '() -> bool',
                     Pathname('/'), :owned?
  end

  def test_parent
    assert_send_type '() -> Pathname',
                     Pathname('/foo/bar'), :parent
    assert_send_type '() -> Pathname',
                     Pathname('/'), :parent
  end

  def test_pipe?
    assert_send_type '() -> bool',
                     Pathname('/'), :pipe?
  end

  def test_read
    assert_send_type '() -> String',
                     Pathname(File.expand_path(__FILE__)), :read
    assert_send_type '(Integer) -> String',
                     Pathname(File.expand_path(__FILE__)), :read, 42
    assert_send_type '(Integer, Integer) -> String',
                     Pathname(File.expand_path(__FILE__)), :read, 42, 43
    assert_send_type '(encoding: String) -> String',
                     Pathname(File.expand_path(__FILE__)), :read, encoding: 'UTF-8'
    assert_send_type '(encoding: ToStr) -> String',
                     Pathname(File.expand_path(__FILE__)), :read, encoding: ToStr.new('UTF-8')
    assert_send_type '(encoding: Encoding) -> String',
                     Pathname(File.expand_path(__FILE__)), :read, encoding: Encoding::UTF_8
  end

  def test_readable?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :readable?
  end

  def test_readable_real?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :readable_real?
  end

  def test_readlines
    assert_send_type '() -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines
    assert_send_type '(String) -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines, 'a'
    assert_send_type '(Integer) -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines, 42
    assert_send_type '(String, Integer) -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines, 'a', 42
    assert_send_type '(String, Integer, chomp: true) -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines, 'a', 42, chomp: true
    assert_send_type '(String, Integer, binmode: true) -> Array[String]',
                     Pathname(File.expand_path(__FILE__)), :readlines, 'a', 42, binmode: true
  end

  def test_readlink
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      src = dir.join('src')
      dst = dir.join('dst')
      FileUtils.touch src
      dst.make_symlink(src)

      assert_send_type '() -> Pathname',
                       dst, :readlink
    end
  end

  def test_realdirpath
    assert_send_type '() -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realdirpath
    assert_send_type '(String) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realdirpath, '.'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realdirpath, ToStr.new('.')
    assert_send_type '(Pathname) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realdirpath, Pathname.new('.')
  end

  def test_realpath
    assert_send_type '() -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realpath
    assert_send_type '(String) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realpath, '.'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realpath, ToStr.new('.')
    assert_send_type '(Pathname) -> Pathname',
                     Pathname(File.expand_path(__FILE__)), :realpath, Pathname.new('.')
  end

  def test_relative?
    assert_send_type '() -> bool',
                     Pathname('.'), :relative?
    assert_send_type '() -> bool',
                     Pathname('/'), :relative?
  end

  def test_relative_path_from
    assert_send_type '(Pathname) -> Pathname',
                     Pathname('.'), :relative_path_from, Pathname('.')
    assert_send_type '(String) -> Pathname',
                     Pathname('.'), :relative_path_from, '.'

    assert_send_type '(_ToStr) -> Pathname',
                     Pathname('.'), :relative_path_from, ToStr.new('.').__with_object_methods(:is_a?)
  end

  def test_rename
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      src = dir.join('src')
      dst1 = dir.join('dst1')
      dst2 = dir.join('dst2')
      dst3 = dir.join('dst3')
      FileUtils.touch src

      assert_send_type '(Pathname) -> 0',
                       src, :rename, dst1
      assert_send_type '(String) -> 0',
                       dst1, :rename, dst2.to_s
      assert_send_type '(ToStr) -> 0',
                       dst2, :rename, ToStr.new(dst3.to_s)
    end
  end

  def test_rmdir
    Dir.mktmpdir do |dir|
      target = Pathname(dir).join('target')
      target.mkdir
      assert_send_type '() -> 0',
                       target, :rmdir
    end
  end

  def test_rmtree
    Dir.mktmpdir do |dir|
      target = Pathname(dir).join('target')
      target.mkdir
      assert_send_type '() -> void',
                       target, :rmtree
    end
  end

  def test_root?
    assert_send_type '() -> bool',
                     Pathname('.'), :root?
    assert_send_type '() -> bool',
                     Pathname('/'), :root?
  end

  def test_setgid?
    assert_send_type '() -> bool',
                     Pathname('.'), :setgid?
  end

  def test_setuid?
    assert_send_type '() -> bool',
                     Pathname('.'), :setuid?
  end

  def test_size
    assert_send_type '() -> Integer',
                     Pathname(File.expand_path(__FILE__)), :size
  end

  def test_size?
    assert_send_type '() -> Integer',
                     Pathname(File.expand_path(__FILE__)), :size?

    assert_send_type '() -> nil',
                     Pathname('/does/not/exist'), :size?
  end

  def test_socket?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :socket?
  end

  def test_split
    assert_send_type '() -> [Pathname, Pathname]',
                     Pathname(File.expand_path(__FILE__)), :split
    assert_send_type '() -> [Pathname, Pathname]',
                     Pathname('/'), :split
  end

  def test_stat
    assert_send_type '() -> File::Stat',
                     Pathname(File.expand_path(__FILE__)), :stat
  end

  def test_sticky?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :sticky?
  end

  def test_sub
    assert_send_type '(String, String) -> Pathname',
                     Pathname("/usr/bin/perl"), :sub, "perl", 'ruby'
    assert_send_type '(ToStr, ToStr) -> Pathname',
                     Pathname("/usr/bin/perl"), :sub, ToStr.new("perl"), ToStr.new('ruby')
    assert_send_type '(Regexp, Hash[String, String]) -> Pathname',
                     Pathname("/usr/bin/perl"), :sub, /perl/, { 'perl' => 'ruby' }
    assert_send_type '(String) { (String) -> String } -> Pathname',
                     Pathname("/usr/bin/perl"), :sub, 'perl' do 'ruby' end
  end

  def test_sub_ext
    assert_send_type '(String) -> Pathname',
                     Pathname("foo.rb"), :sub_ext, '.rbs'
    assert_send_type '(ToStr) -> Pathname',
                     Pathname("foo.rb"), :sub_ext, ToStr.new('.rbs')
  end

  def test_symlink?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :symlink?
  end

  def test_sysopen
    assert_send_type '() -> Integer',
                     Pathname(File.expand_path(__FILE__)), :sysopen
    assert_send_type '(String) -> Integer',
                     Pathname(File.expand_path(__FILE__)), :sysopen, 'r'
    assert_send_type '(String, Integer) -> Integer',
                     Pathname(File.expand_path(__FILE__)), :sysopen, 'r', 0644
  end

  def test_taint
    if Pathname.method_defined?(:taint)
      assert_send_type '() -> Pathname',
                      Pathname(File.expand_path(__FILE__)), :taint
    end
  end

  def test_to_path
    assert_send_type '() -> String',
                     Pathname(File.expand_path(__FILE__)), :to_path
  end

  def test_truncate
    Tempfile.create('rbs-pathname-truncate-test') do |f|
      path = Pathname(f.path)

      assert_send_type '(Integer) -> 0',
                       path, :truncate, 42
    end
  end

  def test_unlink
    Tempfile.create('rbs-pathname-unlink-test') do |f|
      path = Pathname(f.path)

      assert_send_type '() -> Integer',
                       path, :unlink
    end
  end

  def test_untaint
    if Pathname.method_defined?(:untaint)
      assert_send_type '() -> Pathname',
                      Pathname(File.expand_path(__FILE__)), :untaint
    end
  end

  def test_utime
    Tempfile.create('rbs-pathname-unlink-test') do |f|
      path = Pathname(f.path)
      now = Time.now
      assert_send_type '(Time, Time) -> Integer',
                       path, :utime, now, now
      assert_send_type '(Integer, Integer) -> Integer',
                       path, :utime, now.to_i, now.to_i
    end
  end

  def test_world_readable?
    assert_send_type '() -> (Integer | nil)',
                     Pathname(File.expand_path(__FILE__)), :world_readable?
    assert_send_type '() -> (Integer | nil)',
                     Pathname('/'), :world_readable?
  end

  def test_world_writable?
    assert_send_type '() -> (Integer | nil)',
                     Pathname(File.expand_path(__FILE__)), :world_writable?
    assert_send_type '() -> (Integer | nil)',
                     Pathname('/'), :world_writable?
  end

  def test_writable?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :writable?
    assert_send_type '() -> bool',
                     Pathname('/'), :writable?
  end

  def test_write
    Tempfile.create('rbs-pathname-write-test') do |f|
      path = Pathname(f.path)
      assert_send_type '(String) -> Integer',
                       path, :write, 'foo'
      assert_send_type '(String, Integer) -> Integer',
                       path, :write, 'foo', 42
      assert_send_type '(String, Integer, encoding: Encoding) -> Integer',
                       path, :write, 'foo', 42, encoding: Encoding::UTF_8
    end
  end

  def test_zero?
    assert_send_type '() -> bool',
                     Pathname(File.expand_path(__FILE__)), :zero?
  end
end
