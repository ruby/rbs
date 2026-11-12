require_relative "test_helper"
require "logger"
require "tmpdir"

class LoggerSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "logger"
  testing "singleton(::Logger)"

  def test_new
    Dir.mktmpdir do |dir|
      assert_send_type "(String) -> Logger",
                       Logger, :new, File.join(dir, "a.log")
      assert_send_type "(String, Integer, Integer, level: Integer, progname: String) -> Logger",
                       Logger, :new, File.join(dir, "b.log"), 3, 1024, level: Logger::INFO, progname: "app"
      assert_send_type "(String, reraise_write_errors: Array[singleton(IOError)], skip_header: bool) -> Logger",
                       Logger, :new, File.join(dir, "c.log"), reraise_write_errors: [IOError], skip_header: true
    end
  end
end

class LoggerInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "logger"
  testing "::Logger"

  def test_reopen
    Dir.mktmpdir do |dir|
      logger = Logger.new(File.join(dir, "a.log"))

      assert_send_type "() -> Logger",
                       logger, :reopen
      assert_send_type "(String) -> Logger",
                       logger, :reopen, File.join(dir, "b.log")
      assert_send_type "(String, Integer, Integer, shift_period_suffix: String, binmode: bool) -> Logger",
                       logger, :reopen, File.join(dir, "c.log"), 3, 1024, shift_period_suffix: "%Y%m", binmode: true
      assert_send_type "(binmode: bool) -> Logger",
                       logger, :reopen, binmode: false
    ensure
      logger&.close
    end
  end
end

class LoggerLogDeviceSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "logger"
  testing "singleton(::Logger::LogDevice)"

  def test_new
    Dir.mktmpdir do |dir|
      assert_send_type "(String) -> Logger::LogDevice",
                       Logger::LogDevice, :new, File.join(dir, "a.log")
      assert_send_type "(String, reraise_write_errors: Array[singleton(IOError)], skip_header: bool) -> Logger::LogDevice",
                       Logger::LogDevice, :new, File.join(dir, "b.log"), reraise_write_errors: [IOError], skip_header: true
    end
  end
end

class LoggerLogDeviceInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "logger"
  testing "::Logger::LogDevice"

  def test_reopen
    Dir.mktmpdir do |dir|
      device = Logger::LogDevice.new(File.join(dir, "a.log"))

      assert_send_type "() -> Logger::LogDevice",
                       device, :reopen
      assert_send_type "(nil) -> Logger::LogDevice",
                       device, :reopen, nil
      assert_send_type "(String, shift_age: Integer, shift_size: Integer, shift_period_suffix: String, binmode: bool) -> Logger::LogDevice",
                       device, :reopen, File.join(dir, "b.log"), shift_age: 3, shift_size: 1024, shift_period_suffix: "%Y%m", binmode: true
    ensure
      device&.close
    end
  end
end
