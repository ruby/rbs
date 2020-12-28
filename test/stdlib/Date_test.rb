require_relative "test_helper"
require "date"

class DateSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "date"
  testing "singleton(::Date)"

  def test_new
    assert_send_type  "() -> ::Date",
                      Date, :new
    assert_send_type  "(::Integer year) -> ::Date",
                      Date, :new, 2020
    assert_send_type  "(::Integer year, ::Integer month) -> ::Date",
                      Date, :new, 2020, 8
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> ::Date",
                      Date, :new, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer start) -> ::Date",
                      Date, :new, 2020, 8, 15, Date::ITALY
  end

  def test__httpdate
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_httpdate, "Sat Aug 15 00:00:00 2020"
  end

  def test__iso8601
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_iso8601, "2020-08-15"
  end

  def test__jisx0301
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_jisx0301, "2020-08-15"
  end

  def test__parse
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_parse, "2020-08-15"
    assert_send_type  "(::String str, bool complete) -> ::Hash[Symbol, Integer]",
                      Date, :_parse, "2020-08-15", true
  end

  def test__rfc2822
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer | String]",
                      Date, :_rfc2822, "Sat Aug 15 2020 00:00:00 +09:00"
  end

  def test__rfc3339
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer | String]",
                      Date, :_rfc3339, "2020-08-15T00:00:00+09:00"
  end

  def test__rfc822
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer | String]",
                      Date, :_rfc822, "Sat Aug 15 2020 00:00:00 +09:00"
  end

  def test__strptime
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_strptime, "2020-08-15"
    assert_send_type  "(::String str, ::String format) -> ::Hash[Symbol, Integer]",
                      Date, :_strptime, "2020-08-15", "%Y-%M-%d"
  end

  def test__xmlschema
    assert_send_type  "(::String str) -> ::Hash[Symbol, Integer]",
                      Date, :_xmlschema, "2020-08-15"
  end

  def test_civil
    assert_send_type  "() -> ::Date",
                      Date, :civil
    assert_send_type  "(::Integer year) -> ::Date",
                      Date, :civil, 2020
    assert_send_type  "(::Integer year, ::Integer month) -> ::Date",
                      Date, :civil, 2020, 8
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> ::Date",
                      Date, :civil, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer start) -> ::Date",
                      Date, :civil, 2020, 8, 15, Date::ITALY
  end

  def test_commercial
    assert_send_type  "() -> ::Date",
                      Date, :commercial
    assert_send_type  "(::Integer year) -> ::Date",
                      Date, :commercial, 2020
    assert_send_type  "(::Integer year, ::Integer month) -> ::Date",
                      Date, :commercial, 2020, 1
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> ::Date",
                      Date, :commercial, 2020, 1, 1
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer start) -> ::Date",
                      Date, :commercial, 2020, 1, 1, Date::ITALY
  end

  def test_gregorian_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :gregorian_leap?, 2020
  end

  def test_httpdate
    assert_send_type  "(::String str) -> ::Date",
                      Date, :httpdate, "Sat Aug 15 00:00:00 2020"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :httpdate, "Sat Aug 15 00:00:00 2020", Date::ITALY
  end

  def test_iso8601
    assert_send_type  "(::String str) -> ::Date",
                      Date, :iso8601, "2020-08-15"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :iso8601, "2020-08-15", Date::ITALY
  end

  def test_jd
    assert_send_type  "(::Integer jd) -> ::Date",
                      Date, :jd, 2020
    assert_send_type  "(::Integer jd, ::Integer start) -> ::Date",
                      Date, :jd, 2020, Date::ITALY
  end

  def test_jisx0301
    assert_send_type  "(::String str) -> ::Date",
                      Date, :jisx0301, "2020-08-15"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :jisx0301, "2020-08-15", Date::ITALY
  end

  def test_julian_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :julian_leap?, 2020
  end

  def test_leap?
    assert_send_type  "(::Integer year) -> bool",
                      Date, :leap?, 2020
  end

  def test_ordinal
    assert_send_type  "() -> ::Date",
                      Date, :ordinal
    assert_send_type  "(::Integer year) -> ::Date",
                      Date, :ordinal, 2020
    assert_send_type  "(::Integer year, ::Integer yday) -> ::Date",
                      Date, :ordinal, 2020, 1
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer start) -> ::Date",
                      Date, :ordinal, 2020, 1, Date::ITALY
  end

  def test_parse
    assert_send_type  "(::String str) -> ::Date",
                      Date, :parse, "2020-08-15"
    assert_send_type  "(::String str, bool complete) -> ::Date",
                      Date, :parse, "2020-08-15", true
    assert_send_type  "(::String str, Symbol) -> ::Date",
                      Date, :parse, "2020-08-15", :true
    assert_send_type  "(::String str, bool complete, ::Integer start) -> ::Date",
                      Date, :parse, "2020-08-15", true, Date::ITALY
  end

  def test_rfc2822
    assert_send_type  "(::String str) -> ::Date",
                      Date, :rfc2822, "Sat, 15 Aug 2020 00:00:00 +0900"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :rfc2822, "Sat, 15 Aug 2020 00:00:00 +0900", Date::ITALY
  end

  def test_rfc3339
    assert_send_type  "(::String str) -> ::Date",
                      Date, :rfc3339, "2020-08-15T00:00:00+09:00"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :rfc3339, "2020-08-15T00:00:00+09:00", Date::ITALY
  end

  def test_rfc822
    assert_send_type  "(::String str) -> ::Date",
                      Date, :rfc822, "Sat, 15 Aug 2020 00:00:00 +0900"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :rfc822, "Sat, 15 Aug 2020 00:00:00 +0900", Date::ITALY
  end

  def test_strptime
    assert_send_type  "(::String str) -> ::Date",
                      Date, :strptime, "2020-08-15"
    assert_send_type  "(::String str, ::String format) -> ::Date",
                      Date, :strptime, "2020-08-15", "%Y-%M-%d"
    assert_send_type  "(::String str, ::String format, ::Integer start) -> ::Date",
                      Date, :strptime, "2020-08-15", "%Y-%M-%d", Date::ITALY
  end

  def test_today
    assert_send_type  "() -> ::Date",
                      Date, :today
    assert_send_type  "(::Integer start) -> ::Date",
                      Date, :today, Date::ITALY
  end

  def test_valid_civil?
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> bool",
                      Date, :valid_civil?, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer start) -> bool",
                      Date, :valid_civil?, 2020, 8, 15, Date::ITALY
  end

  def test_valid_commercial?
    assert_send_type  "(::Integer cwyear, ::Integer cweek, ::Integer cwday, ?::Integer start) -> bool",
                      Date, :valid_commercial?, 2020, 1, 1
  end

  def test_valid_date?
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday) -> bool",
                      Date, :valid_date?, 2020, 8, 15
    assert_send_type  "(::Integer year, ::Integer month, ::Integer mday, ::Integer start) -> bool",
                      Date, :valid_date?, 2020, 8, 15, Date::ITALY
  end

  def test_valid_jd?
    assert_send_type  "(::Integer jd) -> bool",
                      Date, :valid_jd?, 2020
    assert_send_type  "(::Integer jd, ::Integer start) -> bool",
                      Date, :valid_jd?, 2020, Date::ITALY
  end

  def test_valid_ordinal?
    assert_send_type  "(::Integer year, ::Integer yday) -> bool",
                      Date, :valid_ordinal?, 2020, 1
    assert_send_type  "(::Integer year, ::Integer yday, ::Integer start) -> bool",
                      Date, :valid_ordinal?, 2020, 1, Date::ITALY
  end

  def test_xmlschema
    assert_send_type  "(::String str) -> ::Date",
                      Date, :xmlschema, "2020-08-15"
    assert_send_type  "(::String str, ::Integer start) -> ::Date",
                      Date, :xmlschema, "2020-08-15", Date::ITALY
  end
end

class DateTest < Test::Unit::TestCase
  include TypeAssertions

  library "date"
  testing "::Date"

  def test_spaceship
    assert_send_type  "(::Date other) -> ::Integer",
                      Date.new, :<=>, Date.new(2020, 8, 15)
    assert_send_type  "(::Rational other) -> ::Integer",
                      Date.new, :<=>, Rational(1, 2)
    assert_send_type  "(::Object other) -> ::Integer?",
                      Date.new, :<=>, {}
  end

  def test_triple_equal
    assert_send_type  "(::Date other) -> bool",
                      Date.new, :===, Date.new
  end

  def test_plus
    assert_send_type  "(::Integer other) -> ::Date",
                      Date.new, :+, 1
    assert_send_type  "(::Rational other) -> ::Date",
                      Date.new, :+, Rational(1, 2)
  end

  def test_minus
    assert_send_type  "(::Integer) -> ::Date",
                      Date.new, :-, 1
    assert_send_type  "(::Rational other) -> ::Date",
                      Date.new, :-, Rational(1, 2)
    assert_send_type  "(::Date other) -> ::Rational",
                      Date.new, :-, Date.new
  end

  def test_left_shift
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :<<, 1
  end

  def test_right_shift
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :>>, 1
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

  def test_downto
    assert_send_type  "(::Date min) { (::Date) -> untyped } -> ::Date",
                      Date.new, :downto, Date.new do end
    assert_send_type  "(::Date min) -> ::Enumerator[::Date, ::Date]",
                      Date.new, :downto, Date.new
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

  def test_inspect
    assert_send_type  "() -> ::String",
                      Date.new, :inspect
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
    assert_send_type  "() -> ::Date",
                      Date.new, :new_start
    assert_send_type  "(::Integer start) -> ::Date",
                      Date.new, :new_start, Date::ITALY
  end

  def test_next
    assert_send_type  "() -> ::Date",
                      Date.new, :next
  end

  def test_next_day
    assert_send_type  "() -> ::Date",
                      Date.new, :next_day
    assert_send_type  "(::Integer day) -> ::Date",
                      Date.new, :next_day, 1
  end

  def test_next_month
    assert_send_type  "() -> ::Date",
                      Date.new, :next_month
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :next_month, 1
  end

  def test_next_year
    assert_send_type  "() -> ::Date",
                      Date.new, :next_year
    assert_send_type  "(::Integer year) -> ::Date",
                      Date.new, :next_year, 1
  end

  def test_prev_day
    assert_send_type  "() -> ::Date",
                      Date.new, :prev_day
    assert_send_type  "(::Integer day) -> ::Date",
                      Date.new, :prev_day, 1
  end

  def test_prev_month
    assert_send_type  "() -> ::Date",
                      Date.new, :prev_month
    assert_send_type  "(::Integer month) -> ::Date",
                      Date.new, :prev_month, 1
  end

  def test_prev_year
    assert_send_type  "() -> ::Date",
                      Date.new, :prev_year
    assert_send_type  "(::Integer year) -> ::Date",
                      Date.new, :prev_year, 1
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
    assert_send_type  "() -> ::Float",
                      Date.new, :start
  end

  def test_step
    assert_send_type  "(::Date limit) { (::Date) -> untyped } -> Date",
                      Date.new, :step, Date.new do end
    assert_send_type  "(::Date limit, ::Integer step) { (::Date) -> untyped } -> Date",
                      Date.new, :step, Date.new, 1 do end
    assert_send_type  "(::Date limit) -> ::Enumerator[::Date, ::Date]",
                      Date.new, :step, Date.new
    assert_send_type  "(::Date limit, ::Integer step) -> ::Enumerator[::Date, ::Date]",
                      Date.new, :step, Date.new, 1
  end

  def test_strftime
    assert_send_type  "() -> ::String",
                      Date.new, :strftime
    assert_send_type  "(::String format) -> ::String",
                      Date.new, :strftime, "%Y-%M"
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

  def test_to_s
    assert_send_type  "() -> ::String",
                      Date.new, :to_s
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
    assert_send_type  "(::Date max) { (::Date) -> untyped } -> Date",
                      Date.new, :upto, Date.new do end
    assert_send_type  "(::Date max) -> ::Enumerator[::Date, ::Date]",
                      Date.new, :upto, Date.new
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
