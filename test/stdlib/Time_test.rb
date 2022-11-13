require_relative "test_helper"

class TimeTest < StdlibTest
  target Time

  def test_class_method_at
    Time.at(100)
    Time.at(946684800, 123456.789)
  end

  def test_class_method_gm
    Time.gm(2000, "jan", 1, 20, 15, 1)
  end

  def test_class_method_local
    Time.local(1991, 2, 22)
  end

  def test_class_method_now
    Time.now
  end

  def test_class_method_utc
    Time.utc(2000, "jan", 1, 20, 15, 1)
  end

  def test_class_method_mktime
    Time.mktime(2000, "jan", 1, 20, 15, 1)
  end

  def test_spaceship
    Time.local(1991, 2, 22) <=> Time.local(2000, 2, 22)
  end

  def test_eql?
    Time.local(1991, 2, 22).eql?(Time.local(2000, 2, 22))
    Time.local(1991, 2, 22).eql?(Time.local(1991, 2, 22))
  end

  def test_hash
    Time.local(1991, 2, 22).hash
  end

  def test_inspect
    Time.local(1991, 2, 22).inspect
  end

  def test_to_s
    Time.local(1991, 2, 22).to_s
  end

  def test_less_than
    Time.local(1991, 2, 22) < Time.local(2000, 2, 22)
  end

  def test_less_than_equal_to
    Time.local(1991, 2, 22) <= Time.local(2000, 2, 22)
  end

  def test_greater_than
    Time.local(1991, 2, 22) > Time.local(2000, 2, 22)
  end

  def test_greater_than_equal_to
    Time.local(1991, 2, 22) >= Time.local(2000, 2, 22)
  end

  def test_plus
    Time.now + 3
  end

  def test_minus
    Time.now - 3
    Time.now - Time.local(2000, 1, 1)
  end

  def test_asctime
    Time.new.asctime
  end

  def test_ctime
    Time.new.ctime
  end

  def test_day
    Time.new.day
  end

  def test_dst?
    Time.new.dst?
  end

  def test_friday?
    Time.local(1991, 2, 22).friday?
  end

  def test_getgm
    Time.new.getgm
  end

  def test_getlocal
    Time.new.getlocal
  end

  def test_getutc
    Time.new.getutc
  end

  def test_gmt?
    Time.new.gmt?
  end

  def test_gmt_offset
    Time.new.gmt_offset
  end

  def test_gmtime
    Time.new.gmtime
  end

  def test_hour
    Time.new.hour
  end

  def test_isdst
    Time.local(2000, 1, 1).isdst
  end

  def test_localtime
    t = Time.utc(2000, "jan", 1, 20, 15, 1)
    t.localtime
  end

  def test_mday
    Time.new.mday
  end

  def test_min
    Time.new.min
  end

  def test_mon
    Time.new.mon
  end

  def test_monday?
    Time.local(2003, 8, 4).monday?
  end

  def test_nsec
    Time.new.nsec
  end

  def test_round
    Time.new(2010, 3, 30, 5, 43, 25).round
    Time.new(1999,12,31, 23,59,59).round(4)
  end

  def test_saturday?
    Time.local(1991, 2, 23).saturday?
  end

  def test_sec
    Time.new.sec
  end

  def test_strftime
    t = Time.new(2007, 11, 19, 8, 37, 48, "-06:00")
    t.strftime("%m/%d/%Y")
  end

  def test_subsec
    Time.new.subsec
  end

  def test_sunday?
    Time.local(1991, 2, 24).sunday?
  end

  def test_thursday?
    Time.local(1991, 2, 21).thursday?
  end

  def test_to_a
    Time.new.to_a
  end

  def test_to_f
    Time.new.to_f
  end

  def test_to_i
    Time.new.to_i
  end

  def test_to_r
    Time.new.to_r
  end

  def test_tuesday?
    Time.local(1991, 2, 19).tuesday?
  end

  def test_tv_nsec
    Time.new.tv_nsec
  end

  def test_tv_sec
    Time.new.tv_sec
  end

  def test_tv_usec
    Time.new.tv_usec
  end

  def test_usec
    Time.new.usec
  end

  def test_utc
    Time.new.utc
  end

  def test_utc?
    t = Time.utc(2000, "jan", 1, 20, 15, 1)
    t.utc?
  end

  def test_utc_offset
    Time.new.utc_offset
  end

  def test_wday
    Time.new.wday
  end

  def test_wednesday?
    Time.local(1991, 2, 20).wednesday?
  end

  def test_yday
    Time.new.yday
  end

  def test_year
    Time.new.year
  end

  def test_zone
    Time.new.zone
  end

  def test_gmtoff
    Time.new.gmtoff
  end

  def test_month
    Time.new.month
  end

  def test_floor
    Time.new.floor
    Time.new.floor(1)
  end

  def test_ceil
    Time.new.ceil
    Time.new.ceil(1)
  end
end

class TimeSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  testing "singleton(::Time)"

  def test_now
    assert_send_type(
      "() -> Time",
      Time, :now
    )
    assert_send_type(
      "(in: Integer) -> Time",
      Time, :now, in: 9*3600
    )
    assert_send_type(
      "(in: String) -> Time",
      Time, :now, in: "+09:00"
    )
    assert_send_type(
      "(in: nil) -> Time",
      Time, :now, in: nil
    )
  end

  def test_at
    assert_send_type(
      "(Time) -> Time",
      Time, :at, Time.now
    )
    assert_send_type(
      "(Time, in: String) -> Time",
      Time, :at, Time.now, in: "+09:00"
    )
    assert_send_type(
      "(Integer) -> Time",
      Time, :at, Time.now.to_i
    )
    assert_send_type(
      "(Integer, in: String) -> Time",
      Time, :at, Time.now.to_i, in: "+04:00"
    )
    assert_send_type(
      "(Integer, Integer, :millisecond, in: String) -> Time",
      Time, :at, Time.now.to_i, 100, :millisecond, in: "+04:00"
    )
  end

  def test_new
    assert_send_type(
      "() -> Time",
      Time, :new
    )
    assert_send_type(
      "(in: String) -> Time",
      Time, :new, in: "+08:00"
    )
    assert_send_type(
      "(Integer, Integer, Integer, Integer, Integer, Float, String) -> Time",
      Time, :new, 2022, 1, 3, 13, 22, 30.4, "Z"
    )
    assert_send_type(
      "(Integer, Integer, Integer, in: String) -> Time",
      Time, :new, 2022, 1, 3, in: "Z"
    )
  end
end

class TimeInDateTest < Test::Unit::TestCase
  include TypeAssertions

  require "date"

  library "date"
  testing "::Time"

  def test_to_time
    assert_send_type "() -> Time", Time.now, :to_time
  end

  def test_to_date
    assert_send_type "() -> Date", Time.now, :to_date
  end

  def test_to_datetime
    assert_send_type "() -> DateTime", Time.now, :to_datetime
  end
end
