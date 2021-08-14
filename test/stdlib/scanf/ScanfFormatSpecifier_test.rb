require_relative "../test_helper"
require "scanf"

class ScanfFormatSpecifierSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "scanf"
  testing "singleton(::Scanf::FormatSpecifier)"

  def test_new
    assert_send_type  "(String str) -> ::Scanf::FormatSpecifier",
                      ::Scanf::FormatSpecifier, :new, "%d"
  end
end

class ScanfFormatSpecifierInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "scanf"
  testing "::Scanf::FormatSpecifier"

  def test_conversion
    fs = ::Scanf::FormatSpecifier.new("%d")
    fs.match("1")

    assert_send_type  "() -> (Integer|String|nil)", fs, :conversion
  end

  def test_letter
    assert_send_type  "() -> String?",
                      ::Scanf::FormatSpecifier.new("%s"), :letter
  end

  def test_match
    assert_send_type  "(String str) -> MatchData?",
                      ::Scanf::FormatSpecifier.new("%s"), :match, "haystack"
  end

  def test_matched
    fs = ::Scanf::FormatSpecifier.new("%d")
    fs.match("1")

    assert_send_type  "() -> (bool|nil)", fs, :matched
  end

  def test_matched_string
    assert_send_type  "() -> String?",
                      ::Scanf::FormatSpecifier.new("%d"), :matched_string
  end

  def test_mid_match?
    assert_send_type  "() -> String",
                      ::Scanf::FormatSpecifier.new("%d"), :re_string
  end

  def test_re_string
    assert_send_type  "() -> String",
                      ::Scanf::FormatSpecifier.new("%d"), :re_string
  end

  def test_to_re
    assert_send_type  "() -> Regexp",
                      ::Scanf::FormatSpecifier.new("%d"), :to_re
  end

  def test_to_s
    assert_send_type  "() -> String",
                      ::Scanf::FormatSpecifier.new("%d"), :to_s
  end

  def test_width
    assert_send_type  "() -> Integer?",
                      ::Scanf::FormatSpecifier.new("%d"), :width
  end
end


