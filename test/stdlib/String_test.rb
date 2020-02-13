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

class StringInstanceTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "::String"

  def test_format_m
    assert_send_type "(Integer) -> String",
                     "%05d", :%, 123
    assert_send_type "(Array[String | Integer]) -> String",
                     "%-5s: %016x", :%, [ "ID", self.object_id ]
    assert_send_type "(Hash[Symbol, untyped]) -> String",
                     "foo = %{foo}", :%, { :foo => 'bar' }
  end

  def test_times
    assert_send_type "(Integer) -> String",
                     "Ho! ", :*, 3
    assert_send_type "(ToInt) -> String",
                     "Ho! ", :*, ToInt.new(0)
  end

  def test_plus
    assert_send_type "(String) -> String",
                     "Hello from ", :+, self.to_s
    assert_send_type "(ToStr) -> String",
                     "Hello from ", :+, ToStr.new(self.to_s)
  end

  def test_unary_plus
    assert_send_type "() -> String",
                     '', :+@
  end

  def test_unary_minus
    assert_send_type "() -> String",
                     '', :-@
  end

  def test_concat_op
    a = "hello "
    assert_send_type "(String) -> String",
                     a, :<<, "world"
    assert_send_type "(ToStr) -> String",
                     a, :<<, ToStr.new("world")
    assert_send_type "(Integer) -> String",
                     a, :<<, 33
  end

  def test_cmp
    assert_send_type "(String) -> Integer",
                     "abcdef", :<=>, "abcde"
    assert_send_type "(Integer) -> nil",
                     "abcdef", :<=>, 1
  end

  def test_eq
    assert_send_type "(String) -> true",
                     "a", :==, "a"
    assert_send_type "(nil) -> false",
                     "a", :==, nil
  end

  def test_eqq
    assert_send_type "(String) -> true",
                     "a", :===, "a"
    assert_send_type "(nil) -> false",
                     "a", :===, nil
  end

  def test_match_op
    assert_send_type "(Regexp) -> Integer",
                     "a", :=~, /a/
    assert_send_type "(nil) -> nil",
                     "a", :=~, nil
  end

  def test_aref
    assert_send_type "(Integer) -> String",
                     "a", :[], 0
    assert_send_type "(ToInt) -> String",
                     "a", :[], ToInt.new(0)
    assert_send_type "(Integer) -> nil",
                     "a", :[], 1
    assert_send_type "(ToInt) -> nil",
                     "a", :[], ToInt.new(1)
    assert_send_type "(Integer, Integer) -> String",
                     "a", :[], 0, 1
    assert_send_type "(Integer, Integer) -> nil",
                     "a", :[], 2, 1
    assert_send_type "(ToInt, ToInt) -> String",
                     "a", :[], ToInt.new(0), ToInt.new(1)
    assert_send_type "(ToInt, ToInt) -> nil",
                     "a", :[], ToInt.new(2), ToInt.new(1)
    assert_send_type "(Range[Integer]) -> String",
                     "a", :[], 0..1
    assert_send_type "(Range[Integer]) -> nil",
                     "a", :[], 2..1
    assert_send_type "(Range[Integer?]) -> String",
                     "a", :[], (0...)
    assert_send_type "(Range[Integer?]) -> nil",
                     "a", :[], (2...)
    if ::RUBY_27_OR_LATER
      eval(<<~RUBY)
        assert_send_type "(Range[Integer?]) -> String",
                         "a", :[], (...0)
      RUBY
    end
    assert_send_type "(Regexp) -> String",
                     "a", :[], /a/
    assert_send_type "(Regexp) -> nil",
                     "a", :[], /b/
    assert_send_type "(Regexp, Integer) -> String",
                     "a", :[], /a/, 0
    assert_send_type "(Regexp, Integer) -> nil",
                     "a", :[], /b/, 0
    assert_send_type "(Regexp, ToInt) -> String",
                     "a", :[], /a/, ToInt.new(0)
    assert_send_type "(Regexp, ToInt) -> nil",
                     "a", :[], /b/, ToInt.new(0)
    assert_send_type "(Regexp, String) -> String",
                     "a", :[], /(?<a>a)/, "a"
    assert_send_type "(Regexp, String) -> nil",
                     "a", :[], /(?<b>b)/, "b"
    assert_send_type "(String) -> String",
                     "a", :[], "a"
    assert_send_type "(String) -> nil",
                     "a", :[], "b"
  end

  def test_aset_m
    assert_send_type "(Integer, String) -> String",
                     "foo", :[]=, 0, "bar"
    assert_send_type "(ToInt, String) -> String",
                     "foo", :[]=, ToInt.new(0), "bar"
    assert_send_type "(Integer, Integer, String) -> String",
                     "foo", :[]=, 0, 3, "bar"
    assert_send_type "(ToInt, ToInt, String) -> String",
                     "foo", :[]=, ToInt.new(0), ToInt.new(3), "bar"
    assert_send_type "(Range[Integer], String) -> String",
                     "foo", :[]=, 0..3, "bar"
    assert_send_type "(Range[Integer?], String) -> String",
                    "foo", :[]=, (0..), "bar"
    assert_send_type "(Regexp, String) -> String",
                     "foo", :[]=, /foo/, "bar"
    assert_send_type "(Regexp, Integer, String) -> String",
                     "foo", :[]=, /(foo)/, 1, "bar"
    assert_send_type "(Regexp, ToInt, String) -> String",
                     "foo", :[]=, /(foo)/, ToInt.new(1), "bar"
    assert_send_type "(Regexp, String, String) -> String",
                     "foo", :[]=, /(?<foo>foo)/, "foo", "bar"
    assert_send_type "(String, String) -> String",
                     "foo", :[]=, "foo", "bar"
  end

  def test_ascii_only?
    assert_send_type "() -> true",
                     "abc".force_encoding("UTF-8"), :ascii_only?
    assert_send_type "() -> false",
                     "abc\u{6666}".force_encoding("UTF-8"), :ascii_only?
  end

  def test_b
    assert_send_type "() -> String",
                     "a", :b
  end

  def test_bytes
    assert_send_type "() -> Array[Integer]",
                     "a", :bytes
    assert_send_type "() { (Integer) -> void } -> String",
                     "a", :bytes do |b| b end
  end

  def test_bytesize
    assert_send_type "() -> Integer",
                     "string", :bytesize
  end

  def test_byteslice
    assert_send_type "(Integer) -> String",
                     "hello", :byteslice, 1
    assert_send_type "(ToInt) -> String",
                     "hello", :byteslice, ToInt.new(1)
    assert_send_type "(Integer) -> nil",
                     "hello", :byteslice, 10
    assert_send_type "(ToInt) -> nil",
                     "hello", :byteslice, ToInt.new(10)
    assert_send_type "(Integer, Integer) -> String",
                     "hello", :byteslice, 1, 2
    assert_send_type "(ToInt, ToInt) -> String",
                     "hello", :byteslice, ToInt.new(1), ToInt.new(2)
    assert_send_type "(Integer, Integer) -> nil",
                     "hello", :byteslice, 10, 2
    assert_send_type "(ToInt, ToInt) -> nil",
                     "hello", :byteslice, ToInt.new(10), ToInt.new(2)
    assert_send_type "(Range[Integer]) -> String",
                     "\x03\u3042\xff", :byteslice, 1..3
    assert_send_type "(Range[Integer?]) -> String",
                     "\x03\u3042\xff", :byteslice, (1..)
    assert_send_type "(Range[Integer]) -> nil",
                     "\x03\u3042\xff", :byteslice, 11..13
    assert_send_type "(Range[Integer?]) -> nil",
                     "\x03\u3042\xff", :byteslice, (11..)
  end

  def test_capitalize
    assert_send_type "() -> String",
                     "a", :capitalize
    assert_send_type "(:ascii) -> String",
                     "a", :capitalize, :ascii
    assert_send_type "(:lithuanian) -> String",
                     "a", :capitalize, :lithuanian
    assert_send_type "(:turkic) -> String",
                     "a", :capitalize, :turkic
    assert_send_type "(:lithuanian, :turkic) -> String",
                     "a", :capitalize, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> String",
                     "a", :capitalize, :turkic, :lithuanian
  end

  def test_capitalize!
    assert_send_type "() -> String",
                     "a", :capitalize!
    assert_send_type "(:ascii) -> String",
                     "a", :capitalize!, :ascii
    assert_send_type "(:lithuanian) -> String",
                     "a", :capitalize!, :lithuanian
    assert_send_type "(:turkic) -> String",
                     "a", :capitalize!, :turkic
    assert_send_type "(:lithuanian, :turkic) -> String",
                     "a", :capitalize!, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> String",
                     "a", :capitalize!, :turkic, :lithuanian
    assert_send_type "() -> nil",
                     "", :capitalize!
    assert_send_type "(:ascii) -> nil",
                     "", :capitalize!, :ascii
    assert_send_type "(:lithuanian) -> nil",
                     "", :capitalize!, :lithuanian
    assert_send_type "(:turkic) -> nil",
                     "", :capitalize!, :turkic
    assert_send_type "(:lithuanian, :turkic) -> nil",
                     "", :capitalize!, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> nil",
                     "", :capitalize!, :turkic, :lithuanian
  end

  def test_casecmp
    assert_send_type "(String) -> 0",
                     "a", :casecmp, "A"
    assert_send_type "(String) -> -1",
                     "a", :casecmp, "B"
    assert_send_type "(String) -> 1",
                     "b", :casecmp, "A"
    assert_send_type "(String) -> nil",
                     "\u{e4 f6 fc}".encode("ISO-8859-1"), :casecmp, "\u{c4 d6 dc}"
    assert_send_type "(Integer) -> nil",
                     "a", :casecmp , 42
  end

  def test_casecmp?
    assert_send_type "(String) -> false",
                     "aBcDeF", :casecmp?, "abcde"
    assert_send_type "(String) -> true",
                     "aBcDeF", :casecmp?, "abcdef"
    assert_send_type "(String) -> nil",
                     "\u{e4 f6 fc}".encode("ISO-8859-1"), :casecmp?, "\u{c4 d6 dc}"
    assert_send_type "(Integer) -> nil",
                     "foo", :casecmp?, 2
  end

  def test_center
    assert_send_type "(Integer) -> String",
                     "hello", :center, 4
    assert_send_type "(ToInt) -> String",
                     "hello", :center, ToInt.new(4)
    assert_send_type "(Integer, String) -> String",
                     "hello", :center, 20, '123'
    assert_send_type "(ToInt, ToStr) -> String",
                     "hello", :center, ToInt.new(20), ToStr.new('123')
  end

  def test_chars
    assert_send_type "() -> Array[String]",
                     "a", :chars
    assert_send_type "() { (String) -> void } -> String",
                     "a", :chars do |c| c end
  end

  def test_chomp
    assert_send_type "() -> String",
                     "a", :chomp
    assert_send_type "(String) -> String",
                     "a", :chomp, ""
    assert_send_type "(ToStr) -> String",
                     "a", :chomp, ToStr.new("")
  end

  def test_chomp!
    assert_send_type "() -> String",
                     "a\n", :chomp!
    assert_send_type "(String) -> String",
                     "a\n", :chomp!, "\n"
    assert_send_type "(String) -> nil",
                     "a\n", :chomp!, "\r"
    assert_send_type "(ToStr) -> String",
                     "a\n", :chomp!, ToStr.new("\n")
    assert_send_type "(ToStr) -> nil",
                     "a\n", :chomp!, ToStr.new("\r")
  end

  def test_chop
    assert_send_type "() -> String",
                     "a", :chop
  end

  def test_chop!
    assert_send_type "() -> String",
                     "a", :chop!
    assert_send_type "() -> nil",
                     "", :chop!
  end

  def test_chr
    assert_send_type "() -> String",
                     "a", :chr
  end

  def test_clear
    assert_send_type "() -> String",
                     "a", :clear
  end

  def test_codepoints
    assert_send_type "() -> Array[Integer]",
                     "a", :codepoints
    assert_send_type "() { (Integer) -> void } -> String",
                     "a", :codepoints do |cp| cp end
  end

  def test_concat
    assert_send_type "() -> String",
                     "hello", :concat
    assert_send_type "(String) -> String",
                     "hello", :concat, " "
    assert_send_type "(ToStr) -> String",
                     "hello", :concat, ToStr.new(" ")
    assert_send_type "(String, Integer) -> String",
                     "hello", :concat, "world", 33
  end

  def test_count
    assert_send_type "(String) -> Integer",
                     "hello world", :count, "lo"
    assert_send_type "(ToStr) -> Integer",
                     "hello world", :count, ToStr.new("lo")
    assert_send_type "(String, String) -> Integer",
                     "hello world", :count, "lo", "o"
    assert_send_type "(ToStr, ToStr) -> Integer",
                     "hello world", :count, ToStr.new("lo"), ToStr.new("o")
    assert_send_type "(String, String, String) -> Integer",
                     "hello world", :count, "lo", "o", "o"
    assert_send_type "(ToStr, ToStr, ToStr) -> Integer",
                     "hello world", :count, ToStr.new("lo"), ToStr.new("o"), ToStr.new("o")
  end

  def test_crypt
    assert_send_type "(String) -> String",
                     "foo", :crypt, "bar"
    assert_send_type "(ToStr) -> String",
                     "foo", :crypt, ToStr.new("bar")
  end

  def test_delete
    assert_send_type "(String, String) -> String",
                     "hello", :delete, "l", "lo"
    assert_send_type "(ToStr, ToStr) -> String",
                     "hello", :delete, ToStr.new("l"), ToStr.new("lo")
    assert_send_type "(String) -> String",
                     "hello", :delete, "lo"
    assert_send_type "(ToStr) -> String",
                     "hello", :delete, ToStr.new("lo")
  end

  def test_delete!
    assert_send_type "(String, String) -> String",
                     "hello", :delete!, "l", "lo"
    assert_send_type "(ToStr, ToStr) -> String",
                     "hello", :delete!, ToStr.new("l"), ToStr.new("lo")
    assert_send_type "(String) -> String",
                     "hello", :delete!, "lo"
    assert_send_type "(ToStr) -> String",
                     "hello", :delete!, ToStr.new("lo")
    assert_send_type "(String) -> nil",
                     "hello", :delete!, "a"
    assert_send_type "(ToStr) -> nil",
                     "hello", :delete!, ToStr.new("a")
  end

  def test_delete_prefix
    assert_send_type "(String) -> String",
                     "foo", :delete_prefix, "f"
    assert_send_type "(ToStr) -> String",
                     "foo", :delete_prefix, ToStr.new("f")
  end

  def test_delete_prefix!
    assert_send_type "(String) -> String",
                     "foo", :delete_prefix!, "f"
    assert_send_type "(ToStr) -> String",
                     "foo", :delete_prefix!, ToStr.new("f")
    assert_send_type "(String) -> nil",
                     "foo", :delete_prefix!, "a"
    assert_send_type "(ToStr) -> nil",
                     "foo", :delete_prefix!, ToStr.new("a")
  end

  def test_delete_suffix
    assert_send_type "(String) -> String",
                     "foo", :delete_suffix, "o"
    assert_send_type "(ToStr) -> String",
                     "foo", :delete_suffix, ToStr.new("o")
  end

  def test_delete_suffix!
    assert_send_type "(String) -> String",
                     "foo", :delete_suffix!, "o"
    assert_send_type "(ToStr) -> String",
                     "foo", :delete_suffix!, ToStr.new("o")
    assert_send_type "(String) -> nil",
                     "foo", :delete_suffix!, "a"
    assert_send_type "(ToStr) -> nil",
                     "foo", :delete_suffix!, ToStr.new("a")
  end

  def test_downcase
    assert_send_type "() -> String",
                     "a", :downcase
    assert_send_type "(:ascii) -> String",
                     "a", :downcase, :ascii
    assert_send_type "(:fold) -> String",
                     "a", :downcase, :fold
    assert_send_type "(:lithuanian) -> String",
                     "a", :downcase, :lithuanian
    assert_send_type "(:turkic) -> String",
                     "a", :downcase, :turkic
    assert_send_type "(:lithuanian, :turkic) -> String",
                     "a", :downcase, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> String",
                     "a", :downcase, :turkic, :lithuanian
  end

  def test_downcase!
    assert_send_type "() -> nil",
                     "a", :downcase!
    assert_send_type "(:ascii) -> nil",
                     "a", :downcase!, :ascii
    assert_send_type "(:fold) -> nil",
                     "a", :downcase!, :fold
    assert_send_type "(:lithuanian) -> nil",
                     "a", :downcase!, :lithuanian
    assert_send_type "(:turkic) -> nil",
                     "a", :downcase!, :turkic
    assert_send_type "(:lithuanian, :turkic) -> nil",
                     "a", :downcase!, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> nil",
                     "a", :downcase!, :turkic, :lithuanian
    assert_send_type "() -> String",
                     "A", :downcase!
    assert_send_type "(:ascii) -> String",
                     "A", :downcase!, :ascii
    assert_send_type "(:fold) -> String",
                     "A", :downcase!, :fold
    assert_send_type "(:lithuanian) -> String",
                     "A", :downcase!, :lithuanian
    assert_send_type "(:turkic) -> String",
                     "A", :downcase!, :turkic
    assert_send_type "(:lithuanian, :turkic) -> String",
                     "A", :downcase!, :lithuanian, :turkic
    assert_send_type "(:turkic, :lithuanian) -> String",
                     "A", :downcase!, :turkic, :lithuanian
  end

  def test_dump
    assert_send_type "() -> String",
                     "foo", :dump
  end

  def test_each_byte
    assert_send_type "() -> Enumerator[Integer, self]",
                     "hello", :each_byte
    assert_send_type "() { (Integer) -> void } -> self",
                     "hello", :each_byte do |c| c end
  end

  def test_each_char
    assert_send_type "() -> Enumerator[String, self]",
                     "hello", :each_char
    assert_send_type "() { (String) -> void } -> self",
                     "hello", :each_char do |c| c end
  end

  def test_each_codepoint
    assert_send_type "() -> Enumerator[Integer, self]",
                     "hello", :each_codepoint
    assert_send_type "() { (Integer) -> void } -> self",
                     "hello", :each_codepoint do |c| c end
  end

  def test_each_grapheme_cluster
    assert_send_type "() -> Enumerator[String, self]",
                     "hello", :each_grapheme_cluster
    assert_send_type "() { (String) -> void } -> self",
                     "hello", :each_grapheme_cluster do |c| c end
  end

  def test_each_line
    assert_send_type "() -> Enumerator[String, self]",
                     "hello", :each_line
    assert_send_type "() { (String) -> void } -> self",
                     "hello", :each_line do |line| line end
    assert_send_type "(String) -> Enumerator[String, self]",
                     "hello", :each_line, "l"
    assert_send_type "(ToStr) -> Enumerator[String, self]",
                     "hello", :each_line, ToStr.new("l")
    assert_send_type "(String) { (String) -> void } -> self",
                     "hello", :each_line, "l" do |line| line end
    assert_send_type "(ToStr) { (String) -> void } -> self",
                     "hello", :each_line, ToStr.new("l") do |line| line end
    assert_send_type "(chomp: true) -> Enumerator[String, self]",
                     "hello", :each_line, chomp: true
    assert_send_type "(chomp: false) -> Enumerator[String, self]",
                     "hello", :each_line, chomp: false
    assert_send_type "(chomp: true) { (String) -> void } -> self",
                     "hello", :each_line, chomp: true do |line| line end
    assert_send_type "(chomp: false){ (String)  -> void } -> self",
                     "hello", :each_line, chomp: false do |line| line end
    assert_send_type "(String, chomp: true) -> Enumerator[String, self]",
                     "hello", :each_line, "l", chomp: true
    assert_send_type "(ToStr, chomp: true) -> Enumerator[String, self]",
                     "hello", :each_line, ToStr.new("l"), chomp: true
    assert_send_type "(String, chomp: false) -> Enumerator[String, self]",
                     "hello", :each_line, "l", chomp: false
    assert_send_type "(ToStr, chomp: false) -> Enumerator[String, self]",
                     "hello", :each_line, ToStr.new("l"), chomp: false
    assert_send_type "(String, chomp: true) { (String) -> void } -> self",
                     "hello", :each_line, "l", chomp: true do |line| line end
    assert_send_type "(ToStr, chomp: true) { (String) -> void } -> self",
                     "hello", :each_line, ToStr.new("l"), chomp: true do |line| line end
    assert_send_type "(String, chomp: false) { (String) -> void } -> self",
                     "hello", :each_line, "l", chomp: false do |line| line end
    assert_send_type "(ToStr, chomp: false) { (String) -> void } -> self",
                     "hello", :each_line, ToStr.new("l"), chomp: false do |line| line end
  end

  def test_empty?
    assert_send_type "() -> true",
                     "", :empty?
    assert_send_type "() -> false",
                     " ", :empty?
  end

  def test_encode
    assert_send_type "(String) -> String",
                     "string", :encode, "ascii"
    assert_send_type "(String, Encoding) -> String",
                     "string", :encode, "ascii", Encoding::ASCII_8BIT
    assert_send_type "(Encoding, String) -> String",
                     "string", :encode, Encoding::ASCII_8BIT, "ascii"
    assert_send_type "(String, invalid: :replace) -> String",
                     "string", :encode, "ascii", invalid: :replace
    assert_send_type "(Encoding, Encoding, undef: nil) -> String",
                     "string", :encode, Encoding::ASCII_8BIT, Encoding::ASCII_8BIT, undef: nil
    assert_send_type "(invalid: nil, undef: :replace, replace: String, fallback: Hash[String, String], xml: :text, universal_newline: true) -> String",
                     "string", :encode,
                     invalid: nil,
                     undef: :replace,
                     replace: "foo",
                     fallback: {"a" => "a"},
                     xml: :text,
                     universal_newline: true
    assert_send_type "(xml: :attr) -> String",
                     "string", :encode, xml: :attr
    assert_send_type "(fallback: Proc) -> String",
                     "string", :encode, fallback: proc { |s| s }
    assert_send_type "(fallback: Method) -> String",
                     "string", :encode, fallback: "test".method(:+)
    assert_send_type "(cr_newline: true) -> String",
                     "string", :encode, cr_newline: true
    assert_send_type "(crlf_newline: true) -> String",
                     "string", :encode, crlf_newline: true
    assert_send_type "(ToStr, ToStr) -> String",
                     "string", :encode, ToStr.new("ascii"), ToStr.new("ascii")
  end

  def test_encode!
    assert_send_type "(String) -> self",
                     "string", :encode!, "ascii"
    assert_send_type "(String, Encoding) -> self",
                     "string", :encode!, "ascii", Encoding::ASCII_8BIT
    assert_send_type "(Encoding, String) -> self",
                     "string", :encode!, Encoding::ASCII_8BIT, "ascii"
    assert_send_type "(String, invalid: :replace) -> self",
                     "string", :encode!, "ascii", invalid: :replace
    assert_send_type "(Encoding, Encoding, undef: nil) -> self",
                     "string", :encode!, Encoding::ASCII_8BIT, Encoding::ASCII_8BIT, undef: nil
    assert_send_type "(invalid: nil, undef: :replace, replace: String, fallback: Hash[String, String], xml: :text, universal_newline: true) -> self",                 
                     "string", :encode!, 
                     invalid: nil,
                     undef: :replace,
                     replace: "foo",
                     fallback: {"a" => "a"},
                     xml: :text,
                     universal_newline: true
    assert_send_type "(xml: :attr) -> self",
                     "string", :encode!, xml: :attr
    assert_send_type "(fallback: Proc) -> self",
                     "string", :encode!, fallback: proc { |s| s }
    assert_send_type "(fallback: Method) -> self",
                     "string", :encode!, fallback: "test".method(:+)
    assert_send_type "(cr_newline: true) -> self",
                     "string", :encode!, cr_newline: true
    assert_send_type "(crlf_newline: true) -> self",
                     "string", :encode!, crlf_newline: true
    assert_send_type "(ToStr, ToStr) -> self",
                     "string", :encode!, ToStr.new("ascii"), ToStr.new("ascii")
  end

  def test_encoding
    assert_send_type "() -> Encoding",
                     "test", :encoding
  end
end

class StringTest < StdlibTest
  target String
  using hook.refinement

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
