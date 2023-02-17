require_relative "test_helper"
require "fileutils"

module TmpdirHelper
  private

  def in_tmpdir(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &block)
    end
  end
end

class FileUtilsSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  include TmpdirHelper

  library "fileutils"
  testing "singleton(::FileUtils)"

  def test_cd
    dir = Dir.pwd

    begin
      assert_send_type  "(String) -> void",
                        FileUtils, :cd, __dir__
      assert_send_type  "(ToStr) -> void",
                        FileUtils, :cd, ToStr.new(__dir__)
      assert_send_type  "(ToPath, verbose: bool) -> void",
                        FileUtils, :cd, ToPath.new(__dir__), verbose: false
      assert_send_type  "(String) { (String) -> Integer } -> Integer",
                        FileUtils, :cd, __dir__ do |dir| 1 end
      assert_send_type  "(ToStr) { (String) -> Integer } -> Integer",
                        FileUtils, :cd, ToStr.new(__dir__) do |dir| 1 end
      assert_send_type  "(ToPath, verbose: nil) { (String) -> Integer } -> Integer",
                        FileUtils, :cd, ToPath.new(__dir__), verbose: nil do |dir| 1 end
    ensure
      Dir.chdir dir
    end
  end

  def test_chdir
    dir = Dir.pwd

    begin
      assert_send_type  "(String) -> void",
                        FileUtils, :chdir, __dir__
      assert_send_type  "(String) { (String) -> Integer } -> Integer",
                        FileUtils, :chdir, __dir__ do |dir| 1 end
    ensure
      Dir.chdir(dir)
    end
  end

  def test_chmod
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        FileUtils, :chmod, 0755, dir
      assert_send_type  "(Integer, ToStr) -> void",
                        FileUtils, :chmod, 0755, ToStr.new(dir)
      assert_send_type  "(Integer, ToPath) -> void",
                        FileUtils, :chmod, 0755, ToPath.new(dir)
      assert_send_type  "(String, Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :chmod, "u=wrx", [dir, ToStr.new(dir), ToPath.new(dir)]
      assert_send_type  "(Integer, Array[String], noop: bool, verbose: bool) -> void",
                        FileUtils, :chmod, 0755, [dir], noop: false, verbose: false
    end
  end

  def test_chmod_R
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        FileUtils, :chmod_R, 0755, dir
      assert_send_type  "(Integer, ToStr) -> void",
                        FileUtils, :chmod_R, 0755, ToStr.new(dir)
      assert_send_type  "(Integer, ToPath) -> void",
                        FileUtils, :chmod_R, 0755, ToPath.new(dir)
      assert_send_type  "(String, Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :chmod_R, "u=wrx", [dir, ToStr.new(dir), ToPath.new(dir)]
      assert_send_type  "(Integer, Array[String], noop: bool, verbose: bool, force: nil) -> void",
                        FileUtils, :chmod_R, 0755, [dir], noop: true, verbose: false, force: nil
    end
  end

  def test_chown
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        FileUtils, :chown, nil, nil, dir
      assert_send_type  "(nil, nil, ToStr) -> void",
                        FileUtils, :chown, nil, nil, ToStr.new(dir)
      assert_send_type  "(nil, nil, ToPath) -> void",
                        FileUtils, :chown, nil, nil, ToPath.new(dir)
      assert_send_type  "(nil, nil, Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :chown, nil, nil, [dir, ToStr.new(dir), ToPath.new(dir)]
      assert_send_type  "(String, String, Array[String], noop: bool, verbose: nil) -> void",
                        FileUtils, :chown, "user", "group", [dir], noop: true, verbose: nil
    end
  end

  def test_chown_R
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        FileUtils, :chown_R, nil, nil, dir
      assert_send_type  "(nil, nil, ToStr) -> void",
                        FileUtils, :chown_R, nil, nil, ToStr.new(dir)
      assert_send_type  "(nil, nil, ToPath) -> void",
                        FileUtils, :chown_R, nil, nil, ToPath.new(dir)
      assert_send_type  "(nil, nil, Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :chown_R, nil, nil, [dir, ToStr.new(dir), ToPath.new(dir)]
      assert_send_type  "(String, String, Array[String], noop: bool, verbose: nil, force: bool) -> void",
                        FileUtils, :chown_R, "user", "group", [dir], noop: true, verbose: nil, force: false
    end
  end

  def test_collect_method
    assert_send_type  "(Symbol) -> Array[String]",
                      FileUtils, :collect_method, :preserve
  end

  def test_commands
    assert_send_type  "() -> Array[String]",
                      FileUtils, :commands
  end

  def test_compare_file
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        FileUtils, :compare_file, "foo", "foo"
      assert_send_type  "(ToStr, ToStr) -> bool",
                        FileUtils, :compare_file, ToStr.new("foo"), ToStr.new("foo")
      assert_send_type  "(ToPath, ToPath) -> bool",
                        FileUtils, :compare_file, ToPath.new("foo"), ToPath.new("foo")
    end
  end

  def test_cmp
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        FileUtils, :cmp, "foo", "foo"
    end
  end

  def test_identical?
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        FileUtils, :identical?, "foo", "foo"
    end
  end

  def test_compare_stream
    in_tmpdir do
      File.write "foo", ""
      File.open("foo") do |io|
        assert_send_type  "(IO, IO) -> bool",
                          FileUtils, :compare_stream, io, io
      end
    end
  end

  def test_copy_entry
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :copy_entry, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :copy_entry, ToStr.new("src"), ToStr.new("dest")
      assert_send_type  "(ToPath, ToPath, bool, nil, bool) -> void",
                        FileUtils, :copy_entry, ToPath.new("src"), ToPath.new("dest"), true, nil, false
    end
  end

  def test_copy_file
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :copy_file, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :copy_file, ToStr.new("src"), ToStr.new("dest")
      assert_send_type  "(ToPath, ToPath, bool, nil) -> void",
                        FileUtils, :copy_file, ToPath.new("src"), ToPath.new("dest"), false, nil
    end
  end

  def test_copy_stream
    in_tmpdir do
      File.write "src", ""
      File.open("src") do |src|
        File.open("dest", "w") do |dest|
          assert_send_type  "(IO, IO) -> void",
                            FileUtils, :copy_stream, src, dest
        end
      end
    end
  end

  def test_cp
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :cp, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :cp, ToStr.new("src"), ToStr.new("dest")
      assert_send_type  "(Array[String | ToStr | ToPath], String) -> void",
                        FileUtils, :cp, ["src", ToStr.new("src"), ToPath.new("src")], "dest_dir"
      assert_send_type  "(ToPath, ToPath, preserve: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :cp, ToPath.new("src"), ToPath.new("dest"), preserve: true, noop: nil, verbose: false
    end
  end

  def test_copy
    in_tmpdir do
      assert_send_type  "(String, String, preserve: bool, noop: bool, verbose: nil) -> void",
                        FileUtils, :copy, "src", "dest", preserve: true, noop: true, verbose: nil
    end
  end

  def test_cp_lr
    in_tmpdir do
      Dir.mkdir "src"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :cp_lr, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :cp_lr, ToStr.new("src"), ToStr.new("dest")
      assert_send_type  "(Array[String | ToStr | ToPath], String) -> void",
                        FileUtils, :cp_lr, ["src", ToStr.new("src"), ToPath.new("src")], "dest"
      assert_send_type  "(ToPath, ToPath, noop: bool, verbose: false, dereference_root: nil, remove_destination: nil) -> void",
                        FileUtils, :cp_lr, ToPath.new("src"), ToPath.new("dest"), noop: true, verbose: false, dereference_root: nil, remove_destination: nil
    end
  end

  def test_cp_r
    in_tmpdir do
      Dir.mkdir "src"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :cp_r, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :cp_r, ToStr.new("src"), ToStr.new("dest")
      assert_send_type  "(Array[String | ToStr | ToPath], String) -> void",
                        FileUtils, :cp_r, ["src", ToStr.new("src"), ToPath.new("src")], "dest"
      assert_send_type  "(ToPath, ToPath, preserve: nil, noop: bool, verbose: bool, dereference_root: bool, remove_destination: nil) -> void",
                        FileUtils, :cp_r, ToPath.new("src"), ToPath.new("dest"), preserve: nil, noop: false, verbose: false, dereference_root: false, remove_destination: nil
    end
  end

  def test_have_option?
    assert_send_type  "(Symbol, Symbol) -> bool",
                      FileUtils, :have_option?, :cp, :noop
  end

  def test_install
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :install, "src", "dest"
      assert_send_type  "(ToStr, ToStr, mode: nil) -> void",
                        FileUtils, :install, ToStr.new("src"), ToStr.new("dest"), mode: nil
      assert_send_type  "(ToPath, ToPath, mode: Integer) -> void",
                        FileUtils, :install, ToPath.new("src"), ToPath.new("dest"), mode: 0755
      assert_send_type  "(String, String, mode: String, owner: String, group: nil, preserve: bool, noop: bool, verbose: nil) -> void",
                        FileUtils, :install, "src", "dest", mode: "u=wrx", owner: "user", group: nil, preserve: false, noop: true, verbose: nil
    end
  end

  def test_link_entry
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :link_entry, "src", "dest"
      assert_send_type  "(ToStr, ToStr) -> void",
                        FileUtils, :link_entry, ToStr.new("src"), ToStr.new("dest2")
      assert_send_type  "(ToPath, ToPath, bool, bool) -> void",
                        FileUtils, :link_entry, ToPath.new("src"), ToPath.new("dest"), false, true
    end
  end

  def test_ln
    in_tmpdir do |dir|
      File.write "src", ""
      Dir.mkdir "dest"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln, "src", "dest"
      assert_send_type  "(ToStr, ToStr, noop: bool) -> void",
                        FileUtils, :ln, ToStr.new("src"), ToStr.new("dest"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], String, noop: bool) -> void",
                        FileUtils, :ln, ["src", ToStr.new("src"), ToPath.new("src")], "dest", noop: true
      assert_send_type  "(ToPath, ToPath, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :ln, ToPath.new("src"), ToPath.new("dest"), force: true, noop: nil, verbose: false
    end
  end

  def test_link
    in_tmpdir do
      assert_send_type  "(String, String, force: nil, noop: bool, verbose: bool) -> void",
                        FileUtils, :link, "src", "dest", force: nil, noop: true, verbose: false
    end
  end

  def test_ln_s
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln_s, "src", "dest"
      assert_send_type  "(ToStr, ToStr, noop: bool) -> void",
                        FileUtils, :ln_s, ToStr.new("src"), ToStr.new("dest"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], String, noop: bool) -> void",
                        FileUtils, :ln_s, ["src", ToStr.new("src"), ToPath.new("src")], "dest_dir", noop: true
      assert_send_type  "(ToPath, ToPath, force: nil, noop: bool, verbose: bool, target_directory: bool, relative: bool) -> void",
                        FileUtils, :ln_s, ToPath.new("src"), ToPath.new("dest"), force: nil, noop: true, verbose: false, relative: false, target_directory: false
    end
  end

  def test_symlink
    in_tmpdir do
      assert_send_type  "(String, String, force: nil, noop: bool, verbose: bool) -> void",
                        FileUtils, :symlink, "src", "dest", force: nil, noop: true, verbose: false
    end
  end

  def test_ln_sf
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln_sf, "src", "dest"
      assert_send_type  "(ToStr, ToStr, noop: bool) -> void",
                        FileUtils, :ln_sf, ToStr.new("src"), ToStr.new("dest"), noop: true
      assert_send_type  "(ToPath, ToPath, noop: bool) -> void",
                        FileUtils, :ln_sf, ToPath.new("src"), ToPath.new("dest"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], String, noop: bool, verbose: bool) -> void",
                        FileUtils, :ln_sf, ["src", ToStr.new("src"), ToStr.new("src")], "dest_dir", noop: true, verbose: false
    end
  end

  def test_ln_sr
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln_sr, "src", "dest"
      assert_send_type  "(ToStr, ToStr, noop: bool) -> void",
                        FileUtils, :ln_sr, ToStr.new("src"), ToStr.new("dest"), noop: true
      assert_send_type  "(ToPath, ToPath, noop: bool) -> void",
                        FileUtils, :ln_sr, ToPath.new("src"), ToPath.new("dest"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], String, noop: bool, verbose: bool, target_directory: false) -> void",
                        FileUtils, :ln_sr, ["src", ToStr.new("src"), ToStr.new("src")], "dest_dir", noop: true, verbose: false, target_directory: false
    end
  end

  def test_mkdir
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :mkdir, "foo"
      assert_send_type  "(ToStr) -> void",
                        FileUtils, :mkdir, ToStr.new("bar")
      assert_send_type  "(Array[String | ToStr | ToPath], mode: nil) -> void",
                        FileUtils, :mkdir, ["bar1", ToStr.new("bar2"), ToPath.new("bar3")], mode: nil
      assert_send_type  "(ToPath, mode: Integer, noop: bool, verbose: nil) -> void",
                        FileUtils, :mkdir, ToPath.new("foo"), mode: 0755, noop: true, verbose: nil
    end
  end

  def test_mkdir_p
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :mkdir_p, "foo"
      assert_send_type  "(ToStr) -> void",
                        FileUtils, :mkdir_p, ToStr.new("foo")
      assert_send_type  "(Array[String | ToStr | ToPath], mode: nil) -> void",
                        FileUtils, :mkdir_p, ["foo", ToStr.new("foo"), ToPath.new("foo")], mode: nil
      assert_send_type  "(ToPath, mode: Integer, noop: bool, verbose: bool) -> void",
                        FileUtils, :mkdir_p, ToPath.new("foo"), mode: 0755, noop: false, verbose: false
    end
  end

  def test_makedirs
    in_tmpdir do
      assert_send_type  "(String, mode: Integer, noop: bool, verbose: bool) -> void",
                        FileUtils, :makedirs, "foo", mode: 0755, noop: false, verbose: false
    end
  end

  def test_mkpath
    in_tmpdir do
      assert_send_type  "(String, mode: Integer, noop: bool, verbose: bool) -> void",
                        FileUtils, :mkpath, "foo", mode: 0755, noop: false, verbose: false
    end
  end

  def test_mv
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :mv, "src", "dest"
      assert_send_type  "(ToStr, ToStr, noop: bool) -> void",
                        FileUtils, :mv, ToStr.new("src"), ToStr.new("dest"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], String, noop: bool) -> void",
                        FileUtils, :mv, ["src", ToStr.new("src"), ToPath.new("src")], "dest_dir", noop: true
      assert_send_type  "(ToPath, ToPath, force: bool, noop: bool, verbose: nil, secure: bool) -> void",
                        FileUtils, :mv, ToPath.new("src"), ToPath.new("dest"), force: true, noop: true, verbose: nil, secure: true
    end
  end

  def test_move
    in_tmpdir do
      assert_send_type  "(String, String, force: bool, noop: bool, verbose: nil, secure: bool) -> void",
                        FileUtils, :move, "src", "dest", force: true, noop: true, verbose: nil, secure: true
    end
  end

  def test_options
    assert_send_type  "() -> Array[String]",
                      FileUtils, :options
  end

  def test_options_of
    assert_send_type  "(Symbol) -> Array[String]",
                      FileUtils, :options_of, :rm
  end

  def test_pwd
    assert_send_type  "() -> String",
                      FileUtils, :pwd
  end

  def test_getwd
    assert_send_type  "() -> String",
                      FileUtils, :getwd
  end

  def test_remove_dir
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :remove_dir, "foo"
      assert_send_type  "(ToStr, bool) -> void",
                        FileUtils, :remove_dir, ToStr.new("foo"), true
      assert_send_type  "(ToPath, bool) -> void",
                        FileUtils, :remove_dir, ToPath.new("foo"), true
    end
  end

  def test_remove_entry
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :remove_entry, "foo"
      assert_send_type  "(ToStr, bool) -> void",
                        FileUtils, :remove_entry, ToStr.new("foo"), true
      assert_send_type  "(ToPath, bool) -> void",
                        FileUtils, :remove_entry, ToPath.new("foo"), true
    end
  end

  def test_remove_entry_secure
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :remove_entry_secure, "foo"
      assert_send_type  "(ToStr, bool) -> void",
                        FileUtils, :remove_entry_secure, ToStr.new("foo"), true
      assert_send_type  "(ToPath, bool) -> void",
                        FileUtils, :remove_entry_secure, ToPath.new("foo"), true
    end
  end

  def test_remove_file
    in_tmpdir do
      File.write "foo", ""

       assert_send_type  "(String) -> void",
                        FileUtils, :remove_file, "foo"
       assert_send_type  "(ToStr, bool) -> void",
                        FileUtils, :remove_file, ToStr.new("foo"), true
       assert_send_type  "(ToPath, bool) -> void",
                        FileUtils, :remove_file, ToPath.new("foo"), true
    end
  end

  def test_rm
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String) -> void",
                        FileUtils, :rm, "foo"
      assert_send_type  "(ToStr, noop: bool) -> void",
                        FileUtils, :rm, ToStr.new("foo"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], noop: bool) -> void",
                        FileUtils, :rm, ["foo", ToStr.new("foo"), ToPath.new("foo")], noop: true
      assert_send_type  "(ToPath, force: nil, noop: bool, verbose: bool) -> void",
                        FileUtils, :rm, ToPath.new("foo"), force: nil, noop: true, verbose: false
    end
  end

  def test_remove
    in_tmpdir do
      assert_send_type  "(String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :remove, "foo", force: true, noop: nil, verbose: false
    end
  end

  def test_rm_f
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :rm_f, "foo"
      assert_send_type  "(ToStr) -> void",
                        FileUtils, :rm_f, ToStr.new("foo")
      assert_send_type  "(Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :rm_f, ["foo", ToStr.new("foo"), ToPath.new("foo")]
      assert_send_type  "(ToPath, noop: bool, verbose: nil) -> void",
                        FileUtils, :rm_f, ToPath.new("foo"), noop: false, verbose: nil
    end
  end

  def test_safe_unlink
    in_tmpdir do
      assert_send_type  "(String, noop: bool, verbose: nil) -> void",
                        FileUtils, :safe_unlink, "foo", noop: false, verbose: nil
    end
  end

  def test_rm_r
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :rm_r, "foo"
      assert_send_type  "(ToStr, noop: bool) -> void",
                        FileUtils, :rm_r, ToStr.new("foo"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], noop: bool) -> void",
                        FileUtils, :rm_r, ["foo", ToStr.new("foo"), ToPath.new("foo")], noop: true
      assert_send_type  "(ToPath, force: bool, noop: bool, verbose: nil, secure: bool) -> void",
                        FileUtils, :rm_r, ToPath.new("foo"), force: true, noop: true, verbose: nil, secure: true
    end
  end

  def test_rm_rf
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :rm_rf, "foo"
      assert_send_type  "(ToStr) -> void",
                        FileUtils, :rm_rf, ToStr.new("foo")
      assert_send_type  "(Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :rm_rf, ["foo", ToStr.new("foo"), ToPath.new("foo")]
      assert_send_type  "(ToPath, noop: nil, verbose: nil, secure: bool) -> void",
                        FileUtils, :rm_rf, ToPath.new("foo"), noop: nil, verbose: nil, secure: true
    end
  end

  def test_rmtree
    in_tmpdir do
      assert_send_type  "(String, noop: nil, verbose: nil, secure: bool) -> void",
                        FileUtils, :rmtree, "foo", noop: nil, verbose: nil, secure: true
    end
  end

  def test_rmdir
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :rmdir, "foo"
      assert_send_type  "(ToStr, noop: bool) -> void",
                        FileUtils, :rmdir, ToStr.new("foo"), noop: true
      assert_send_type  "(Array[String | ToStr | ToPath], noop: bool) -> void",
                        FileUtils, :rmdir, ["foo", ToStr.new("foo"), ToPath.new("foo")], noop: true
      assert_send_type  "(ToPath, parents: bool, noop: bool, verbose: nil) -> void",
                        FileUtils, :rmdir, ToPath.new("foo"), parents: false, noop: true, verbose: nil
    end
  end

  def test_touch
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :touch, "foo"
      assert_send_type  "(Array[String | ToStr | ToPath]) -> void",
                        FileUtils, :touch, ["foo", ToStr.new("foo"), ToPath.new("foo")]
      assert_send_type  "(ToStr, mtime: Time) -> void",
                        FileUtils, :touch, ToStr.new("foo"), mtime: Time.now
      assert_send_type  "(ToPath, noop: bool, verbose: bool, mtime: Integer, nocreate: nil) -> void",
                        FileUtils, :touch, ToPath.new("foo"), noop: true, verbose: false, mtime: 1000, nocreate: nil
    end
  end

  def test_uptodate?
    assert_send_type  "(String, String) -> bool",
                      FileUtils, :uptodate?, "foo", "bar"
    assert_send_type  "(String, Array[String | ToStr | ToPath]) -> bool",
                      FileUtils, :uptodate?, "foo", ["bar", ToStr.new("bar"), ToPath.new("bar")]
    assert_send_type  "(ToStr, ToStr) -> bool",
                      FileUtils, :uptodate?, ToStr.new("foo"), ToStr.new("bar")
    assert_send_type  "(ToPath, ToPath) -> bool",
                      FileUtils, :uptodate?, ToPath.new("foo"), ToPath.new("bar")
  end
end

class FileUtilsInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  include TmpdirHelper

  library "fileutils"
  testing "::FileUtils"

  class Foo
    include FileUtils
  end

  def test_cd
    dir = Dir.pwd

    begin
      assert_send_type  "(String) -> void",
                        Foo.new, :cd, __dir__
    ensure
      Dir.chdir(dir)
    end
  end

  def test_chdir
    dir = Dir.pwd

    begin
      assert_send_type  "(String) -> void",
                        Foo.new, :chdir, __dir__
    ensure
      Dir.chdir(dir)
    end
  end

  def test_chmod
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        Foo.new, :chmod, 0755, dir
    end
  end

  def test_chmod_R
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        Foo.new, :chmod_R, 0755, dir
    end
  end

  def test_chown
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        Foo.new, :chown, nil, nil, dir
    end
  end

  def test_chown_R
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        Foo.new, :chown_R, nil, nil, dir
    end
  end

  def test_compare_file
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        Foo.new, :compare_file, "foo", "foo"
    end
  end

  def test_cmp
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        Foo.new, :cmp, "foo", "foo"
    end
  end

  def test_identical?
    in_tmpdir do
      File.write "foo", ""

      assert_send_type  "(String, String) -> bool",
                        Foo.new, :identical?, "foo", "foo"
    end
  end

  def test_compare_stream
    in_tmpdir do
      File.write "foo", ""
      File.open("foo") do |io|
        assert_send_type  "(IO, IO) -> bool",
                          Foo.new, :compare_stream, io, io
      end
    end
  end

  def test_copy_entry
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        Foo.new, :copy_entry, "src", "dest"
    end
  end

  def test_copy_file
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        Foo.new, :copy_file, "src", "dest"
    end
  end

  def test_copy_stream
    in_tmpdir do
      File.write "src", ""
      File.open("src") do |src|
        File.open("dest", "w") do |dest|
          assert_send_type  "(IO, IO) -> void",
                            Foo.new, :copy_stream, src, dest
        end
      end
    end
  end

  def test_cp
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :cp, "src", "dest", noop: true
    end
  end

  def test_copy
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :copy, "src", "dest", noop: true
    end
  end

  def test_cp_lr
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :cp_lr, "src", "dest", noop: true
    end
  end

  def test_cp_r
    in_tmpdir do
      Dir.mkdir "src"

      assert_send_type  "(String, String) -> void",
                        Foo.new, :cp_r, "src", "dest"
    end
  end

  def test_install
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :install, "src", "dest", noop: true
    end
  end

  def test_link_entry
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        Foo.new, :link_entry, "src", "dest"
    end
  end

  def test_ln
    in_tmpdir do |dir|
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :ln, "src", "dest", noop: true
    end
  end

  def test_link
    in_tmpdir do |dir|
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :link, "src", "dest", noop: true
    end
  end

  def test_ln_s
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :ln_s, "src", "dest", noop: true
    end
  end

  def test_symlink
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :symlink, "src", "dest", noop: true
    end
  end

  def test_ln_sf
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :ln_sf, "src", "dest", noop: true
    end
  end

  def test_mkdir
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :mkdir, "foo", noop: true
    end
  end

  def test_mkdir_p
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :mkdir_p, "foo", noop: true
    end
  end

  def test_makedirs
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :makedirs, "foo", noop: true
    end
  end

  def test_mkpath
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :mkpath, "foo", noop: true
    end
  end

  def test_mv
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :mv, "src", "dest", noop: true
    end
  end

  def test_move
    in_tmpdir do
      assert_send_type  "(String, String, noop: bool) -> void",
                        Foo.new, :move, "src", "dest", noop: true
    end
  end

  def test_pwd
    assert_send_type  "() -> String",
                      Foo.new, :pwd
  end

  def test_getwd
    assert_send_type  "() -> String",
                      Foo.new, :getwd
  end

  def test_remove_dir
    in_tmpdir do
      assert_send_type  "(String, bool) -> void",
                        Foo.new, :remove_dir, "foo", true
    end
  end

  def test_remove_entry
    in_tmpdir do
      assert_send_type  "(String, bool) -> void",
                        Foo.new, :remove_entry, "foo", true
    end
  end

  def test_remove_entry_secure
    in_tmpdir do
      assert_send_type  "(String, bool) -> void",
                        Foo.new, :remove_entry_secure, "foo", true
    end
  end

  def test_remove_file
    in_tmpdir do
       assert_send_type  "(String, bool) -> void",
                        Foo.new, :remove_file, "foo", true
    end
  end

  def test_rm
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :rm, "foo", noop: true
    end
  end

  def test_remove
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :remove, "foo", noop: true
    end
  end

  def test_rm_f
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        Foo.new, :rm_f, "foo"
    end
  end

  def test_safe_unlink
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        Foo.new, :safe_unlink, "foo"
    end
  end

  def test_rm_r
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :rm_r, "foo", noop: true
    end
  end

  def test_rm_rf
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        Foo.new, :rm_rf, "foo"
    end
  end

  def test_rmtree
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        Foo.new, :rmtree, "foo"
    end
  end

  def test_rmdir
    in_tmpdir do
      assert_send_type  "(String, noop: bool) -> void",
                        Foo.new, :rmdir, "foo", noop: true
    end
  end

  def test_touch
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        Foo.new, :touch, "foo"
    end
  end

  def test_uptodate?
    assert_send_type  "(String, String) -> bool",
                      Foo.new, :uptodate?, "foo", "bar"
  end
end
