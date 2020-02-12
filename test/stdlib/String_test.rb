require_relative "test_helper"
require "ruby/signature/test/test_helper"

class StringSingletonTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "singleton(::String)"

  def test_try_convert
    assert_send_type "(String) -> String",
                     String, :try_convert, "str"
    assert_send_type "(ToStr) -> String",
                     String, :try_convert, ToStr.new("str")
    assert_send_type "(Regexp) -> nil",
                     String, :try_convert, /re/
  end
end

class StringTest < StdlibTest
  target String
  using hook.refinement

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

  def test_concat_op
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

  def test_capitalize!
    "a".capitalize!
    "a".capitalize!(:ascii)
    "a".capitalize!(:lithuanian)
    "a".capitalize!(:turkic)
    "a".capitalize!(:lithuanian, :turkic)
    "a".capitalize!(:turkic, :lithuanian)
    "".capitalize!
    "".capitalize!(:ascii)
    "".capitalize!(:lithuanian)
    "".capitalize!(:turkic)
    "".capitalize!(:lithuanian, :turkic)
    "".capitalize!(:turkic, :lithuanian)
  end

  def test_casecmp
    "a".casecmp("A")
    "a".casecmp("B")
    "b".casecmp("A")
    "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym.casecmp("\u{c4 d6 dc}")
    "a".casecmp(42)
  end

  def test_casecmp_p
    "a".casecmp?("A")
    "a".casecmp?("B")
    "\u{e4 f6 fc}".encode("ISO-8859-1").to_sym.casecmp?("\u{c4 d6 dc}")
    "a".casecmp?(42)
  end

  def test_center
    "hello".center(4)
    "hello".center(20, '123')
  end

  def test_chars
    "a".chars
    "a".chars {|c| c }
  end

  def test_chomp
    "a".chomp
    "a".chomp("")
  end

  def test_chomp!
    "a\n".chomp!
    "a\n".chomp!("\r")
  end

  def test_chop
    "a".chop
  end

  def test_chop!
    "a".chop!
    "".chop!
  end

  def test_chr
    "a".chr
  end

  def test_clear
    "a".clear
  end

  def test_codepoints
    "a".codepoints
    "a".codepoints {|cp| cp }
  end

  def test_concat
    a = "hello"
    a.concat
    a.concat(" ")
    a.concat("world", 33)
  end

  def test_count
    a = "hello world"
    a.count("lo")
    a.count("lo", "o")
    a.count("lo", "o", "o")
  end

  def test_crypt
    "foo".crypt("bar")
  end

  def test_delete
    "hello".delete("l", "lo")
    "hello".delete("lo")
  end

  def test_delete!
    "hello".delete!("l", "lo")
    "hello".delete!("lo")
    "hello".delete!("a")
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

  def test_downcase
    "a".downcase
    "a".downcase(:ascii)
    "a".downcase(:fold)
    "a".downcase(:lithuanian)
    "a".downcase(:turkic)
    "a".downcase(:lithuanian, :turkic)
    "a".downcase(:turkic, :lithuanian)
  end

  def test_downcase!
    "a".downcase!
    "a".downcase!(:ascii)
    "a".downcase!(:fold)
    "a".downcase!(:lithuanian)
    "a".downcase!(:turkic)
    "a".downcase!(:lithuanian, :turkic)
    "a".downcase!(:turkic, :lithuanian)
    "A".downcase!
    "A".downcase!(:ascii)
    "A".downcase!(:fold)
    "A".downcase!(:lithuanian)
    "A".downcase!(:turkic)
    "A".downcase!(:lithuanian, :turkic)
    "A".downcase!(:turkic, :lithuanian)
  end

  def test_dump
    "foo".dump
  end

  def test_each_byte
    "hello".each_byte
    "hello".each_byte { |c| c }
  end

  def test_each_char
    "hello".each_char
    "hello".each_char { |c| c }
  end

  def test_each_codepoint
    "hello".each_codepoint
    "hello".each_codepoint { |codepoint| codepoint }
  end

  def test_each_grapheme_cluster
    "test".each_grapheme_cluster
    "test".each_grapheme_cluster { |c| nil }
  end

  def test_each_line
    "hello".each_line
    "hello".each_line { |line| line }
    "hello".each_line('l')
    "hello".each_line('l') { |line| line }
    "hello".each_line(chomp: true)
    "hello".each_line(chomp: false)
    "hello".each_line(chomp: true) { |line| line }
    "hello".each_line(chomp: false) { |line| line }
    "hello".each_line('l', chomp: true)
    "hello".each_line('l', chomp: false)
    "hello".each_line('l', chomp: true) { |line| line }
    "hello".each_line('l', chomp: false) { |line| line }
  end

  def test_empty?
    "".empty?
    " ".empty?
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
    s.encode(xml: :attr)
    s.encode(fallback: proc { |s| s })
    s.encode(fallback: "test".method(:+))
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
    s.encode!(xml: :attr)
    s.encode!(fallback: proc { |s| s })
    s.encode!(fallback: "test".method(:+))
    s.encode!(cr_newline: true)
    s.encode!(crlf_newline: true)
  end

  def test_encoding
    "test".encoding
  end

  def test_end_with?
    s = "string"
    s.end_with?
    s.end_with?("string")
    s.end_with?("foo", "bar")
  end

  def test_eql?
    s = "string"
    s.eql?(s)
    s.eql?(42)
  end

  def test_force_encoding
    s = ""
    s.force_encoding "ASCII-8BIT"
    s.force_encoding Encoding::ASCII_8BIT
  end

  def test_freeze
    "test".freeze
  end

  def test_getbyte
    "a".getbyte(0)
    "a".getbyte(1)
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

  def test_gsub!
    s = "string"
    s.gsub!(/z/, "s")
    s.gsub!(/s/, "s")
    s.gsub!("z", "s")
    s.gsub!("s", "s")
    s.gsub!(/z/) {|x| "s" }
    s.gsub!(/s/) {|x| "s" }
    s.gsub!(/z/, {"z" => "s"})
    s.gsub!(/s/, {"s" => "s"})
    s.gsub!(/s/)
    s.gsub!("t")
  end

  def test_hash
    "".hash
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
