require_relative "test_helper"

class Process_TmsInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Process::Tms"

  def test_utime
    assert_send_type "() -> Float", Process.times, :utime
  end

  def test_utime=
    assert_send_type "(Float) -> Float", Process.times, :utime=, 1.0
  end

  def test_stime
    assert_send_type "() -> Float", Process.times, :stime
  end

  def test_stime=
    assert_send_type "(Float) -> Float", Process.times, :stime=, 1.0
  end

  def test_cutime
    assert_send_type "() -> Float", Process.times, :cutime
  end

  def test_cutime=
    assert_send_type "(Float) -> Float", Process.times, :cutime=, 1.0
  end

  def test_cstime
    assert_send_type "() -> Float", Process.times, :cstime
  end

  def test_cstime=
    assert_send_type "(Float) -> Float", Process.times, :cstime=, 1.0
  end
end
