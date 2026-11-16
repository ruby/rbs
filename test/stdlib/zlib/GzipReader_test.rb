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
    assert_send_type "(nil, nil) -> String?",
                     gzip_reader, :read, nil, nil
    assert_send_type "(int length, nil) -> String?",
                     gzip_reader, :read, 1, nil
  end

  def test_readpartial
    assert_send_type "(int maxlen, nil) -> String",
                     gzip_reader, :readpartial, 1, nil
  end

  private

  def gzip_reader
    io = StringIO.new
    writer = Zlib::GzipWriter.new(io)
    writer.write("hello")
    writer.close

    Zlib::GzipReader.new(StringIO.new(io.string))
  end
end
