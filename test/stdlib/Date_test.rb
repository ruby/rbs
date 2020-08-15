require_relative "test_helper"

class DateSingletonTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "singleton(::Date)"


  def test__httpdate
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_httpdate
  end

  def test__iso8601
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_iso8601
  end

  def test__jisx0301
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_jisx0301
  end

  def test__parse
    assert_send_type  "(::String str, ?bool complete) -> ::Hash",
                      Date, :_parse
  end

  def test__rfc2822
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_rfc2822
  end

  def test__rfc3339
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_rfc3339
  end

  def test__rfc822
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_rfc822
  end

  def test__strptime
    assert_send_type  "(::String str, ?::String format) -> ::Hash",
                      Date, :_strptime
  end

  def test__xmlschema
    assert_send_type  "(::String str) -> ::Hash",
                      Date, :_xmlschema
  end

  def test_civil
    assert_send_type  "(?::Integer year, ?::Integer month, ?::Integer mday, ?::Integer start) -> ::Date",
                      Date, :civil
  end

  def test_commercial
    assert_send_type  "(?::Integer cwyear, ?::Integer cweek, ?::Integer cwday, ?::Integer start) -> ::Date",
                      Date, :commercial
  end

  def test_gregorian_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :gregorian_leap?
  end

  def test_httpdate
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :httpdate
  end

  def test_iso8601
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :iso8601
  end

  def test_jd
    assert_send_type  "(::Integer jd, ?::Integer start) -> ::Date",
                      Date, :jd
  end

  def test_jisx0301
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :jisx0301
  end

  def test_julian_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :julian_leap?
  end

  def test_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :leap?
  end

  def test_ordinal
    assert_send_type  "(?::Integer year, ?::Integer yday, ?::Integer start) -> ::Date",
                      Date, :ordinal
  end

  def test_parse
    assert_send_type  "(::String str, ?bool complete, ?::Integer start) -> ::Date",
                      Date, :parse
  end

  def test_rfc2822
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :rfc2822
  end

  def test_rfc3339
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :rfc3339
  end

  def test_rfc822
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :rfc822
  end

  def test_strptime
    assert_send_type  "(::String str, ?::String format, ?::Integer start) -> ::Date",
                      Date, :strptime
  end

  def test_today
    assert_send_type  "(?::Integer start) -> ::Date",
                      Date, :today
  end

  def test_valid_civil?
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ?::Integer start) -> bool",
                      Date, :valid_civil?
  end

  def test_valid_commercial?
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ?::Integer start) -> bool",
                      Date, :valid_commercial?
  end

  def test_valid_date?
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ?::Integer start) -> bool",
                      Date, :valid_date?
  end

  def test_valid_jd?
    assert_send_type  "(::Integer jd, ?::Integer start) -> bool",
                      Date, :valid_jd?
  end

  def test_valid_ordinal?
    assert_send_type  "(::Integer year, ::Integer yday, ?::Integer start) -> bool",
                      Date, :valid_ordinal?
  end

  def test_xmlschema
    assert_send_type  "(::String str, ?::Integer start) -> ::Date",
                      Date, :xmlschema
  end
end

class DateTest < Minitest::Test
  include TypeAssertions

  # library "pathname", "set", "securerandom"     # Declare library signatures to load
  testing "::Date"


  def test_initialize
    assert_send_type  "(*untyped) -> untyped",
                      Date.new, :initialize
  end

  def test_spaceship
    assert_send_type  "(::Date | ::Rational | ::Object other) -> ::Integer?",
                      Date.new, :<=>
  end

  def test_triple_equal
    assert_send_type  "(::Date other) -> bool",
                      Date.new, :===
  end

  def test_inspect
    assert_send_type  "() -> ::String",
                      Date.new, :inspect
  end

  def test_to_s
    assert_send_type  "() -> ::String",
                      Date.new, :to_s
  end

  def test_plus
    assert_send_type  "(::Integer | ::Date | ::Rational arg0) -> ::Date",
                      Date.new, :+
  end

  def test_minus
    assert_send_type  "(::Integer | ::Date | ::Rational arg0) -> ::Date",
                      Date.new, :-
  end

  def test_left_shift
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :<<
  end

  def test_right_shift
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :>>
  end

  def test_ajd
    assert_send_type  "() -> ::Rational",
                      Date.new, :ajd
  end

  def test_amjd
    assert_send_type  "() -> ::Rational",
                      Date.new, :amjd
  end

  def test_asctime
    assert_send_type  "() -> ::String",
                      Date.new, :asctime
  end

  def test_ctime
    assert_send_type  "() -> ::String",
                      Date.new, :ctime
  end

  def test_cwday
    assert_send_type  "() -> ::Integer",
                      Date.new, :cwday
  end

  def test_cweek
    assert_send_type  "() -> ::Integer",
                      Date.new, :cweek
  end

  def test_cwyear
    assert_send_type  "() -> ::Integer",
                      Date.new, :cwyear
  end

  def test_day
    assert_send_type  "() -> ::Integer",
                      Date.new, :day
  end

  def test_day_fraction
    assert_send_type  "() -> ::Rational",
                      Date.new, :day_fraction
  end

  def test_downto
    assert_send_type  "(::Date min) { (::Date) -> untyped } -> nil",
                      Date.new, :downto
    assert_send_type  "(::Date min) -> ::Enumerator[::Date, nil]",
                      Date.new, :downto
  end

  def test_england
    assert_send_type  "() -> ::Date",
                      Date.new, :england
  end

  def test_friday?
    assert_send_type  "() -> bool",
                      Date.new, :friday?
  end

  def test_gregorian
    assert_send_type  "() -> ::Date",
                      Date.new, :gregorian
  end

  def test_gregorian?
    assert_send_type  "() -> bool",
                      Date.new, :gregorian?
  end

  def test_httpdate
    assert_send_type  "() -> ::String",
                      Date.new, :httpdate
  end

  def test_iso8601
    assert_send_type  "() -> ::String",
                      Date.new, :iso8601
  end

  def test_italy
    assert_send_type  "() -> ::Date",
                      Date.new, :italy
  end

  def test_jd
    assert_send_type  "() -> ::Integer",
                      Date.new, :jd
  end

  def test_jisx0301
    assert_send_type  "() -> ::String",
                      Date.new, :jisx0301
  end

  def test_julian
    assert_send_type  "() -> ::Date",
                      Date.new, :julian
  end

  def test_julian?
    assert_send_type  "() -> bool",
                      Date.new, :julian?
  end

  def test_ld
    assert_send_type  "() -> ::Integer",
                      Date.new, :ld
  end

  def test_leap?
    assert_send_type  "() -> bool",
                      Date.new, :leap?
  end

  def test_mday
    assert_send_type  "() -> ::Integer",
                      Date.new, :mday
  end

  def test_mjd
    assert_send_type  "() -> ::Integer",
                      Date.new, :mjd
  end

  def test_mon
    assert_send_type  "() -> ::Integer",
                      Date.new, :mon
  end

  def test_monday?
    assert_send_type  "() -> bool",
                      Date.new, :monday?
  end

  def test_month
    assert_send_type  "() -> ::Integer",
                      Date.new, :month
  end

  def test_new_start
    assert_send_type  "(?::Integer start) -> ::Date",
                      Date.new, :new_start
  end

  def test_next
    assert_send_type  "() -> ::Date",
                      Date.new, :next
  end

  def test_next_day
    assert_send_type  "(?::Integer day) -> ::Date",
                      Date.new, :next_day
  end

  def test_next_month
    assert_send_type  "(?::Integer month) -> ::Date",
                      Date.new, :next_month
  end

  def test_next_year
    assert_send_type  "(?::Integer year) -> ::Date",
                      Date.new, :next_year
  end

  def test_prev_day
    assert_send_type  "(?::Integer day) -> ::Date",
                      Date.new, :prev_day
  end

  def test_prev_month
    assert_send_type  "(?::Integer month) -> ::Date",
                      Date.new, :prev_month
  end

  def test_prev_year
    assert_send_type  "(?::Integer year) -> ::Date",
                      Date.new, :prev_year
  end

  def test_rfc2822
    assert_send_type  "() -> ::String",
                      Date.new, :rfc2822
  end

  def test_rfc3339
    assert_send_type  "() -> ::String",
                      Date.new, :rfc3339
  end

  def test_rfc822
    assert_send_type  "() -> ::String",
                      Date.new, :rfc822
  end

  def test_saturday?
    assert_send_type  "() -> bool",
                      Date.new, :saturday?
  end

  def test_start
    assert_send_type  "() -> ::Integer",
                      Date.new, :start
  end

  def test_step
    assert_send_type  "(::Date limit, ?::Integer step) { (::Date) -> untyped } -> nil",
                      Date.new, :step
    assert_send_type  "(::Date limit, ?::Integer step) -> ::Enumerator[::Date, nil]",
                      Date.new, :step
  end

  def test_strftime
    assert_send_type  "(?::String format) -> ::String",
                      Date.new, :strftime
  end

  def test_succ
    assert_send_type  "() -> ::Date",
                      Date.new, :succ
  end

  def test_sunday?
    assert_send_type  "() -> bool",
                      Date.new, :sunday?
  end

  def test_thursday?
    assert_send_type  "() -> bool",
                      Date.new, :thursday?
  end

  def test_to_date
    assert_send_type  "() -> ::Date",
                      Date.new, :to_date
  end

  def test_to_datetime
    assert_send_type  "() -> untyped",
                      Date.new, :to_datetime
  end

  def test_to_time
    assert_send_type  "() -> ::Time",
                      Date.new, :to_time
  end

  def test_tuesday?
    assert_send_type  "() -> bool",
                      Date.new, :tuesday?
  end

  def test_upto
    assert_send_type  "(::Date max) { (::Date) -> untypd } -> nil",
                      Date.new, :upto
    assert_send_type  "(::Date max) -> ::Enumerator[::Date, nil]",
                      Date.new, :upto
  end

  def test_wday
    assert_send_type  "() -> ::Integer",
                      Date.new, :wday
  end

  def test_wednesday?
    assert_send_type  "() -> bool",
                      Date.new, :wednesday?
  end

  def test_xmlschema
    assert_send_type  "() -> ::String",
                      Date.new, :xmlschema
  end

  def test_yday
    assert_send_type  "() -> ::Integer",
                      Date.new, :yday
  end

  def test_year
    assert_send_type  "() -> ::Integer",
                      Date.new, :year
  end
end
