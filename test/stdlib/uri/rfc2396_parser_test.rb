require_relative "../test_helper"
require "uri"

class URIRFC2396_ParserSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "uri"
  testing "singleton(::URI::RFC2396_Parser)"

  def test_new
    assert_send_type  "() -> URI::RFC2396_Parser",
                      URI::RFC2396_Parser, :new
  end
end

class URIRFC2396_ParserInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "uri"
  testing "::URI::RFC2396_Parser"

  def setup
    @instance = URI::RFC2396_Parser.new
  end

  def test_pattern
    assert_send_type  "() -> Hash[Symbol, String]",
                      @instance, :pattern
  end

  def test_regexp
    assert_send_type  "() -> Hash[Symbol, Regexp]",
                      @instance, :regexp
  end

  def test_escape
    assert_send_type  "(String) -> String",
                      @instance, :escape, "foo"
    assert_send_type  "(String, Regexp) -> String",
                      @instance, :escape, "foo", /bar/
  end

  def test_extract
    assert_send_type  "(String) -> Array[String]",
                      @instance, :extract, "foo"
    assert_send_type  "(String, Array[String]) -> Array[String]",
                      @instance, :extract, "foo", ["http", "https"]
    assert_send_type  "(String) { (String) -> untyped } -> nil",
                      @instance, :extract, "foo" do |s| s.bytes end
    assert_send_type  "(String, Array[String]) { (String) -> untyped } -> nil",
                      @instance, :extract, "foo", ["http", "https"] do |s| s.bytes end
  end

  def test_join
    assert_send_type  "(String, String) -> URI::HTTPS",
                      @instance, :join, "https://github.com", "ruby/rbs"
  end

  def test_make_regexp
    assert_send_type  "(Array[String]) -> Regexp",
                      @instance, :make_regexp, ["http", "https"]
  end

  def test_parse
    assert_send_type  "(String) -> URI::HTTPS",
                      @instance, :parse, "https://github.com/ruby/rbs"
  end

  def test_split
    assert_send_type  "(String) -> [String, String, String, String, nil, String, nil, nil, String]",
                      @instance, :split, "https://user@github.com:443/ruby/rbs#readme"
  end

  def test_unescape
    assert_send_type  "(String) -> String",
                      @instance, :unescape, "foo"
    assert_send_type  "(String, Regexp) -> String",
                      @instance, :unescape, "foo", /bar/
  end
end
