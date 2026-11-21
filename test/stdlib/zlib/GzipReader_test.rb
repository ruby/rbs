require_relative "../test_helper"
require "zlib"
require "tempfile"

class ZlibGzipReaderSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "zlib"
  testing "singleton(::Zlib::GzipReader)"

  def test_open
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.gz")
      Zlib::GzipWriter.open(path) { _1.puts "hello" }

      assert_send_type "(String filename) -> Zlib::GzipReader",
                       Zlib::GzipReader, :open, path
      assert_send_type "(_ToPath filename) -> Zlib::GzipReader",
                       Zlib::GzipReader, :open, Pathname(path)
      assert_send_type "(String filename, external_encoding: String) -> Zlib::GzipReader",
                       Zlib::GzipReader, :open, path, external_encoding: "UTF-8"
      assert_send_type "(String filename) { (Zlib::GzipReader) -> String } -> String",
                       Zlib::GzipReader, :open, path do |gz| gz.read end
      assert_send_type "(_ToPath filename) { (Zlib::GzipReader) -> String } -> String",
                       Zlib::GzipReader, :open, Pathname(path) do |gz| gz.read end
      assert_send_type "(String filename, encoding: Encoding) { (Zlib::GzipReader) -> String } -> String",
                       Zlib::GzipReader, :open, path, encoding: Encoding::UTF_8 do |gz| gz.read end
    end
  end

  def test_wrap
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.gz")
      Zlib::GzipWriter.open(path) { _1.puts "hello" }

      File.open(path, "rb") do |io|
        assert_send_type "(IO io) -> Zlib::GzipReader",
                         Zlib::GzipReader, :wrap, io

        io.rewind

        assert_send_type "(IO io) { (Zlib::GzipReader gz) -> String } -> String",
                         Zlib::GzipReader, :wrap, io do |gz| gz.read end
      end

      gzipped = File.binread(path)
      assert_send_type "(StringIO io, external_encoding: String) -> Zlib::GzipReader",
                       Zlib::GzipReader, :wrap, StringIO.new(gzipped), external_encoding: "UTF-8"
      assert_send_type "(StringIO io, encoding: Encoding) { (Zlib::GzipReader gz) -> String } -> String",
                       Zlib::GzipReader, :wrap, StringIO.new(gzipped), encoding: Encoding::UTF_8 do |gz| gz.read end
    end
  end
end

class ZlibGzipReaderInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "zlib"
  testing "::Zlib::GzipReader"

  def test_read
    assert_send_type "() -> String",
                     gzip_reader, :read
    assert_send_type "(nil, nil) -> String",
                     gzip_reader, :read, nil, nil
    assert_send_type "(nil, String) -> String",
                     gzip_reader, :read, nil, +""
    assert_send_type "(int length, nil) -> String",
                     gzip_reader, :read, 1, nil
    assert_send_type "(int length, String) -> String",
                     gzip_reader, :read, 1, +""

    reader = gzip_reader
    reader.read
    assert_send_type "() -> String",
                     reader, :read
    assert_send_type "(int length) -> nil",
                     reader, :read, 1
  end

  def test_readpartial
    assert_send_type "(int maxlen, nil) -> String",
                     gzip_reader, :readpartial, 1, nil
  end

  def test_gets
    assert_send_type "() -> String",
                     gzip_reader, :gets
    assert_send_type "(String sep) -> String",
                     gzip_reader, :gets, "l"
    assert_send_type "(ToStr sep) -> String",
                     gzip_reader, :gets, ToStr.new("l")
    assert_send_type "(nil sep) -> String",
                     gzip_reader, :gets, nil
    assert_send_type "(String sep, Integer limit) -> String",
                     gzip_reader, :gets, "l", 2
    assert_send_type "(nil sep, Integer limit) -> String",
                     gzip_reader, :gets, nil, 2
    assert_send_type "(String sep, nil limit) -> String",
                     gzip_reader, :gets, "l", nil
    assert_send_type "(Integer limit) -> String",
                     gzip_reader, :gets, 2
    assert_send_type "(ToInt limit) -> String",
                     gzip_reader, :gets, ToInt.new(2)

    reader = gzip_reader
    reader.read
    assert_send_type "() -> nil",
                     reader, :gets
  end

  def test_readline
    assert_send_type "() -> String",
                     gzip_reader, :readline
    assert_send_type "(nil sep) -> String",
                     gzip_reader, :readline, nil
    assert_send_type "(nil sep, Integer limit) -> String",
                     gzip_reader, :readline, nil, 2
    assert_send_type "(String sep, nil limit) -> String",
                     gzip_reader, :readline, "l", nil
    assert_send_type "(Integer limit) -> String",
                     gzip_reader, :readline, 2
  end

  def test_readlines
    assert_send_type "() -> Array[String]",
                     gzip_reader, :readlines
    assert_send_type "(nil sep) -> Array[String]",
                     gzip_reader, :readlines, nil
    assert_send_type "(nil sep, Integer limit) -> Array[String]",
                     gzip_reader, :readlines, nil, 2
    assert_send_type "(String sep, nil limit) -> Array[String]",
                     gzip_reader, :readlines, "l", nil
    assert_send_type "(Integer limit) -> Array[String]",
                     gzip_reader, :readlines, 2
  end

  def test_each
    each_line_tests(:each)
  end

  def test_each_line
    each_line_tests(:each_line)
  end

  def test_each_byte
    assert_send_type "() { (Integer) -> void } -> nil",
                     gzip_reader, :each_byte do end
    assert_send_type "() -> Enumerator[Integer, nil]",
                     gzip_reader, :each_byte
  end

  def test_each_char
    assert_send_type "() { (String) -> void } -> nil",
                     gzip_reader, :each_char do end
    assert_send_type "() -> Enumerator[String, nil]",
                     gzip_reader, :each_char
  end

  def test_ungetc
    assert_send_type "(String) -> nil",
                     gzip_reader, :ungetc, "x"
    assert_send_type "(ToStr) -> nil",
                     gzip_reader, :ungetc, ToStr.new("x")
    assert_send_type "(Integer) -> nil",
                     gzip_reader, :ungetc, 65
  end

  private

  def each_line_tests(method)
    assert_send_type "() { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method do end
    assert_send_type "(String sep) { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method, "l" do end
    assert_send_type "(nil sep) { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method, nil do end
    assert_send_type "(nil sep, Integer limit) { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method, nil, 2 do end
    assert_send_type "(String sep, nil limit) { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method, "l", nil do end
    assert_send_type "(Integer limit) { (String) -> void } -> Zlib::GzipReader",
                     gzip_reader, method, 2 do end
    assert_send_type "() -> Enumerator[String, Zlib::GzipReader]",
                     gzip_reader, method
  end

  def gzip_reader
    io = StringIO.new
    writer = Zlib::GzipWriter.new(io)
    writer.write("hello")
    writer.close

    Zlib::GzipReader.new(StringIO.new(io.string))
  end
end
