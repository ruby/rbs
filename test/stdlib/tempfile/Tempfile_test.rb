require_relative "../test_helper"
require 'tempfile'

class TempfileSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "tempfile"
  testing "singleton(::Tempfile)"


  def test_open
    assert_send_type "(String) -> ::Tempfile",
                     Tempfile, :open, 'README.md'

    assert_send_type "() { (::Tempfile) -> ::Integer } -> ::Integer",
                     Tempfile, :open do 123 end

  end

  def test_new
    assert_send_type "(?::String basename, ?::String? tmpdir, ?mode: ::Integer, **untyped) -> ::Tempfile",
                     Tempfile, :new, 'README.md', '/tmp', mode: 0

    assert_send_type "([::String, ::String]) -> ::Tempfile",
                     Tempfile, :new, ['foo', '.txt']
  end

  def test_create
    assert_send_type "(::String basename, ::String? tmpdir, mode: ::Integer) -> ::File",
                     Tempfile, :create, 'README.md', '/tmp', mode: 0

    assert_send_type "([::String, ::String]) -> ::File",
                     Tempfile, :create, ['foo', '.txt']

    assert_send_type "() { (::File) -> Integer } -> Integer",
                     Tempfile, :create do |file| 123 end
  end

  def test_initialize
    assert_send_type "(?::String basename, ?::String? tmpdir, ?mode: ::Integer, **untyped) -> void",
                     Tempfile, :new, 'README.md', '/tmp', mode: 0
  end
end

class TempfileTest < Test::Unit::TestCase
  include TypeAssertions

  library "tempfile"
  testing "::Tempfile"


  def test_open
    assert_send_type "() -> ::File",
                     Tempfile.new('README.md'), :open
  end

  def test_inspect
    assert_send_type "() -> ::String",
                     Tempfile.new('README.md'), :inspect
  end

  def test_close
    assert_send_type "() -> void",
                     Tempfile.new('README.md'), :close

    assert_send_type "(true) -> void",
                     Tempfile.new('README.md'), :close, true

    assert_send_type "(String) -> void",
                     Tempfile.new('README.md'), :close, "true"

    assert_send_type "(false) -> void",
                     Tempfile.new('README.md'), :close, false
  end

  def test_path
    assert_send_type "() -> ::String?",
                     Tempfile.new('README.md'), :path

    assert_send_type "() -> ::String?",
                     Tempfile.new('README.md').tap(&:unlink), :path
  end

  def test_size
    assert_send_type "() -> ::Integer",
                     Tempfile.new('README.md'), :size
  end

  def test_close!
    assert_send_type "() -> void",
                     Tempfile.new, :close!
  end

  def test_unlink
    assert_send_type "() -> void",
                     Tempfile.new, :unlink

    assert_send_type "() -> void",
                     Tempfile.new('README.md').tap(&:unlink), :unlink
  end

  def test_delete
    assert_send_type "() -> bool?",
                     Tempfile.new, :delete

    assert_send_type  "() -> bool?",
                     Tempfile.new('README.md').tap(&:unlink), :delete
  end

  def test_length
    assert_send_type "() -> ::Integer",
                     Tempfile.new('README.md'), :length
  end
end
