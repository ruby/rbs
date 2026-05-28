require_relative "test_helper"
require "strscan"

class StringScannerSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "strscan"
  testing "singleton(::StringScanner)"

  def test_new
    assert_send_type "(::String) -> ::StringScanner",
                     StringScanner, :new, "foo"
    assert_send_type "(::String, fixed_anchor: bool) -> ::StringScanner",
                     StringScanner, :new, "foo", fixed_anchor: true
  end

  def test_must_C_version
    assert_send_type "() -> singleton(::StringScanner)",
                     StringScanner, :must_C_version
  end
end

class StringScannerTest < Test::Unit::TestCase
  include TestHelper

  library "strscan"
  testing "::StringScanner"

  # A scanner that has already matched a named-capture regexp; every capture
  # produced a non-nil String. Use this when you want the "all matched" branch.
  def matched_named_scanner
    s = StringScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/(?<wday>\w+) (?<month>\w+) (?<day>\d+) /)
    s
  end

  # A scanner where a named-capture regexp matched, but some captures were
  # optional and resolved to nil. Use this when you want String? value cells.
  def partial_named_scanner
    s = StringScanner.new("Fri")
    s.scan(/(?<wday>\w+)(?<month> \w+)?/)
    s
  end

  # A fresh scanner that has not attempted any match yet.
  def unmatched_scanner
    StringScanner.new("Fri Dec 12 1975 14:39")
  end

  def test_inspect
    assert_send_type "() -> ::String",
                     StringScanner.new("foo"), :inspect
  end

  def test_initialize_copy
    assert_send_type "(::StringScanner) -> void",
                     StringScanner.new("foo"), :initialize_copy, StringScanner.new("bar")
  end

  def test_left_shift
    assert_send_type "(::String) -> ::StringScanner",
                     StringScanner.new("foo"), :<<, "bar"
  end

  def test_square_bracket
    s = matched_named_scanner
    assert_send_type "(::Integer) -> ::String",
                     s, :[], 0
    assert_send_type "(::String) -> ::String",
                     s, :[], "wday"
    assert_send_type "(::Symbol) -> ::String",
                     s, :[], :wday
    assert_send_type "(::Integer) -> nil",
                     unmatched_scanner, :[], 0
  end

  def test_beginning_of_line?
    assert_send_type "() -> bool",
                     StringScanner.new("foo"), :beginning_of_line?
  end

  def test_bol?
    assert_send_type "() -> bool",
                     StringScanner.new("foo"), :bol?
  end

  def test_captures
    assert_send_type "() -> ::Array[::String]",
                     matched_named_scanner, :captures
    assert_send_type "() -> nil",
                     unmatched_scanner, :captures
  end

  def test_charpos
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :charpos
  end

  def test_check
    assert_send_type "(::Regexp) -> ::String",
                     StringScanner.new("foo"), :check, /foo/
    assert_send_type "(::String) -> ::String",
                     StringScanner.new("foo"), :check, "foo"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foo"), :check, /nope/
  end

  def test_check_until
    assert_send_type "(::Regexp) -> ::String",
                     StringScanner.new("foobar"), :check_until, /bar/
    assert_send_type "(::String) -> ::String",
                     StringScanner.new("foobar"), :check_until, "bar"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foobar"), :check_until, /nope/
  end

  def test_concat
    assert_send_type "(::String) -> ::StringScanner",
                     StringScanner.new("foo"), :concat, "bar"
  end

  def test_eos?
    assert_send_type "() -> bool",
                     StringScanner.new("foo"), :eos?
  end

  def test_exist?
    assert_send_type "(::Regexp) -> ::Integer",
                     StringScanner.new("foobar"), :exist?, /bar/
    assert_send_type "(::String) -> ::Integer",
                     StringScanner.new("foobar"), :exist?, "bar"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foobar"), :exist?, /nope/
  end

  def test_fixed_anchor?
    assert_send_type "() -> bool",
                     StringScanner.new("foo"), :fixed_anchor?
  end

  def test_get_byte
    assert_send_type "() -> ::String",
                     StringScanner.new("foo"), :get_byte
    assert_send_type "() -> nil",
                     StringScanner.new(""), :get_byte
  end

  def test_getch
    assert_send_type "() -> ::String",
                     StringScanner.new("foo"), :getch
    assert_send_type "() -> nil",
                     StringScanner.new(""), :getch
  end

  def test_match?
    assert_send_type "(::Regexp) -> ::Integer",
                     StringScanner.new("foo"), :match?, /foo/
    assert_send_type "(::String) -> ::Integer",
                     StringScanner.new("foo"), :match?, "foo"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foo"), :match?, /nope/
  end

  def test_matched
    assert_send_type "() -> ::String",
                     matched_named_scanner, :matched
    assert_send_type "() -> nil",
                     unmatched_scanner, :matched
  end

  def test_matched?
    assert_send_type "() -> bool",
                     matched_named_scanner, :matched?
    assert_send_type "() -> bool",
                     unmatched_scanner, :matched?
  end

  def test_matched_size
    assert_send_type "() -> ::Integer",
                     matched_named_scanner, :matched_size
    assert_send_type "() -> nil",
                     unmatched_scanner, :matched_size
  end

  def test_named_captures
    assert_send_type "() -> ::Hash[::String, ::String]",
                     matched_named_scanner, :named_captures
    assert_send_type "() -> ::Hash[::String, ::String?]",
                     partial_named_scanner, :named_captures
  end

  def test_peek
    assert_send_type "(::Integer) -> ::String",
                     StringScanner.new("foo"), :peek, 3
  end

  def test_peek_byte
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :peek_byte
    assert_send_type "() -> nil",
                     StringScanner.new(""), :peek_byte
  end

  def test_pointer
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :pointer
  end

  def test_pointer=
    assert_send_type "(::Integer) -> ::Integer",
                     StringScanner.new("foo"), :pointer=, 0
  end

  def test_pos
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :pos
  end

  def test_pos=
    assert_send_type "(::Integer) -> ::Integer",
                     StringScanner.new("foo"), :pos=, 0
  end

  def test_post_match
    assert_send_type "() -> ::String",
                     matched_named_scanner, :post_match
    assert_send_type "() -> nil",
                     unmatched_scanner, :post_match
  end

  def test_pre_match
    assert_send_type "() -> ::String",
                     matched_named_scanner, :pre_match
    assert_send_type "() -> nil",
                     unmatched_scanner, :pre_match
  end

  def test_reset
    assert_send_type "() -> ::StringScanner",
                     StringScanner.new("foo"), :reset
  end

  def test_rest
    assert_send_type "() -> ::String",
                     StringScanner.new("foo"), :rest
  end

  def test_rest?
    assert_send_type "() -> bool",
                     StringScanner.new("foo"), :rest?
  end

  def test_rest_size
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :rest_size
  end

  def test_scan
    assert_send_type "(::Regexp) -> ::String",
                     StringScanner.new("foo"), :scan, /foo/
    assert_send_type "(::String) -> ::String",
                     StringScanner.new("foo"), :scan, "foo"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foo"), :scan, /nope/
  end

  def test_scan_byte
    assert_send_type "() -> ::Integer",
                     StringScanner.new("foo"), :scan_byte
    assert_send_type "() -> nil",
                     StringScanner.new(""), :scan_byte
  end

  def test_scan_full
    assert_send_type "(::Regexp, bool, true) -> ::String",
                     StringScanner.new("foo"), :scan_full, /foo/, true, true
    assert_send_type "(::String, bool, true) -> ::String",
                     StringScanner.new("foo"), :scan_full, "foo", false, true
    assert_send_type "(::Regexp, bool, true) -> nil",
                     StringScanner.new("foo"), :scan_full, /nope/, true, true
    assert_send_type "(::Regexp, bool, false) -> ::Integer",
                     StringScanner.new("foo"), :scan_full, /foo/, true, false
    assert_send_type "(::String, bool, false) -> ::Integer",
                     StringScanner.new("foo"), :scan_full, "foo", false, false
    assert_send_type "(::Regexp, bool, false) -> nil",
                     StringScanner.new("foo"), :scan_full, /nope/, true, false
  end

  def test_scan_integer
    assert_send_type "() -> ::Integer",
                     StringScanner.new("123abc"), :scan_integer
    assert_send_type "(base: ::Integer) -> ::Integer",
                     StringScanner.new("0xff"), :scan_integer, base: 16
    assert_send_type "() -> nil",
                     StringScanner.new("abc"), :scan_integer
  end

  def test_scan_until
    assert_send_type "(::Regexp) -> ::String",
                     StringScanner.new("foobar"), :scan_until, /bar/
    assert_send_type "(::String) -> ::String",
                     StringScanner.new("foobar"), :scan_until, "bar"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foobar"), :scan_until, /nope/
  end

  def test_search_full
    assert_send_type "(::Regexp, bool, true) -> ::String",
                     StringScanner.new("foobar"), :search_full, /bar/, true, true
    assert_send_type "(::String, bool, true) -> ::String",
                     StringScanner.new("foobar"), :search_full, "bar", false, true
    assert_send_type "(::Regexp, bool, true) -> nil",
                     StringScanner.new("foobar"), :search_full, /nope/, true, true
    assert_send_type "(::Regexp, bool, false) -> ::Integer",
                     StringScanner.new("foobar"), :search_full, /bar/, true, false
    assert_send_type "(::String, bool, false) -> ::Integer",
                     StringScanner.new("foobar"), :search_full, "bar", false, false
    assert_send_type "(::Regexp, bool, false) -> nil",
                     StringScanner.new("foobar"), :search_full, /nope/, true, false
  end

  def test_size
    assert_send_type "() -> ::Integer",
                     matched_named_scanner, :size
    assert_send_type "() -> nil",
                     unmatched_scanner, :size
  end

  def test_skip
    assert_send_type "(::Regexp) -> ::Integer",
                     StringScanner.new("foo"), :skip, /foo/
    assert_send_type "(::String) -> ::Integer",
                     StringScanner.new("foo"), :skip, "foo"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foo"), :skip, /nope/
  end

  def test_skip_until
    assert_send_type "(::Regexp) -> ::Integer",
                     StringScanner.new("foobar"), :skip_until, /bar/
    assert_send_type "(::String) -> ::Integer",
                     StringScanner.new("foobar"), :skip_until, "bar"
    assert_send_type "(::Regexp) -> nil",
                     StringScanner.new("foobar"), :skip_until, /nope/
  end

  def test_string
    assert_send_type "() -> ::String",
                     StringScanner.new("foo"), :string
  end

  def test_string=
    assert_send_type "(::String) -> ::String",
                     StringScanner.new("foo"), :string=, "bar"
  end

  def test_terminate
    assert_send_type "() -> ::StringScanner",
                     StringScanner.new("foo"), :terminate
  end

  def test_unscan
    # unscan raises StringScanner::Error unless there was a prior match,
    # so we have to scan something first.
    s = StringScanner.new("foo")
    s.scan(/foo/)
    assert_send_type "() -> ::StringScanner",
                     s, :unscan
  end

  def test_values_at
    s = matched_named_scanner
    assert_send_type "(::Integer) -> ::Array[::String]",
                     s, :values_at, 0
    assert_send_type "(::String) -> ::Array[::String]",
                     s, :values_at, "wday"
    assert_send_type "(::Symbol) -> ::Array[::String]",
                     s, :values_at, :wday
    assert_send_type "(::Integer) -> nil",
                     unmatched_scanner, :values_at, 0
  end
end
