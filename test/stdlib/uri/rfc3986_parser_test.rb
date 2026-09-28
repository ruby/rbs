require_relative '../test_helper'
require 'uri'

class URIRFC3986_ParserSingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'uri'
  testing 'singleton(::URI::RFC3986_Parser)'

  def test_new
    assert_send_type '() -> URI::RFC3986_Parser',
                      URI::RFC3986_Parser, :new
  end
end

class URIRFC3986_ParserInstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'uri'
  testing '::URI::RFC3986_Parser'

  def test_regexp
    parser = URI::RFC3986_Parser.new
    assert_send_type '() -> Hash[Symbol, Regexp]',
                      parser, :regexp
  end

  def test_escape
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String) -> String',
                      parser, :escape, 'foo'
    assert_send_type '(String, Regexp) -> String',
                      parser, :escape, 'foo', /bar/
  end

  def test_extract
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String) -> Array[String]',
                      parser, :extract, 'foo'
    assert_send_type '(String, Array[String]) -> Array[String]',
                      parser, :extract, 'foo', ['http', 'https']
    assert_send_type '(String) { (String) -> untyped } -> nil',
                      parser, :extract, 'foo' do |s| s.bytes end
    assert_send_type '(String, Array[String]) { (String) -> untyped } -> nil',
                      parser, :extract, 'foo', ['http', 'https'] do |s| s.bytes end
  end

  def test_join
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String, String) -> URI::Generic',
                      parser, :join, 'https://github.com', 'ruby/rbs'
  end

  def test_make_regexp
    parser = URI::RFC3986_Parser.new
    assert_send_type '() -> Regexp',
                      parser, :make_regexp
    assert_send_type '(Array[String]) -> Regexp',
                      parser, :make_regexp, ['http', 'https']
  end

  def test_parse
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String) -> URI::Generic',
                      parser, :parse, 'https://github.com'
  end

  def test_split
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String) -> [String?, String?, String?, String?, String?, String?, String?, String?, String?]',
                      parser, :split, 'https://github.com'
  end

  def test_unescape
    parser = URI::RFC3986_Parser.new
    assert_send_type '(String) -> String',
                      parser, :unescape, 'foo'
    assert_send_type '(String, Regexp) -> String',
                      parser, :unescape, 'foo', /bar/
  end
end
