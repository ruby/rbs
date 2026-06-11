require_relative "test_helper"

class StringIOTest < StdlibTest
  target StringIO

  def test_close_read
    io = StringIO.new('example')
    io.close_read
  end

  def test_closed_read?
    io = StringIO.new('example')
    io.closed_read?
    io.close_read
    io.closed_read?
  end

  def test_close_write
    io = StringIO.new(+'example')
    io.close_write
  end

  def test_closed_write?
    io = StringIO.new(+'example')
    io.closed_write?
    io.close_write
    io.closed_write?
  end

  def test_each
    io = StringIO.new("")
    io.each(chomp: 3) do end
    io.each(chomp: 3)
  end

  def test_gets
    io = StringIO.new("")
    io.gets(chomp: :true)
  end
end

class StringIOSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::StringIO)'

  def test_open
    assert_send_type "() -> ::StringIO",
                     StringIO, :open
    assert_send_type "(::String) -> ::StringIO",
                     StringIO, :open, "abc"
    assert_send_type "(::String, ::String) -> ::StringIO",
                     StringIO, :open, "abc", "r"
    assert_send_type "() { (::StringIO) -> ::Integer } -> ::Integer",
                     StringIO, :open do |io| io.write("a") end
  end
end

class StringIOTypeTest < Test::Unit::TestCase
  include TestHelper

  testing '::StringIO'

  def test_write
    io = StringIO.new

    assert_send_type "(*String data) -> Integer",
                     io, :write, "a", "b"
  end

  def test_truncate
    io = StringIO.new

    assert_send_type(
      "(Integer) -> 0",
      io, :truncate, 10
    )
  end

  def test_readline
    assert_send_type  "() -> ::String",
                      StringIO.new("\n"), :readline
    assert_send_type  "(::String sep) -> ::String",
                      StringIO.new("\n"), :readline, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::String",
                      StringIO.new("\n"), :readline, "\n", 1
    assert_send_type  "(chomp: boolish) -> ::String",
                      StringIO.new("\n"), :readline, chomp: true
    assert_send_type  "(::String sep, ::Integer limit, chomp: boolish) -> ::String",
                      StringIO.new("\n"), :readline, "\n", 1, chomp: true
  end

  def test_readlines
    assert_send_type  "() -> ::Array[::String]",
                      StringIO.new("\n"), :readlines
    assert_send_type  "(::String sep) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n", 1
    assert_send_type  "(chomp: boolish) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, chomp: true
    assert_send_type  "(::String sep, ::Integer limit, chomp: boolish) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n", 1, chomp: true
  end

  def test_pread
    assert_send_type "(Integer, Integer) -> String",
                     StringIO.new("abcdef"), :pread, 3, 0
    assert_send_type "(Integer, Integer, String) -> String",
                     StringIO.new("abcdef"), :pread, 3, 0, +"buf"
  end

  def test_read_nonblock
    assert_send_type "(int) -> String",
                     StringIO.new("abc"), :read_nonblock, 2
    assert_send_type "(int, string) -> String",
                     StringIO.new("abc"), :read_nonblock, 2, +"buf"
    assert_send_type "(int, exception: true) -> String",
                     StringIO.new("abc"), :read_nonblock, 2, exception: true
    assert_send_type "(int, exception: false) -> String",
                     StringIO.new("abc"), :read_nonblock, 2, exception: false
    assert_send_type "(int, exception: false) -> nil",
                     StringIO.new(""), :read_nonblock, 2, exception: false
  end

  def test_write_nonblock
    assert_send_type "(_ToS) -> Integer",
                     StringIO.new(+""), :write_nonblock, "abc"
    assert_send_type "(_ToS, exception: true) -> Integer",
                     StringIO.new(+""), :write_nonblock, "abc", exception: true
    assert_send_type "(_ToS, exception: false) -> Integer",
                     StringIO.new(+""), :write_nonblock, "abc", exception: false
  end

  def test_sysread
    assert_send_type "(Integer) -> String",
                     StringIO.new("abc"), :sysread, 2
    assert_send_type "(Integer, String) -> String",
                     StringIO.new("abc"), :sysread, 2, +"buf"
  end

  def test_ungetc
    assert_send_type "(String) -> nil",
                     StringIO.new(+"abc"), :ungetc, "x"
    assert_send_type "(Integer) -> nil",
                     StringIO.new(+"abc"), :ungetc, 65
  end

  def test_set_encoding_by_bom
    assert_send_type "() -> Encoding",
                     StringIO.new("\u{FEFF}abc"), :set_encoding_by_bom
    assert_send_type "() -> nil",
                     StringIO.new("abc"), :set_encoding_by_bom
  end

  def test_fcntl
    assert_send_type_error "(*untyped) -> bot", NotImplementedError,
                           StringIO.new("abc"), :fcntl, 1, 1
  end

  def test_fsync
    assert_send_type "() -> Integer",
                     StringIO.new("abc"), :fsync
  end

  def test_internal_encoding
    assert_send_type "() -> nil",
                     StringIO.new("abc"), :internal_encoding
  end

  def test_external_encoding
    assert_send_type "() -> Encoding",
                     StringIO.new("abc"), :external_encoding
  end
end
