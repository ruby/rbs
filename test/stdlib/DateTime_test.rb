require_relative "test_helper"

class DateTimeSingletonTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "singleton(::DateTime)"


  def test_new
    assert_send_type  "(?::Integer year, ?::Integer month, ?::Integer mday, ?::Integer hour, ?::Integer minute, ?::Integer second, ?::Integer offset, ?::Integer start) -> ::DateTime",
                      DateTime, :new
  end

  def test__strptime
    assert_send_type  "(::String str, ?::String format) -> ::Hash",
                      DateTime, :_strptime
  end

  def test_civil
    assert_send_type  "(?::Integer year, ?::Integer month, ?::Integer mday, ?::Integer hour, ?::Integer minute, ?::Integer second, ?::Integer offset, ?::Integer start) -> ::DateTime",
                      DateTime, :civil
  end

  def test_commercial
    assert_send_type  "(?::Integer cwyear, ?::Integer cweek, ?::Integer cwday, ?::Integer hour, ?::Integer minute, ?::Integer second, ?::Integer offset, ?::Integer start) -> ::DateTime",
                      DateTime, :commercial
  end

  def test_httpdate
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :httpdate
  end

  def test_iso8601
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :iso8601
  end

  def test_jd
    assert_send_type  "(?::Integer jd, ?::Integer hour, ?::Integer minute, ?::Integer second, ?::Integer offset, ?::Integer start) -> ::DateTime",
                      DateTime, :jd
  end

  def test_jisx0301
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :jisx0301
  end

  def test_ordinal
    assert_send_type  "(?::Integer year, ?::Integer yday, ?::Integer hour, ?::Integer minute, ?::Integer second, ?::Integer offset, ?::Integer start) -> ::DateTime",
                      DateTime, :ordinal
  end

  def test_parse
    assert_send_type  "(::String str, ?bool complete, ?::Integer start) -> ::DateTime",
                      DateTime, :parse
  end

  def test_rfc2822
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :rfc2822
  end

  def test_rfc3339
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :rfc3339
  end

  def test_rfc822
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :rfc822
  end

  def test_strptime
    assert_send_type  "(::String str, ?::String format, ?::Integer start) -> ::DateTime",
                      DateTime, :strptime
  end

  def test_xmlschema
    assert_send_type  "(::String str, ?::Integer start) -> ::DateTime",
                      DateTime, :xmlschema
  end

  def test_now
    assert_send_type  "(?::Integer start) -> ::DateTime",
                      DateTime, :now
  end
end

class DateTimeTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::DateTime"


  def test_to_s
    assert_send_type  "() -> ::String",
                      DateTime.new, :to_s
  end

  def test_iso8601
    assert_send_type  "(?::Integer n) -> ::String",
                      DateTime.new, :iso8601
  end

  def test_jisx0301
    assert_send_type  "(?::Integer n) -> ::String",
                      DateTime.new, :jisx0301
  end

  def test_rfc3339
    assert_send_type  "(?::Integer n) -> ::String",
                      DateTime.new, :rfc3339
  end

  def test_strftime
    assert_send_type  "(?::String format) -> ::String",
                      DateTime.new, :strftime
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
    assert_send_type  "(?::Integer n) -> ::String",
                      DateTime.new, :xmlschema
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
    assert_send_type  "(?::String offset) -> ::DateTime",
                      DateTime.new, :new_offset
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
