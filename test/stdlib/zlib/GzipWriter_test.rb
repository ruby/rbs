require_relative "../test_helper"
require "zlib"
require "tempfile"

class ZlibGzipWriterSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "zlib"
  testing "singleton(::Zlib::GzipWriter)"

  def test_open
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.gz")
      result = assert_send_type "(String) -> Zlib::GzipWriter", Zlib::GzipWriter, :open, path
      result.close

      result = assert_send_type "(Pathname) -> Zlib::GzipWriter", Zlib::GzipWriter, :open, Pathname(path)
      result.close
      result = assert_send_type "(String, nil, nil) -> Zlib::GzipWriter", Zlib::GzipWriter, :open, path, nil, nil
      result.close

      assert_send_type "(String) { (Zlib::GzipWriter) -> Integer } -> Integer",
                       Zlib::GzipWriter, :open, path do |gz| gz.write("hello") end
      assert_send_type "(Pathname) { (Zlib::GzipWriter) -> Integer } -> Integer",
                       Zlib::GzipWriter, :open, Pathname(path) do |gz| gz.write("hello") end
      assert_send_type "(String, Integer, Integer) { (Zlib::GzipWriter) -> nil } -> nil",
                       Zlib::GzipWriter, :open, path, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY do |gz| end
      assert_send_type "(String, nil, nil) { (Zlib::GzipWriter) -> nil } -> nil",
                       Zlib::GzipWriter, :open, path, nil, nil do |gz| end
      assert_send_type "(String, Integer, Integer, encoding: Encoding) { (Zlib::GzipWriter) -> nil } -> nil",
                       Zlib::GzipWriter, :open, path, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY, encoding: Encoding::UTF_8 do |gz| end
    end
  end

  def test_wrap
    result = assert_send_type "(StringIO) -> Zlib::GzipWriter",
                              Zlib::GzipWriter, :wrap, StringIO.new
    result.close
    result = assert_send_type "(StringIO, Integer, nil, external_encoding: String) -> Zlib::GzipWriter",
                              Zlib::GzipWriter, :wrap, StringIO.new, Zlib::BEST_SPEED, nil, external_encoding: "UTF-8"
    result.close

    assert_send_type "(StringIO) { (Zlib::GzipWriter) -> Integer } -> Integer",
                     Zlib::GzipWriter, :wrap, StringIO.new do |gz| gz.write("hello") end
    assert_send_type "(StringIO, Integer, Integer) { (Zlib::GzipWriter) -> nil } -> nil",
                     Zlib::GzipWriter, :wrap, StringIO.new, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY do |gz| end
  end

  def test_new
    assert_send_type "(StringIO) -> Zlib::GzipWriter",
                     Zlib::GzipWriter, :new, StringIO.new
    assert_send_type "(StringIO, Integer) -> Zlib::GzipWriter",
                     Zlib::GzipWriter, :new, StringIO.new, Zlib::DEFAULT_COMPRESSION
    assert_send_type "(StringIO, Integer, Integer) -> Zlib::GzipWriter",
                     Zlib::GzipWriter, :new, StringIO.new, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY
    assert_send_type "(StringIO, Integer, Integer, encoding: Encoding) -> Zlib::GzipWriter",
                     Zlib::GzipWriter, :new, StringIO.new, Zlib::DEFAULT_COMPRESSION, Zlib::DEFAULT_STRATEGY, encoding: Encoding::UTF_8
  end
end

class ZlibGzipWriterInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "zlib"
  testing "::Zlib::GzipWriter"

  def test_lshift
    assert_send_type "(String) -> Zlib::GzipWriter",
                     Zlib::GzipWriter.new(StringIO.new), :<<, "hello"
  end

  def test_comment=
    assert_send_type "(String) -> void",
                     Zlib::GzipWriter.new(StringIO.new), :comment=, "hello"
  end

  def test_flush
    assert_send_type "() -> Zlib::GzipWriter",
                     Zlib::GzipWriter.new(StringIO.new), :flush
    assert_send_type "(Integer) -> Zlib::GzipWriter",
                     Zlib::GzipWriter.new(StringIO.new), :flush, Zlib::SYNC_FLUSH
  end

  def test_mtime=
    assert_send_type "(Time) -> void",
                     Zlib::GzipWriter.new(StringIO.new), :mtime=, Time.now
    assert_send_type "(Integer) -> void",
                     Zlib::GzipWriter.new(StringIO.new), :mtime=, 0
  end

  def test_orig_name=
    assert_send_type "(String) -> void",
                     Zlib::GzipWriter.new(StringIO.new), :orig_name=, "hello"
  end

  def test_pos
    assert_send_type "() -> Integer",
                     Zlib::GzipWriter.new(StringIO.new), :pos
  end

  def test_print
    assert_send_type "(String) -> nil",
                     Zlib::GzipWriter.new(StringIO.new), :print, "hello"
  end

  def test_printf
    assert_send_type "(String) -> nil",
                     Zlib::GzipWriter.new(StringIO.new), :printf, "hello"
    assert_send_type "(String, Integer) -> nil",
                     Zlib::GzipWriter.new(StringIO.new), :printf, "%d", 1
  end

  def test_putc
    assert_send_type "(String) -> String",
                     Zlib::GzipWriter.new(StringIO.new), :putc, "h"
    assert_send_type "(Integer) -> Integer",
                     Zlib::GzipWriter.new(StringIO.new), :putc, "h".ord
  end

  def test_puts
    assert_send_type "() -> nil",
                     Zlib::GzipWriter.new(StringIO.new), :puts
    assert_send_type "(String) -> nil",
                     Zlib::GzipWriter.new(StringIO.new), :puts, "hello"
  end

  def test_tell
    assert_send_type "() -> Integer",
                     Zlib::GzipWriter.new(StringIO.new), :tell
  end

  def test_write
    assert_send_type "(String) -> Integer",
                     Zlib::GzipWriter.new(StringIO.new), :write, "hello"
  end
end
