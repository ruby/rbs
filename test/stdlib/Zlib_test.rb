require_relative "test_helper"
require "zlib"

class ZlibSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "zlib"
  testing "singleton(::Zlib)"


  def test_adler32
    assert_send_type  "() -> ::Integer",
                      Zlib, :adler32
    assert_send_type  "(::String) -> ::Integer",
                      Zlib, :adler32, "hello"
    assert_send_type  "(::String, ::Integer) -> ::Integer",
                      Zlib, :adler32, "hello", 1
  end

  def test_adler32_combine
    assert_send_type  "(::Integer, ::Integer, ::Integer) -> ::Integer",
                      Zlib, :adler32_combine, 1, 1, 1
  end

  def test_crc32
    assert_send_type  "() -> ::Integer",
                      Zlib, :crc32
    assert_send_type  "(::String) -> ::Integer",
                      Zlib, :crc32, "hello"
    assert_send_type  "(::String, ::Integer) -> ::Integer",
                      Zlib, :crc32, "hello", 1
  end

  def test_crc32_combine
    assert_send_type  "(::Integer, ::Integer, ::Integer) -> ::Integer",
                      Zlib, :crc32_combine, 1, 1, 1
  end

  def test_crc_table
    assert_send_type  "() -> ::Array[::Integer]",
                      Zlib, :crc_table
  end

  def test_deflate
    assert_send_type  "(::String) -> ::String",
                      Zlib, :deflate, "hello"
    assert_send_type  "(::String, ::Integer) -> ::String",
                      Zlib, :deflate, "hello", 1
  end

  def test_gunzip
    gzipped_hello = "\x1F\x8B\b\x00\x12f)_\x00\x03\xCBH\xCD\xC9\xF1\a\x00N\x86~\r\x05\x00\x00\x00"
    assert_send_type  "(::String) -> ::String",
                      Zlib, :gunzip, gzipped_hello
  end

  def test_gzip
    assert_send_type  "(::String) -> ::String",
                      Zlib, :gzip, "hello"
    assert_send_type  "(::String, level: ::Integer) -> ::String",
                      Zlib, :gzip, "hello", level: 1
    assert_send_type  "(::String, strategy: ::Integer) -> ::String",
                      Zlib, :gzip, "hello", strategy: 1
    assert_send_type  "(::String, level: ::Integer, strategy: ::Integer) -> ::String",
                      Zlib, :gzip, "hello", level: 1, strategy: 1
  end

  def test_inflate
    deflated_hello =  "x\x9C\xCBH\xCD\xC9\xC9\a\x00\x06,\x02\x15"
    assert_send_type  "(::String) -> ::String",
                      Zlib, :inflate, deflated_hello
  end

  def test_zlib_version
    assert_send_type  "() -> ::String",
                      Zlib, :zlib_version
  end
end

