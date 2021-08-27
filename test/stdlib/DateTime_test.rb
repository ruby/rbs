require_relative "test_helper"
require "date"

class DateTimeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "date"
  testing "singleton(::DateTime)"

  def test_new
    assert_send_type  "() -> ::DateTime",
                      DateTime, :new
    assert_send_type  "(::Integer year) -> ::DateTime",
                      DateTime, :new, 2020
    assert_send_type  "(::Integer year, ::Integer month) -> ::DateTime",
                      DateTime, :new, 2020, 8
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15, 2, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15, 2, 2, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15, 2, 2, 2, 1
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset, ::Integer start) -> ::DateTime",
                      DateTime, :new, 2020, 8, 15, 2, 2, 2, 1, Date::ITALY
  end

  def test__strptime
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer | String]",
                      DateTime, :_strptime, "2020-08-15T00:00:00Z"
    assert_send_type  "(::String str, ::String format) -> ::Hash[Symbol, Integer | String]",
                      DateTime, :_strptime, "2020-08-15T00:00:00Z", "%Y-%M-%d"
  end

  def test_civil
    assert_send_type  "() -> ::DateTime",
                      DateTime, :civil
    assert_send_type  "(::Integer year) -> ::DateTime",
                      DateTime, :civil, 2020
    assert_send_type  "(::Integer year, ::Integer month) -> ::DateTime",
                      DateTime, :civil, 2020, 8
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15, 2, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15, 2, 2, 2
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15, 2, 2, 2, 1
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset, ::Integer start) -> ::DateTime",
                      DateTime, :civil, 2020, 8, 15, 2, 2, 2, 1, Date::ITALY
  end

  def test_commercial
    assert_send_type  "() -> ::DateTime",
                      DateTime, :commercial
    assert_send_type  "(::Integer cwyear) -> ::DateTime",
                      DateTime, :commercial, 2020
    assert_send_type  "(::Integer cwyear, ::Integer cweek) -> ::DateTime",
                      DateTime, :commercial, 2020, 1
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ::Integer hour) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1, 2
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ::Integer hour, ::Integer minute) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1, 2, 2
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ::Integer hour, ::Integer minute, ::Integer second) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1, 2, 2, 2
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1, 2, 2, 2, 3
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset, ::Integer start) -> ::DateTime",
                      DateTime, :commercial, 2020, 1, 1, 2, 2, 2, 3, Date::ITALY
  end

  def test_httpdate
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :httpdate, "Sat Aug 15 00:00:00 2020"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :httpdate, "Sat Aug 15 00:00:00 2020", Date::ITALY
  end

  def test_iso8601
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :iso8601, "2020-08-15T00:00:00+0900"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :iso8601, "2020-08-15T00:00:00+0900", Date::ITALY
  end

  def test_jd
    assert_send_type  "() -> ::DateTime",
                      DateTime, :jd
    assert_send_type  "(::Integer jd) -> ::DateTime",
                      DateTime, :jd, 2020
    assert_send_type  "(::Integer jd, ::Integer hour) -> ::DateTime",
                      DateTime, :jd, 2020, 1
    assert_send_type  "(::Integer jd, ::Integer hour, ::Integer minute) -> ::DateTime",
                      DateTime, :jd, 2020, 1, 1
    assert_send_type  "(::Integer jd, ::Integer hour, ::Integer minute, ::Integer second) -> ::DateTime",
                      DateTime, :jd, 2020, 1, 1, 1
    assert_send_type  "(::Integer jd, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset) -> ::DateTime",
                      DateTime, :jd, 2020, 1, 1, 1, 2
    assert_send_type  "(::Integer jd, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset, ::Integer start) -> ::DateTime",
                      DateTime, :jd, 2020, 1, 1, 1, 2, Date::ITALY
  end

  def test_jisx0301
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :jisx0301, "2020-08-15T00:00:00+0900"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :jisx0301, "2020-08-15T00:00:00+0900", Date::ITALY
  end

  def test_ordinal
    assert_send_type  "() -> ::DateTime",
                      DateTime, :ordinal
    assert_send_type  "(::Integer year) -> ::DateTime",
                      DateTime, :ordinal, 2020
    assert_send_type  "(::Integer year, ::Integer yday) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer hour) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1, 2
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer hour, ::Integer minute) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1, 2, 2
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer hour, ::Integer minute, ::Integer second) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1, 2, 2, 2
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1, 2, 2, 2, 3
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer hour, ::Integer minute, ::Integer second, ::Integer offset, ::Integer start) -> ::DateTime",
                      DateTime, :ordinal, 2020, 1, 2, 2, 2, 3, Date::ITALY
  end

  def test_parse
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :parse, "2020-08-15T00:00:00+0900"
    assert_send_type  "(::String str, bool complete) -> ::DateTime",
                      DateTime, :parse, "2020-08-15T00:00:00+0900", true
    assert_send_type  "(::String str, Symbol complete) -> ::DateTime",
                      DateTime, :parse, "2020-08-15T00:00:00+0900", :true
    assert_send_type  "(::String str, bool complete, ::Integer start) -> ::DateTime",
                      DateTime, :parse, "2020-08-15T00:00:00+0900", true, Date::ITALY
  end

  def test_rfc2822
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :rfc2822, "Sat, 15 Aug 2020 00:00:00 +0900"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :rfc2822, "Sat, 15 Aug 2020 00:00:00 +0900", Date::ITALY
  end

  def test_rfc3339
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :rfc3339, "2020-08-15T00:00:00+09:00"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :rfc3339, "2020-08-15T00:00:00+09:00", Date::ITALY
  end

  def test_rfc822
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :rfc822, "Sat, 15 Aug 2020 00:00:00 +0900"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :rfc822, "Sat, 15 Aug 2020 00:00:00 +0900", Date::ITALY
  end

  def test_strptime
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :strptime, "2020-08-15T00:00:00+09:00"
    assert_send_type  "(::String str, ::String format) -> ::DateTime",
                      DateTime, :strptime, "2020-08-15T00:00:00+09:00", "%Y-%M-%d"
    assert_send_type  "(::String str, ::String format, ::Integer start) -> ::DateTime",
                      DateTime, :strptime, "2020-08-15T00:00:00+09:00", "%Y-%M-%d", Date::ITALY
  end

  def test_xmlschema
    assert_send_type  "(::String str) -> ::DateTime",
                      DateTime, :xmlschema, "2020-08-15T00:00:00+09:00"
    assert_send_type  "(::String str, ::Integer start) -> ::DateTime",
                      DateTime, :xmlschema, "2020-08-15T00:00:00+09:00", Date::ITALY
  end

  def test_now
    assert_send_type  "() -> ::DateTime",
                      DateTime, :now
    assert_send_type  "(::Integer start) -> ::DateTime",
                      DateTime, :now, Date::ITALY
  end
end

class DateTimeTest < Test::Unit::TestCase
  include TypeAssertions

  library "date"
  testing "::DateTime"

  def test_to_s
    assert_send_type  "() -> ::String",
                      DateTime.new, :to_s
  end

  def test_iso8601
    assert_send_type  "() -> ::String",
                      DateTime.new, :iso8601
    assert_send_type  "(::Integer n) -> ::String",
                      DateTime.new, :iso8601, 1
  end

  def test_jisx0301
    assert_send_type  "() -> ::String",
                      DateTime.new, :jisx0301
    assert_send_type  "(::Integer n) -> ::String",
                      DateTime.new, :jisx0301, 1
  end

  def test_rfc3339
    assert_send_type  "() -> ::String",
                      DateTime.new, :rfc3339
    assert_send_type  "(::Integer n) -> ::String",
                      DateTime.new, :rfc3339, 1
  end

  def test_strftime
    assert_send_type  "() -> ::String",
                      DateTime.new, :strftime
    assert_send_type  "(::String format) -> ::String",
                      DateTime.new, :strftime, "%Y-%M-%d"
  end

  def test_to_date
    assert_send_type  "() -> ::Date",
                      DateTime.new, :to_date
  end

  def test_to_datetime
    assert_send_type  "() -> ::DateTime",
                      DateTime.new, :to_datetime
  end

  def test_to_time
    assert_send_type  "() -> ::Time",
                      DateTime.new, :to_time
  end

  def test_xmlschema
    assert_send_type  "() -> ::String",
                      DateTime.new, :xmlschema
    assert_send_type  "(::Integer n) -> ::String",
                      DateTime.new, :xmlschema, 1
  end

  def test_hour
    assert_send_type  "() -> ::Integer",
                      DateTime.new, :hour
  end

  def test_min
    assert_send_type  "() -> ::Integer",
                      DateTime.new, :min
  end

  def test_minute
    assert_send_type  "() -> ::Integer",
                      DateTime.new, :minute
  end

  def test_new_offset
    assert_send_type  "() -> ::DateTime",
                      DateTime.new, :new_offset
    assert_send_type  "(::String offset) -> ::DateTime",
                      DateTime.new, :new_offset, "+09:00"
  end

  def test_offset
    assert_send_type  "() -> ::Rational",
                      DateTime.new, :offset
  end

  def test_sec
    assert_send_type  "() -> ::Integer",
                      DateTime.new, :sec
  end

  def test_sec_fraction
    assert_send_type  "() -> ::Rational",
                      DateTime.new, :sec_fraction
  end

  def test_second
    assert_send_type  "() -> ::Integer",
                      DateTime.new, :second
  end

  def test_second_fraction
    assert_send_type  "() -> ::Rational",
                      DateTime.new, :second_fraction
  end

  def test_zone
    assert_send_type  "() -> ::String",
                      DateTime.new, :zone
  end
end
