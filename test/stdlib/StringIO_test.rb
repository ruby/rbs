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

  def test_constants
    assert_const_type "String", "StringIO::VERSION"
    assert_const_type "Integer", "StringIO::MAX_LENGTH"
  end

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

  def test_read
    assert_send_type "(nil, nil) -> ::String?",
                     StringIO.new("a"), :read, nil, nil
    assert_send_type "(::Integer, nil) -> ::String?",
                     StringIO.new("a"), :read, 1, nil
  end

  def test_readpartial
    assert_send_type "(::int, nil) -> ::String",
                     StringIO.new("a"), :readpartial, 1, nil
  end

  def test_truncate
    io = StringIO.new

    assert_send_type(
      "(Integer) -> 0",
      io, :truncate, 10
    )
  end

  def test_gets
    assert_send_type  "() -> ::String",
                      StringIO.new("a\nb"), :gets
    assert_send_type  "() -> nil",
                      StringIO.new(""), :gets
    assert_send_type  "(::String sep) -> ::String",
                      StringIO.new("a\nb"), :gets, "\n"
    assert_send_type  "(nil sep) -> ::String",
                      StringIO.new("a\nb"), :gets, nil
    assert_send_type  "(::String sep, ::Integer limit) -> ::String",
                      StringIO.new("a\nb"), :gets, "\n", 1
    assert_send_type  "(nil sep, ::Integer limit) -> ::String",
                      StringIO.new("a\nb"), :gets, nil, 2
    assert_send_type  "(::String sep, nil limit) -> ::String",
                      StringIO.new("a\nb"), :gets, "\n", nil
    assert_send_type  "(::Integer limit) -> ::String",
                      StringIO.new("a\nb"), :gets, 1
    assert_send_type  "(ToInt limit) -> ::String",
                      StringIO.new("a\nb"), :gets, ToInt.new(1)
    assert_send_type  "(ToStr sep) -> ::String",
                      StringIO.new("a\nb"), :gets, ToStr.new("\n")
    assert_send_type  "(chomp: boolish) -> ::String",
                      StringIO.new("a\nb"), :gets, chomp: true
    assert_send_type  "(::Integer limit, chomp: boolish) -> ::String",
                      StringIO.new("a\nb"), :gets, 2, chomp: true
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
    assert_send_type  "(nil sep) -> ::String",
                      StringIO.new("a\nb"), :readline, nil
    assert_send_type  "(nil sep, ::Integer limit) -> ::String",
                      StringIO.new("a\nb"), :readline, nil, 2
    assert_send_type  "(::String sep, nil limit) -> ::String",
                      StringIO.new("a\nb"), :readline, "\n", nil
    assert_send_type  "(::Integer limit) -> ::String",
                      StringIO.new("a\nb"), :readline, 1
    assert_send_type  "(ToInt limit) -> ::String",
                      StringIO.new("a\nb"), :readline, ToInt.new(1)
    assert_send_type  "(ToStr sep) -> ::String",
                      StringIO.new("a\nb"), :readline, ToStr.new("\n")
    assert_send_type  "(::Integer limit, chomp: boolish) -> ::String",
                      StringIO.new("a\nb"), :readline, 2, chomp: true
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
    assert_send_type  "(nil sep) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, nil
    assert_send_type  "(nil sep, ::Integer limit) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, nil, 2
    assert_send_type  "(::String sep, nil limit) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, "\n", nil
    assert_send_type  "(::Integer limit) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, 1
    assert_send_type  "(ToInt limit) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, ToInt.new(1)
    assert_send_type  "(ToStr sep) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, ToStr.new("\n")
    assert_send_type  "(::Integer limit, chomp: boolish) -> ::Array[::String]",
                      StringIO.new("a\nb"), :readlines, 2, chomp: true
  end

  def test_each
    each_line_tests(:each)
  end

  def test_each_line
    each_line_tests(:each_line)
  end

  def test_pread
    assert_send_type "(Integer, Integer) -> String",
                     StringIO.new("abcdef"), :pread, 3, 0
    assert_send_type "(Integer, Integer, String) -> String",
                     StringIO.new("abcdef"), :pread, 3, 0, +"buf"
    assert_send_type "(::Integer, ::Integer, nil) -> ::String",
                     StringIO.new("a"), :pread, 1, 0, nil
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
    assert_send_type "(::int, nil) -> ::String?",
                     StringIO.new("a"), :read_nonblock, 1, nil
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
    assert_send_type "(::Integer, nil) -> ::String",
                     StringIO.new("a"), :sysread, 1, nil
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

  def test_length
    assert_send_type "() -> ::Integer",
                     StringIO.new("hello"), :length
  end

  private

  def each_line_tests(method)
    assert_send_type  "() { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method do end
    assert_send_type  "(::String sep) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, "\n" do end
    assert_send_type  "(nil sep) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, nil do end
    assert_send_type  "(nil sep, ::Integer limit) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, nil, 2 do end
    assert_send_type  "(::String sep, nil limit) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, "\n", nil do end
    assert_send_type  "(::Integer limit) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, 1 do end
    assert_send_type  "(::Integer limit, chomp: boolish) { (::String) -> void } -> ::StringIO",
                      StringIO.new("a\nb"), method, 2, chomp: true do end

    assert_send_type  "() -> ::Enumerator[::String, ::StringIO]",
                      StringIO.new("a\nb"), method
    assert_send_type  "(nil sep) -> ::Enumerator[::String, ::StringIO]",
                      StringIO.new("a\nb"), method, nil
    assert_send_type  "(::Integer limit) -> ::Enumerator[::String, ::StringIO]",
                      StringIO.new("a\nb"), method, 1
  end
end
