require_relative "test_helper"
require "uri"

class URISingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "uri"
  testing "singleton(::URI)"

  def test_decode_www_form
    assert_send_type "(String) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&a=2&b=3"
    assert_send_type "(String, isindex: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "isindex&a=1", isindex: true
    assert_send_type "(String, use__charset_: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF&_charset_=sjis", use__charset_: true
    assert_send_type "(String, separator: String) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1;a=2;b=3", separator: ";"

    assert_send_type "(String, Encoding) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", Encoding::SJIS
    assert_send_type "(String, Encoding, isindex: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", Encoding::SJIS, isindex: true
    assert_send_type "(String, Encoding, use__charset_: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", Encoding::SJIS, use__charset_: true
    assert_send_type "(String, Encoding, separator: String) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", Encoding::SJIS, separator: ";"

    assert_send_type "(String, String) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", "sjis"
    assert_send_type "(String, String, isindex: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", "sjis", isindex: true
    assert_send_type "(String, String, use__charset_: bool) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", "sjis", use__charset_: true
    assert_send_type "(String, String, separator: String) -> Array[[String, String]]",
                     URI, :decode_www_form, "a=1&%82%A0=%8A%BF", "sjis", separator: ";"
  end

  def test_decode_www_form_component
    assert_send_type "(String) -> String",
                     URI, :decode_www_form_component, "%A1"
    assert_send_type "(String, Encoding) -> String",
                     URI, :decode_www_form_component, "%A1", Encoding::SJIS
    assert_send_type "(String, String) -> String",
                     URI, :decode_www_form_component, "%A1", "sjis"
  end

  def test_encode_www_form
    assert_send_type "(Array[[String, String | Numeric]]) -> String",
                     URI, :encode_www_form, [["a", "1"], ["a", 2], ["b", "3"]]
    assert_send_type "(Hash[interned, String | Numeric]) -> String",
                     URI, :encode_www_form, { a: "1", "b" => 2 }
  end

  def test_encode_www_form_component
    assert_send_type "(String) -> String",
                     URI, :encode_www_form_component, "\u3042"
    assert_send_type "(String, Encoding) -> String",
                     URI, :encode_www_form_component, "\u3042", Encoding::SJIS
    assert_send_type "(String, String) -> String",
                     URI, :encode_www_form_component, "\u3042", "sjis"
  end

  def test_extract
    assert_send_type "(String) -> Array[String]",
                     URI, :extract, "http://example.com"
    assert_send_type "(String, Array[String]) -> Array[String]",
                     URI, :extract, "http://example.com", ["http"]
    assert_send_type "(String) { (String) -> top } -> nil",
                     URI, :extract, "http://example.com" do |uri| uri.ascii_only? end
    assert_send_type "(String, Array[String]) { (String) -> top } -> nil",
                     URI, :extract, "http://example.com", ["http"] do |uri| uri.ascii_only? end
  end

  def test_get_encoding
    assert_send_type "(String) -> Encoding",
                     URI, :get_encoding, "utf-8"
    assert_send_type "(String) -> nil",
                     URI, :get_encoding, "foo"
  end

  def test_join
    assert_send_type "(String) -> URI::Generic",
                     URI, :join, "http://example.com"
    assert_send_type "(String, String) -> URI::Generic",
                     URI, :join, "http://example.com", "foo"
    assert_send_type "(URI::Generic, URI::Generic) -> URI::Generic",
                     URI, :join, URI("http://example.com"), URI("foo")
  end

  def test_parse
    assert_send_type "(String) -> URI::Generic",
                     URI, :parse, "http://example.com"
  end

  def test_regexp
    assert_send_type "() -> Regexp",
                     URI, :regexp
    assert_send_type "(Array[String]) -> Regexp",
                     URI, :regexp, ["http"]
  end

  def test_scheme_list
    assert_send_type "() -> Hash[String, Class]",
                     URI, :scheme_list
  end

  def test_split
    assert_send_type "(String) -> [String, nil, String, String, nil, String, nil, nil, String]",
                     URI, :split, "http://example.com:80/#id-1"
  end

  def test_kernel
    assert_send_type "(URI::Generic) -> URI::Generic",
                     Kernel, :URI, URI.parse("http://example.com")
    assert_send_type "(String) -> URI::Generic",
                     Kernel, :URI, "http://example.com"
  end
end

class URIInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "uri"
  testing "::URI::Generic"

  def test_fragment
    uri = URI.parse("https://example.com")

    assert_send_type(
      "() -> nil",
      uri, :fragment
    )

    assert_send_type(
      "(String) -> String",
      uri, :fragment=, "foo"
    )

    assert_send_type(
      "() -> String",
      uri, :fragment
    )
  end
end
