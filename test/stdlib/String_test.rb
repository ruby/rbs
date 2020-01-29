require_relative "test_helper"

class StringTest < StdlibTest
  target String
  using hook.refinement

  def test_try_convert
    String.try_convert("str")
    String.try_convert(/re/)
  end

  def test_format_m
    "%05d" % 123
    "%-5s: %016x" % [ "ID", self.object_id ]
    "foo = %{foo}" % { :foo => 'bar' }
  end

  def test_times
    "Ho! " * 3
    "Ho! " * 0
  end

  def test_plus
    "Hello from " + self.to_s
  end

  def test_unary_plus
    +''
  end

  def test_unary_minus
    -''
  end

  def test_concat
    a = "hello "
    a << "world"
    a << 33
  end

  def test_cmp
    "abcdef" <=> "abcde"
    "abcdef" <=> 1
  end

  def test_eq
    "a" == "a"
    "a" == nil
  end

  def test_eqq
    "a" === "a"
    "a" === nil
  end

  def test_match_op
    "a" =~ /a/
    "a" =~ nil
  end

  def test_aref
    "a"[0] == "a" or raise
    "a"[1] == nil or raise
    "a"[0, 1] == "a" or raise
    "a"[2, 1] == nil or raise
    "a"[0..1] == "a" or raise
    "a"[2..1] == nil or raise
    "a"[0...] == "a" or raise
    "a"[2...] == nil or raise
    if ::RUBY_27_OR_LATER
      eval(<<~RUBY)
        "a"[...0] == "" or raise
      RUBY
    end
    "a"[/a/] == "a" or raise
    "a"[/b/] == nil or raise
    "a"[/a/, 0] == "a" or raise
    "a"[/b/, 0] == nil or raise
    "a"[/(?<a>a)/, "a"] == "a" or raise
    "a"[/(?<b>b)/, "b"] == nil or raise
    "a"["a"] == "a" or raise
    "a"["b"] == nil or raise
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

  def test_ascii_only?
    "abc".force_encoding("UTF-8").ascii_only?
    "abc\u{6666}".force_encoding("UTF-8").ascii_only?
  end

  def test_b
    "a".b
  end

  def test_bytes
    "a".bytes
    "a".bytes {|b| b }
  end

  def test_bytesize
    s = "string"
    s.bytesize
  end

  def test_byteslice
    "hello".byteslice(1)
    "hello".byteslice(10)
    "hello".byteslice(1, 2)
    "hello".byteslice(10, 2)
    "\x03\u3042\xff".byteslice(1..3)
    "\x03\u3042\xff".byteslice(11..13)
  end

  def test_casecmp?
    "aBcDeF".casecmp?("abcde")
    "aBcDeF".casecmp?("abcdef")
    "foo".casecmp?(2)
  end

  def test_capitalize
    "a".capitalize
    "a".capitalize(:ascii)
    "a".capitalize(:lithuanian)
    "a".capitalize(:turkic)
    "a".capitalize(:lithuanian, :turkic)
    "a".capitalize(:turkic, :lithuanian)
  end

  def test_delete_prefix
    "foo".delete_prefix("f")
  end

  def test_delete_prefix!
    "foo".delete_prefix! "f"
    "foo".delete_prefix! "a"
  end

  def test_delete_suffix
    "foo".delete_suffix "o"
  end

  def test_delete_suffix!
    "foo".delete_suffix! "o"
    "foo".delete_suffix! "a"
  end

  def test_each_grapheme_cluster
    "test".each_grapheme_cluster
    "test".each_grapheme_cluster { |c| nil }
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

  def test_grapheme_clusters
    "\u{1F1EF}\u{1F1F5}".grapheme_clusters
  end

  def test_gsub
    s = "string"
    s.gsub(/./, "")
    s.gsub("a", "b")
    s.gsub(/./) {|x| "" }
    s.gsub(/./, {"foo" => "bar"})
    s.gsub(/./)
    s.gsub("")
  end

  def test_include
    "".include?("")
  end

  def test_reverse!
    "test".reverse!
  end

  def test_succ
    "".succ
  end

  def test_succ!
    "".succ
  end

  def test_undump
    "\"hello \\n ''\"".undump
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

  def test_unicode_normalized?
    "a\u0300".unicode_normalized?
    "a\u0300".unicode_normalized?(:nfc)
    "a\u0300".unicode_normalized?(:nfd)
    "a\u0300".unicode_normalized?(:nfkc)
    "a\u0300".unicode_normalized?(:nfkd)
  end

  def test_unpack1
    "a".unpack1("")
    "a".unpack1("c")
    "a".unpack1("A")
    "\x00\x00\x00\x00".unpack1("f")
  end

  def test_initialize
    String.new
    String.new("")
    String.new("", encoding: Encoding::ASCII_8BIT)
    String.new("", encoding: Encoding::ASCII_8BIT, capacity: 123)
    String.new(encoding: Encoding::ASCII_8BIT, capacity: 123)
  end
end
