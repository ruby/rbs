require_relative "../test_helper"
require "zlib"
require "tempfile"
require "pathname"

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
      assert_send_type "(String filename) { (Zlib::GzipReader) -> void } -> void",
                       Zlib::GzipReader, :open, path do |_| _ end
      assert_send_type "(_ToPath filename) { (Zlib::GzipReader) -> void } -> void",
                       Zlib::GzipReader, :open, Pathname(path) do |_| _ end
    end
  end

  def test_wrap
    Dir.mktmpdir do |tmpdir|
      path = File.join(tmpdir, "test.gz")
      Zlib::GzipWriter.open(path) { _1.puts "hello" }

      File.open(path) do |io|
        assert_send_type "(IO io) -> Zlib::GzipReader",
                         Zlib::GzipReader, :wrap, io

        io.rewind

        assert_send_type "(IO io) { (Zlib::GzipReader gz) -> void } -> void",
                         Zlib::GzipReader, :wrap, io do |_| _ end
      end
    end
  end
end
