require_relative "test_helper"
require "time"

class TimeExtensionSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "time"
  testing "singleton(::Time)"

  class MyDate
    attr_reader :mon, :day, :year

    def initialize(mon, day, year)
      @mon, @day, @year = mon, day, year
    end
  end

  def test_zone_offset
    assert_send_type "(String) -> Integer",
                     Time, :zone_offset, "EST"
    assert_send_type "(String, Integer) -> Integer",
                     Time, :zone_offset, "EST", 100
  end

  def test_parse
    assert_send_type "(String) -> Time",
                     Time, :parse, "2010-10-31"
    assert_send_type "(String, Date) -> Time",
                     Time, :parse, "12:00", Date.parse("2010-10-28")
    assert_send_type "(String, Time) -> Time",
                     Time, :parse, "12:00", Time.parse("2010-10-29")
    assert_send_type "(String, DateTime) -> Time",
                     Time, :parse, "12:00", DateTime.parse("2010-10-30")
    assert_send_type "(String, TimeExtensionSingletonTest::MyDate) -> Time",
                     Time, :parse, "12:00", MyDate.new(10, 31, 2010)
    assert_send_type "(String) { (Integer) -> Integer } -> Time",
                     Time, :parse, "01-10-31" do |year| year + 1000 end
    assert_send_type "(String, Date) { (Integer) -> Integer } -> Time",
                     Time, :parse, "12:00", Date.parse("2010-10-28") do |year| year + 1000 end
  end

  def test_strptime
    assert_send_type "(String, String) -> Time",
                     Time, :strptime, "2010-10-31", "%Y-%m-%d"
    assert_send_type "(String, String, Date) -> Time",
                     Time, :strptime, "12:00", "%H:%M", Date.parse("2010-10-28")
    assert_send_type "(String, String, Time) -> Time",
                     Time, :strptime, "12:00", "%H:%M", Time.parse("2010-10-29")
    assert_send_type "(String, String, DateTime) -> Time",
                     Time, :strptime, "12:00", "%H:%M", DateTime.parse("2010-10-30")
    assert_send_type "(String, String, TimeExtensionSingletonTest::MyDate) -> Time",
                     Time, :strptime, "12:00", "%H:%M", MyDate.new(10, 31, 2010)
    assert_send_type "(String, String) { (Integer) -> Integer } -> Time",
                     Time, :strptime, "01-10-31", "%y-%m-%d" do |year| year + 1000 end
    assert_send_type "(String, String, Date) { (Integer) -> Integer } -> Time",
                     Time, :strptime, "12:00", "%H:%M", Date.parse("2010-10-28") do |year| year + 1000 end
  end

  def test_rfc2822
    assert_send_type "(String) -> Time",
                     Time, :rfc2822, "Wed, 05 Oct 2011 22:26:12 -0400"
  end

  def test_rfc822
    assert_send_type "(String) -> Time",
                     Time, :rfc822, "Wed, 05 Oct 2011 22:26:12 -0400"
  end

  def test_httpdate
    assert_send_type "(String) -> Time",
                     Time, :httpdate, "Thu, 06 Oct 2011 02:26:12 GMT"
  end

  def test_xmlschema
    assert_send_type "(String) -> Time",
                     Time, :xmlschema, "2011-10-05T22:26:12-04:00"
  end

  def test_iso8601
    assert_send_type "(String) -> Time",
                     Time, :iso8601, "2011-10-05T22:26:12-04:00"
  end
end

class TimeExtensionInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "time"
  testing "::Time"

  def test_rfc2822
    assert_send_type "() -> String",
                     Time.now, :rfc2822
  end

  def test_rfc822
    assert_send_type "() -> String",
                     Time.now, :rfc822
  end

  def test_httpdate
    assert_send_type "() -> String",
                     Time.now, :httpdate
  end

  def test_xmlschema
    assert_send_type "() -> String",
                     Time.now, :xmlschema
    assert_send_type "(Integer) -> String",
                     Time.now, :xmlschema, 3
  end

  def test_iso8601
    assert_send_type "() -> String",
                     Time.now, :iso8601
    assert_send_type "(Integer) -> String",
                     Time.now, :iso8601, 3
  end
end
