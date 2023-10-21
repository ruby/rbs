require_relative "test_helper"
require 'tempfile'

# initialize temporary class
module RBS
  module Unnamed
    ARGFClass ||= ARGF.class
  end
end

class ARGFTest < Test::Unit::TestCase
  include TypeAssertions
  testing "::RBS::Unnamed::ARGFClass"

  def argf_for_write
    argf = ARGF.class.new(Tempfile.new.path)
    argf.inplace_mode = ".bak"
    # NOTE: Call rewind to call ARGF.next_argv internally (see: argf_write_io in io.c)
    argf.rewind
    argf
  end

  def test_gets
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :gets
    assert_send_type  "(::String sep) -> ::String",
                      ARGF.class.new(__FILE__), :gets, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::String",
                      ARGF.class.new(__FILE__), :gets, "\n", 1
    assert_send_type  "() -> nil",
                      ARGF.class.new(Tempfile.new), :gets
  end

  def test_print
    assert_send_type  "(*untyped args) -> nil",
                      argf_for_write, :print, "ok"
  end

  def test_printf
    assert_send_type  "(::String format_string, *untyped args) -> nil",
                      argf_for_write, :printf, "%s", "ok"
  end

  def test_putc
    assert_send_type  "(::String obj) -> untyped",
                      argf_for_write, :putc, "c"
    assert_send_type  "(::Numeric) -> untyped",
                      argf_for_write, :putc, "c".ord
  end

  def test_puts
    assert_send_type  "(*untyped obj) -> nil",
                      argf_for_write, :puts, "ok"
  end

  def test_readline
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :readline
    assert_send_type  "(::String sep) -> ::String",
                      ARGF.class.new(__FILE__), :readline, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::String",
                      ARGF.class.new(__FILE__), :readline, "\n", 1
  end

  def test_readlines
    assert_send_type  "() -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :readlines
    assert_send_type  "(::String sep) -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :readlines, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :readlines, "\n", 1
  end

  def test_inspect
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :inspect
  end

  def test_to_s
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :to_s
  end

  def test_to_a
    assert_send_type  "() -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :to_a
    assert_send_type  "(::String sep) -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :to_a, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :to_a, "\n", 1
  end

  def test_argv
    assert_send_type  "() -> ::Array[::String]",
                      ARGF.class.new(__FILE__), :argv
  end

  def test_binmode
    assert_send_type  "() -> self",
                      ARGF.class.new(__FILE__), :binmode
  end

  def test_binmode?
    assert_send_type  "() -> bool",
                      ARGF.class.new(__FILE__), :binmode?
  end

  def test_close
    assert_send_type  "() -> self",
                      ARGF.class.new(__FILE__), :close
  end

  def test_closed?
    assert_send_type  "() -> bool",
                      ARGF.class.new(__FILE__), :closed?
  end

  def test_each
    assert_send_type  "() { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each do |line| line end
    assert_send_type  "(::String sep) { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each, "\n" do |line| line end
    assert_send_type  "(::String sep, ::Integer limit) { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each, "\n", 1 do |line| line end

    assert_send_type  "() -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each
    assert_send_type  "(::String sep) -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each, "\n", 1
  end

  def test_each_byte
    assert_send_type  "() { (::Integer byte) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_byte do |byte| byte end
    assert_send_type  "() -> ::Enumerator[::Integer, self]",
                      ARGF.class.new(__FILE__), :each_byte
  end

  def test_each_char
    assert_send_type  "() { (::String char) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_char do |char| char end
    assert_send_type  "() -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each_char
  end

  def test_each_codepoint
    assert_send_type  "() { (::Integer codepoint) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_codepoint do |codepoint| end
    assert_send_type  "() -> ::Enumerator[::Integer, self]",
                      ARGF.class.new(__FILE__), :each_codepoint
  end

  def test_each_line
    assert_send_type  "() { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_line do |line| line end
    assert_send_type  "(::String sep) { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_line, "\n" do |line| line end
    assert_send_type  "(::String sep, ::Integer limit) { (::String line) -> untyped } -> self",
                      ARGF.class.new(__FILE__), :each_line, "\n", 1 do |line| line end

    assert_send_type  "() -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each_line
    assert_send_type  "(::String sep) -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each_line, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Enumerator[::String, self]",
                      ARGF.class.new(__FILE__), :each_line, "\n", 1
  end

  def test_eof
    assert_send_type  "() -> bool",
                      ARGF.class.new(__FILE__), :eof
  end

  def test_eof?
    assert_send_type  "() -> bool",
                      ARGF.class.new(__FILE__), :eof?
  end

  def test_external_encoding
    assert_send_type  "() -> ::Encoding",
                      ARGF.class.new(__FILE__), :external_encoding
  end

  def test_file
    assert_send_type  "() -> (::IO | ::File)",
                      ARGF.class.new(__FILE__), :file
  end

  def test_filename
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :filename
  end

  def test_fileno
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :fileno
  end

  def test_getbyte
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :getbyte
    assert_send_type  "() -> nil",
                      ARGF.class.new(Tempfile.new), :getbyte
  end

  def test_getc
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :getc
    assert_send_type  "() -> nil",
                      ARGF.class.new(Tempfile.new), :getc
  end

  def test_inplace_mode
    assert_send_type  "() -> nil",
                      ARGF.class.new(__FILE__), :inplace_mode

    argf = ARGF.class.new(__FILE__)
    argf.inplace_mode = ".bak"
    assert_send_type  "() -> String",
                      argf, :inplace_mode
  end

  def test_inplace_mode=()
    assert_send_type  "(::String) -> self",
                      ARGF.class.new(__FILE__), :inplace_mode=, ".bak"
  end

  def test_internal_encoding
    assert_send_type  "() -> ::Encoding",
                      ARGF.class.new(__FILE__), :internal_encoding
  end

  def test_lineno
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :lineno
  end

  def test_lineno=()
    assert_send_type  "(::Integer) -> untyped",
                      ARGF.class.new(__FILE__), :lineno=, 1
  end

  def test_path
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :path
  end

  def test_pos
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :pos
  end

  def test_pos=
    assert_send_type  "(::Integer) -> ::Integer",
                      ARGF.class.new(__FILE__), :pos=, 1
  end

  def test_read
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :read
    assert_send_type  "(::int length) -> ::String",
                      ARGF.class.new(__FILE__), :read, 1
    assert_send_type  "(::int length, ::string outbuf) -> ::String",
                      ARGF.class.new(__FILE__), :read, 1, ""
    assert_send_type  "(::int length) -> nil",
                      ARGF.class.new(Tempfile.new), :read, 1
  end

  def test_read_nonblock
    assert_send_type  "(::int maxlen) -> ::String",
                      ARGF.class.new(__FILE__), :read_nonblock, 1
    assert_send_type  "(::int maxlen, ::string buf) -> ::String",
                      ARGF.class.new(__FILE__), :read_nonblock, 1, ""
  end

  def test_readbyte
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :readbyte
  end

  def test_readchar
    assert_send_type  "() -> ::String",
                      ARGF.class.new(__FILE__), :readchar
  end

  def test_readpartial
    assert_send_type  "(::int maxlen) -> ::String",
                      ARGF.class.new(__FILE__), :readpartial, 1
    assert_send_type  "(::int maxlen, ::string buf) -> ::String",
                      ARGF.class.new(__FILE__), :readpartial, 1, ""
  end

  def test_rewind
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :rewind
  end

  def test_seek
    assert_send_type  "(::Integer amount) -> ::Integer",
                      ARGF.class.new(__FILE__), :seek, 1
    assert_send_type  "(::Integer amount, ::Integer whence) -> ::Integer",
                      ARGF.class.new(__FILE__), :seek, 1, IO::SEEK_SET

  end
  def test_set_encoding
    assert_send_type  "(::String) -> self",
                      ARGF.class.new(__FILE__), :set_encoding, "utf-8"
    assert_send_type  "(::Encoding) -> self",
                      ARGF.class.new(__FILE__), :set_encoding, Encoding::UTF_8
    assert_send_type  "(::String, ::String) -> self",
                      ARGF.class.new(__FILE__), :set_encoding, "utf-8", "utf-8"
    assert_send_type  "(::Encoding, ::Encoding) -> self",
                      ARGF.class.new(__FILE__), :set_encoding, Encoding::UTF_8, Encoding::UTF_8
  end

  def test_skip
    assert_send_type  "() -> self",
                      ARGF.class.new(__FILE__), :skip
  end

  def test_tell
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :tell
  end

  def test_to_i
    assert_send_type  "() -> ::Integer",
                      ARGF.class.new(__FILE__), :to_i
  end

  def test_to_io
    assert_send_type  "() -> ::IO",
                      ARGF.class.new(__FILE__), :to_io
  end

  def test_to_write_io
    assert_send_type  "() -> ::IO",
                      argf_for_write, :to_write_io
  end

  def test_write
    assert_send_type  "(::String) -> ::Integer",
                      argf_for_write, :write, "ok"
    assert_send_type  "(::Integer) -> ::Integer",
                      argf_for_write, :write, 1
  end
end
