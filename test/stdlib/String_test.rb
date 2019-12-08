require_relative "test_helper"

class StringTest < StdlibTest
  target String
  using hook.refinement

  def test_gsub
    s = "string"
    s.gsub(/./, "")
    s.gsub("a", "b")
    s.gsub(/./) {|x| "" }
    s.gsub(/./, {"foo" => "bar"})
    s.gsub(/./)
    s.gsub("")
  end

  def test_bytesize
    s = "string"
    s.bytesize
  end

  def delete_prefix
    "foo".delete_prefix("f")
  end

  def delete_prefix!
    "foo".delete_prefix! "f"
    "foo".delete_prefix! "a"
  end

  def delete_suffix
    "foo".delete_suffix "o"
  end

  def delete_suffix!
    "foo".delete_suffix! "o"
    "foo".delete_suffix! "a"
  end

  def test_endwith
    s = "string"
    s.end_with?
    s.end_with?("foo")
  end

  def test_force_encoding
    s = ""
    s.force_encoding "ASCII-8BIT"
    s.force_encoding Encoding::ASCII_8BIT
  end

  def test_include
    "".include?("")
  end

  def test_initialize
    String.new
    String.new("")
    String.new("", encoding: Encoding::ASCII_8BIT)
    String.new("", encoding: Encoding::ASCII_8BIT, capacity: 123)
    String.new(encoding: Encoding::ASCII_8BIT, capacity: 123)
  end

  def test_succ
    "".succ
  end

  def test_succ!
    "".succ
  end

  def test_encode
    s = "string"
    s.encode("ascii")
    s.encode("ascii", Encoding::ASCII_8BIT)
    s.encode(Encoding::ASCII_8BIT, "ascii")
    s.encode("ascii", invalid: :replace)
    s.encode(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT, undef: nil)
    s.encode(
      invalid: nil,
      undef: :replace,
      replace: "foo",
      fallback: {"a" => "a"},
      xml: :text,
      universal_newline: true,
    )
    s.encode(cr_newline: true)
    s.encode(crlf_newline: true)
  end

  def test_encode!
    s = "string"
    s.encode!("ascii")
    s.encode!("ascii", Encoding::ASCII_8BIT)
    s.encode!(Encoding::ASCII_8BIT, "ascii")
    s.encode!("ascii", invalid: :replace)
    s.encode!(Encoding::ASCII_8BIT, Encoding::ASCII_8BIT, undef: nil)
    s.encode!(
      invalid: nil,
      undef: :replace,
      replace: "foo",
      fallback: {"a" => "a"},
      xml: :text,
      universal_newline: true,
    )
    s.encode!(cr_newline: true)
    s.encode!(crlf_newline: true)
  end

  def test_unary_plus
    +''
  end

  def test_unary_minus
    -''
  end

  def test_unicode_normalize
    "a\u0300".unicode_normalize
    "a\u0300".unicode_normalize(:nfc)
    "a\u0300".unicode_normalize(:nfd)
    "a\u0300".unicode_normalize(:nfkc)
    "a\u0300".unicode_normalize(:nfkd)
  end

  def test_unicode_normalize!
    "a\u0300".unicode_normalize!
    "a\u0300".unicode_normalize!(:nfc)
    "a\u0300".unicode_normalize!(:nfd)
    "a\u0300".unicode_normalize!(:nfkc)
    "a\u0300".unicode_normalize!(:nfkd)
  end

  def test_casecmp?
    "aBcDeF".casecmp?("abcde")
    "aBcDeF".casecmp?("abcdef")
    "foo".casecmp?(2)
  end

  def test_aset_m
    "foo"[0] = "b"
    "foo"[0, 3] = "bar"
    "foo"[0..3] = "bar"
    "foo"[/foo/] = "bar"
    "foo"[/(foo)/, 1] = "bar"
    "foo"[/(?<foo>foo)/, "foo"] = "bar"
    "foo"["foo"] = "bar"
  end

  def test_undump
    "\"hello \\n ''\"".undump
  end

  def test_grapheme_clusters
    "\u{1F1EF}\u{1F1F5}".grapheme_clusters
  end
end
