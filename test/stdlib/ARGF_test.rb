require_relative "test_helper"

class ARGFSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "singleton(::ARGF)"


  def test_new
    assert_send_type  "(*::String argv) -> ::ARGF",
                      ARGF.class, :new
  end
end

class ARGFTest < Test::Unit::TestCase
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::ARGF"


  def test_initialize
    assert_send_type  "(*::String argv) -> void",
                      ARGF.class.new, :initialize
  end

  def test_initialize_copy
    assert_send_type  "(self orig) -> self",
                      ARGF.class.new, :initialize_copy
  end

  def test_gets
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::String?",
                      ARGF.class.new, :gets
  end

  def test_print
    assert_send_type  "(*untyped args) -> nil",
                      ARGF.class.new, :print
  end

  def test_printf
    assert_send_type  "(::String format_string, *untyped args) -> nil",
                      ARGF.class.new, :printf
  end

  def test_putc
    assert_send_type  "(::Numeric | ::String obj) -> untyped",
                      ARGF.class.new, :putc
  end

  def test_puts
    assert_send_type  "(*untyped obj) -> nil",
                      ARGF.class.new, :puts
  end

  def test_readline
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::String",
                      ARGF.class.new, :readline
  end

  def test_readlines
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::Array[::String]",
                      ARGF.class.new, :readlines
  end

  def test_inspect
    assert_send_type  "() -> ::String",
                      ARGF.class.new, :inspect
  end

  def test_to_s
    assert_send_type  "() -> ::String",
                      ARGF.class.new, :to_s
  end

  def test_to_a
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::Array[::String]",
                      ARGF.class.new, :to_a
  end

  def test_argv
    assert_send_type  "() -> ::Array[::String]",
                      ARGF.class.new, :argv
  end

  def test_binmode
    assert_send_type  "() -> self",
                      ARGF.class.new, :binmode
  end

  def test_binmode?
    assert_send_type  "() -> bool",
                      ARGF.class.new, :binmode?
  end

  def test_close
    assert_send_type  "() -> self",
                      ARGF.class.new, :close
  end

  def test_closed?
    assert_send_type  "() -> bool",
                      ARGF.class.new, :closed?
  end

  def test_each
    assert_send_type  "(?::String sep, ?::Integer limit) { (::String line) -> untyped } -> self",
                      ARGF.class.new, :each
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::Enumerator[::String, self]",
                      ARGF.class.new, :each
  end

  def test_each_byte
    assert_send_type  "() { (::Integer byte) -> untyped } -> self",
                      ARGF.class.new, :each_byte
    assert_send_type  "() -> ::Enumerator[::Integer, self]",
                      ARGF.class.new, :each_byte
  end

  def test_each_char
    assert_send_type  "() { (::String char) -> untyped } -> self",
                      ARGF.class.new, :each_char
    assert_send_type  "() -> ::Enumerator[::String, self]",
                      ARGF.class.new, :each_char
  end

  def test_each_codepoint
    assert_send_type  "() { (::Integer codepoint) -> untyped } -> self",
                      ARGF.class.new, :each_codepoint
    assert_send_type  "() -> ::Enumerator[::Integer, self]",
                      ARGF.class.new, :each_codepoint
  end

  def test_each_line
    assert_send_type  "(?::String sep, ?::Integer limit) { (::String line) -> untyped } -> self",
                      ARGF.class.new, :each_line
    assert_send_type  "(?::String sep, ?::Integer limit) -> ::Enumerator[::String, self]",
                      ARGF.class.new, :each_line
  end

  def test_eof
    assert_send_type  "() -> bool",
                      ARGF.class.new, :eof
  end

  def test_eof?
    assert_send_type  "() -> bool",
                      ARGF.class.new, :eof?
  end

  def test_external_encoding
    assert_send_type  "() -> ::Encoding",
                      ARGF.class.new, :external_encoding
  end

  def test_file
    assert_send_type  "() -> (::IO | ::File)",
                      ARGF.class.new, :file
  end

  def test_filename
    assert_send_type  "() -> ::String",
                      ARGF.class.new, :filename
  end

  def test_fileno
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :fileno
  end

  def test_getbyte
    assert_send_type  "() -> ::Integer?",
                      ARGF.class.new, :getbyte
  end

  def test_getc
    assert_send_type  "() -> ::String?",
                      ARGF.class.new, :getc
  end

  def test_inplace_mode
    assert_send_type  "() -> ::String?",
                      ARGF.class.new, :inplace_mode
  end

  def test_inplace_mode=
    assert_send_type  "(::String) -> self",
                      ARGF.class.new, :inplace_mode=
  end

  def test_internal_encoding
    assert_send_type  "() -> ::Encoding",
                      ARGF.class.new, :internal_encoding
  end

  def test_lineno
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :lineno
  end

  def test_lineno=
    assert_send_type  "(::Integer) -> untyped",
                      ARGF.class.new, :lineno=
  end

  def test_path
    assert_send_type  "() -> ::String",
                      ARGF.class.new, :path
  end

  def test_pos
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :pos
  end

  def test_pos=
    assert_send_type  "(::Integer) -> ::Integer",
                      ARGF.class.new, :pos=
  end

  def test_read
    assert_send_type  "(?::int? length, ?::string outbuf) -> ::String?",
                      ARGF.class.new, :read
  end

  def test_read_nonblock
    assert_send_type  "(::int maxlen, ?::string buf, **untyped options) -> ::String",
                      ARGF.class.new, :read_nonblock
  end

  def test_readbyte
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :readbyte
  end

  def test_readchar
    assert_send_type  "() -> ::String",
                      ARGF.class.new, :readchar
  end

  def test_readpartial
    assert_send_type  "(::int maxlen, ?::string outbuf) -> ::String",
                      ARGF.class.new, :readpartial
  end

  def test_rewind
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :rewind
  end

  def test_seek
    assert_send_type  "(::Integer amount, ?::Integer whence) -> ::Integer",
                      ARGF.class.new, :seek
  end

  def test_set_encoding
    assert_send_type  "(::String | ::Encoding ext_or_ext_int_enc, ?::String | ::Encoding int_enc) -> self",
                      ARGF.class.new, :set_encoding
  end

  def test_skip
    assert_send_type  "() -> self",
                      ARGF.class.new, :skip
  end

  def test_tell
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :tell
  end

  def test_to_i
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new, :to_i
  end

  def test_to_io
    assert_send_type  "() -> ::IO",
                      ARGF.class.new, :to_io
  end

  def test_to_write_io
    assert_send_type  "() -> ::IO",
                      ARGF.class.new, :to_write_io
  end

  def test_write
    assert_send_type  "(::_ToS string) -> ::Integer",
                      ARGF.class.new, :write
  end
end
