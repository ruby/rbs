require_relative "../test_helper"
require "scanf"

class ScanfFormatStringSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "scanf"
  testing "singleton(::Scanf::FormatString)"

  def test_new
    assert_send_type  "(String str) -> ::Scanf::FormatString",
                      ::Scanf::FormatString, :new, "%d"
  end
end

class ScanfFormatStringInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "scanf"
  testing "::Scanf::FormatString"

  def test_last_match_tried
    assert_send_type "() -> MatchData?",
                     ::Scanf::FormatString.new("%d"), :last_match_tried
  end

  def test_last_spec
    assert_send_type "() -> bool",
                    ::Scanf::FormatString.new("%d"), :last_spec
  end

  def test_last_spec_tried
    fs = ::Scanf::FormatString.new("%d")
    fs.match("123abc")

    assert_send_type "() -> Scanf::FormatSpecifier?",
                     fs, :last_spec_tried
  end

  def test_match
    assert_send_type "(String str) -> Array[String|Integer]",
                     ::Scanf::FormatString.new("%d%s"), :match, ""
    assert_send_type "(String str) -> Array[String|Integer]",
                     ::Scanf::FormatString.new("%d%s"), :match, "1234abc"
  end

  def test_match_count
    fs = ::Scanf::FormatString.new("%d")
    assert_send_type "() -> Integer?", fs, :matched_count

    fs.match("%d")
    assert_send_type "() -> Integer?", fs, :matched_count
  end

  def test_prune
    assert_send_type "(?Integer n) -> void",
                     ::Scanf::FormatString.new("%d%s"), :prune, 1
  end

  def test_space
    assert_send_type "() -> bool?",
                     ::Scanf::FormatString.new("%d%s "), :space
  end

  def test_spec_count
    assert_send_type "() -> Integer",
                     ::Scanf::FormatString.new("%d%s "), :spec_count
  end
  j
  def test_string_left
    fs = ::Scanf::FormatString.new("%d")
    fs.match("123abc")

    assert_send_type "() -> String?", fs, :string_left
  end

  def test_to_s
    assert_send_type "() -> String",
                     ::Scanf::FormatString.new("%d%s "), :to_s
  end
end


