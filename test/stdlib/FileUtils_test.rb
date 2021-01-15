require_relative "test_helper"
require "fileutils"

class FileUtilsSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "fileutils"
  testing "singleton(::FileUtils)"

  def test_cd
    assert_send_type  "(String) -> void",
                      FileUtils, :cd, __dir__
    assert_send_type  "(String, verbose: bool) -> void",
                      FileUtils, :cd, __dir__, verbose: false
    assert_send_type  "(String) { (String) -> Integer } -> Integer",
                      FileUtils, :cd, __dir__ do |dir| 1 end
    assert_send_type  "(String, verbose: nil) { (String) -> Integer } -> Integer",
                      FileUtils, :cd, __dir__, verbose: nil do |dir| 1 end
  end

  def test_chdir
    assert_send_type  "(String) -> void",
                      FileUtils, :chdir, __dir__
    assert_send_type  "(String) { (String) -> Integer } -> Integer",
                      FileUtils, :chdir, __dir__ do |dir| 1 end
  end

  def test_chmod
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        FileUtils, :chmod, 0755, dir
      assert_send_type  "(String, Array[String]) -> void",
                        FileUtils, :chmod, "u=wrx", [dir]
      assert_send_type  "(Integer, Array[String], noop: bool, verbose: bool) -> void",
                        FileUtils, :chmod, 0755, [dir], noop: false, verbose: false
    end
  end

  def test_chmod_R
    in_tmpdir do |dir|
      assert_send_type  "(Integer, String) -> void",
                        FileUtils, :chmod_R, 0755, dir
      assert_send_type  "(String, Array[String]) -> void",
                        FileUtils, :chmod_R, "u=wrx", [dir]
      assert_send_type  "(Integer, Array[String], noop: bool, verbose: bool, force: nil) -> void",
                        FileUtils, :chmod_R, 0755, [dir], noop: true, verbose: false, force: nil
    end
  end

  def test_chown
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        FileUtils, :chown, nil, nil, dir
      assert_send_type  "(nil, nil, Array[String]) -> void",
                        FileUtils, :chown, nil, nil, [dir]
      assert_send_type  "(String, String, Array[String], noop: bool, verbose: nil) -> void",
                        FileUtils, :chown, "user", "group", [dir], noop: true, verbose: nil
    end
  end

  def test_chown_R
    in_tmpdir do |dir|
      assert_send_type  "(nil, nil, String) -> void",
                        FileUtils, :chown_R, nil, nil, dir
      assert_send_type  "(nil, nil, Array[String]) -> void",
                        FileUtils, :chown_R, nil, nil, [dir]
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
      assert_send_type  "(String, String, bool, nil, bool) -> void",
                        FileUtils, :copy_entry, "src", "dest", true, nil, false
    end
  end

  def test_copy_file
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :copy_file, "src", "dest"
      assert_send_type  "(String, String, bool, nil) -> void",
                        FileUtils, :copy_file, "src", "dest", false, nil
    end
  end

  def test_copy_stream
    in_tmpdir do
      File.write "src", ""
      File.open("src") do |src|
        File.open("dest", "a") do |dest|
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
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :cp, ["src"], "dest_dir"
      assert_send_type  "(String, String, preserve: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :cp, "src", "dest", preserve: true, noop: nil, verbose: false
    end
  end

  def test_copy
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String, preserve: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :copy, "src", "dest", preserve: true, noop: nil, verbose: false
    end
  end

  def test_cp_lr
    in_tmpdir do
      Dir.mkdir "src"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :cp_lr, "src", "dest"
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :cp_lr, ["src"], "dest"
      assert_send_type  "(String, String, noop: bool, verbose: false, dereference_root: nil, remove_destination: nil) -> void",
                        FileUtils, :cp_lr, "src", "dest", noop: true, verbose: false, dereference_root: nil, remove_destination: nil
    end
  end

  def test_cp_r
    in_tmpdir do
      Dir.mkdir "src"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :cp_r, "src", "dest"
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :cp_r, ["src"], "dest"
      assert_send_type  "(String, String, preserve: nil, noop: bool, verbose: bool, dereference_root: bool, remove_destination: nil) -> void",
                        FileUtils, :cp_r, "src", "dest", preserve: nil, noop: false, verbose: false, dereference_root: false, remove_destination: nil
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
      assert_send_type  "(String, String, mode: Integer) -> void",
                        FileUtils, :install, "src", "dest", mode: 0755
      assert_send_type  "(String, String, mode: String, owner: String, group: nil, preserve: bool, noop: bool, verbose: nil) -> void",
                        FileUtils, :install, "src", "dest", mode: "u=wrx", owner: "user", group: nil, preserve: false, noop: true, verbose: nil
    end
  end

  def test_link_entry
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String) -> void",
                        FileUtils, :link_entry, "src", "dest"
      assert_send_type  "(String, String, bool, bool) -> void",
                        FileUtils, :link_entry, "src", "dest", false, true
    end
  end

  def test_ln
    in_tmpdir do |dir|
      File.write "src", ""
      File.write "src2", ""
      Dir.mkdir "dest"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln, "src", "dest"
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :ln, ["src2"], "dest"
      assert_send_type  "(String, String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :ln, "src", "dest", force: true, noop: nil, verbose: false
    end
  end

  def test_link
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :link, "src", "dest", force: true, noop: nil, verbose: false
    end
  end

  def test_ln_s
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln_s, "src", "dest"
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :ln_s, ["src"], "dest_dir"
      assert_send_type  "(String, String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :ln_s, "src", "dest", force: true, noop: nil, verbose: false
    end
  end

  def test_symlink
    in_tmpdir do
      File.write "src", ""

      assert_send_type  "(String, String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :symlink, "src", "dest", force: true, noop: nil, verbose: false
    end
  end

  def test_ln_sf
    in_tmpdir do
      File.write "src", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :ln_sf, "src", "dest"
      assert_send_type  "(Array[String], String, noop: bool, verbose: bool) -> void",
                        FileUtils, :ln_sf, ["src"], "dest_dir", noop: true, verbose: false
    end
  end

  def test_mkdir
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :mkdir, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :mkdir, ["bar"]
      assert_send_type  "(String, mode: Integer, noop: bool, verbose: nil) -> void",
                        FileUtils, :mkdir, "foo", mode: 0755, noop: true, verbose: nil
    end
  end

  def test_mkdir_p
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :mkdir_p, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :mkdir_p, ["foo"]
      assert_send_type  "(String, mode: Integer, noop: bool, verbose: bool) -> void",
                        FileUtils, :mkdir_p, "foo", mode: 0755, noop: false, verbose: false
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
      File.write "src2", ""
      Dir.mkdir "dest_dir"

      assert_send_type  "(String, String) -> void",
                        FileUtils, :mv, "src", "dest"
      assert_send_type  "(Array[String], String) -> void",
                        FileUtils, :mv, ["src2"], "dest_dir"
      assert_send_type  "(String, String, force: bool, noop: bool, verbose: nil, secure: bool) -> void",
                        FileUtils, :mv, "src", "dest", force: true, noop: true, verbose: nil, secure: true
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
      assert_send_type  "(String, bool) -> void",
                        FileUtils, :remove_dir, "foo", true
    end
  end

  def test_remove_entry
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :remove_entry, "foo"
      assert_send_type  "(String, bool) -> void",
                        FileUtils, :remove_entry, "foo", true
    end
  end

  def test_remove_entry_secure
    in_tmpdir do
      Dir.mkdir "foo"

      assert_send_type  "(String) -> void",
                        FileUtils, :remove_entry_secure, "foo"
      assert_send_type  "(String, bool) -> void",
                        FileUtils, :remove_entry_secure, "foo", true
    end
  end

  def test_remove_file
    in_tmpdir do
      File.write "foo", ""

       assert_send_type  "(String) -> void",
                        FileUtils, :remove_file, "foo"
       assert_send_type  "(String, bool) -> void",
                        FileUtils, :remove_file, "foo", true
    end
  end

  def test_rm
    in_tmpdir do
      File.write "foo", ""
      File.write "bar", ""

      assert_send_type  "(String) -> void",
                        FileUtils, :rm, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :rm, ["bar"]
      assert_send_type  "(String, force: bool, noop: nil, verbose: bool) -> void",
                        FileUtils, :rm, "foo", force: true, noop: nil, verbose: false
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
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :rm_f, ["foo"]
      assert_send_type  "(String, noop: bool, verbose: nil) -> void",
                        FileUtils, :rm_f, "foo", noop: false, verbose: nil
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
      Dir.mkdir "bar"

      assert_send_type  "(String) -> void",
                        FileUtils, :rm_r, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :rm_r, ["bar"]
      assert_send_type  "(String, force: bool, noop: bool, verbose: nil, secure: bool) -> void",
                        FileUtils, :rm_r, "foo", force: true, noop: false, verbose: nil, secure: true
    end
  end

  def test_rm_rf
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :rm_rf, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :rm_rf, ["foo"]
      assert_send_type  "(String, noop: nil, verbose: nil, secure: bool) -> void",
                        FileUtils, :rm_rf, "foo", noop: nil, verbose: nil, secure: true
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
      Dir.mkdir "bar"

      assert_send_type  "(String) -> void",
                        FileUtils, :rmdir, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :rmdir, ["bar"]
      assert_send_type  "(String, parents: bool, noop: bool, verbose: nil) -> void",
                        FileUtils, :rmdir, "foo", parents: false, noop: true, verbose: nil
    end
  end

  def test_touch
    in_tmpdir do
      assert_send_type  "(String) -> void",
                        FileUtils, :touch, "foo"
      assert_send_type  "(Array[String]) -> void",
                        FileUtils, :touch, ["foo", "bar"]
      assert_send_type  "(String, mtime: Time) -> void",
                        FileUtils, :touch, "foo", mtime: Time.now
      assert_send_type  "(String, noop: bool, verbose: bool, mtime: Integer, nocreate: nil) -> void",
                        FileUtils, :touch, "foo", noop: true, verbose: false, mtime: 1000, nocreate: nil
    end
  end

  def test_uptodate?
    assert_send_type  "(String, Array[String]) -> bool",
                      FileUtils, :uptodate?, "foo", ["bar"]
  end

  private

  def in_tmpdir(&block)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir, &block)
    end
  end
end
