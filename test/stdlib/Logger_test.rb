require_relative "test_helper"

require 'logger'
require 'stringio'

class LoggerSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library 'logger'
  testing "singleton(::Logger)"

  def test_new
    assert_send_type  "(nil) -> Logger",
                      Logger, :new, nil
    assert_send_type  "(String logdev) -> void",
                      Logger, :new, '/dev/null'
    assert_send_type  "(StringIO logdev) -> void",
                      Logger, :new, StringIO.new
    assert_send_type  "(String logdev, Integer shift_age) -> void",
                      Logger, :new, '/dev/null', 1
    assert_send_type  "(String logdev, String shift_age) -> void",
                      Logger, :new, '/dev/null', 'weekly'
    assert_send_type  "(String logdev, Integer shift_age, Integer shift_size) -> void",
                      Logger, :new, '/dev/null', 1, 1
    assert_send_type  "(String logdev, Integer shift_age, Integer shift_size, shift_period_suffix: String, binmode: bool, datetime_format: String, formatter: Proc, progname: String, level: Integer) -> void",
                      Logger, :new, '/dev/null', 1, 1, shift_period_suffix: '%Y', binmode: true, datetime_format: '%Y', formatter: proc { '' }, progname: 'foo', level: Logger::INFO
    assert_send_type  "(String logdev, Integer shift_age, Integer shift_size, shift_period_suffix: String, binmode: Symbol, datetime_format: String, formatter: Proc, progname: String, level: Integer) -> void",
                      Logger, :new, '/dev/null', 1, 1, shift_period_suffix: '%Y', binmode: :true, datetime_format: '%Y', formatter: proc { '' }, progname: 'foo', level: Logger::INFO
    assert_send_type  "(String logdev, Integer shift_age, Integer shift_size, shift_period_suffix: String, binmode: Symbol, datetime_format: String, formatter: Proc, progname: String, level: String) -> void",
                      Logger, :new, '/dev/null', 1, 1, shift_period_suffix: '%Y', binmode: :true, datetime_format: '%Y', formatter: proc { '' }, progname: 'foo', level: "INFO"
    assert_send_type  "(String logdev, Integer shift_age, Integer shift_size, shift_period_suffix: String, binmode: Symbol, datetime_format: String, formatter: Proc, progname: String, level: Symbol) -> void",
                      Logger, :new, '/dev/null', 1, 1, shift_period_suffix: '%Y', binmode: :true, datetime_format: '%Y', formatter: proc { '' }, progname: 'foo', level: :INFO
  end
end

class LoggerTest < Test::Unit::TestCase
  include TypeAssertions

  library 'logger'
  testing "::Logger"

  class WriteCloser
    def write(str)
    end

    def close
    end
  end

  def logger
    Logger.new(StringIO.new)
  end

  def test_left_shift
    assert_send_type  "(untyped msg) -> (untyped)",
                      logger, :<<, "msg"
  end

  def test_add
    assert_send_type  "(::Integer severity) -> true",
                      logger, :add, Logger::DEBUG
    assert_send_type  "(::Integer severity, String message) -> true",
                      logger, :add, Logger::DEBUG, 'msg'
    assert_send_type  "(::Integer severity, String message, String progname) -> true",
                      logger, :add, Logger::DEBUG, 'msg', 'progname'
    assert_send_type  "(::Integer severity) { () -> String } -> true",
                      logger, :add, Logger::DEBUG do 'msg' end
  end

  def test_close
    assert_send_type  "() -> untyped",
                      logger, :close
  end

  def test_datetime_format
    logger = logger()
    assert_send_type  "() -> nil",
                      logger, :datetime_format
    logger.datetime_format = ''
    assert_send_type  "() -> String",
                      logger, :datetime_format
  end

  def test_datetime_format=
    assert_send_type  "(::String datetime_format) -> ::String",
                      logger, :datetime_format=, ''
    assert_send_type  "(nil datetime_format) -> nil",
                      logger, :datetime_format=, nil
  end

  def test_debug
    assert_send_type  "() -> true",
                      logger, :debug
    assert_send_type  "(String message) -> true",
                      logger, :debug, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :debug, 'progname' do 'msg' end
  end

  def test_debug!
    assert_send_type  "() -> ::Integer",
                      logger, :debug!
  end

  def test_debug?
    logger = logger()
    logger.debug!
    assert_send_type  "() -> true",
                      logger, :debug?
    logger.info!
    assert_send_type  "() -> false",
                      logger, :debug?
  end

  def test_error
    assert_send_type  "() -> true",
                      logger, :error
    assert_send_type  "(String message) -> true",
                      logger, :error, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :error, 'progname' do 'msg' end
  end

  def test_error!
    assert_send_type  "() -> ::Integer",
                      logger, :error!
  end

  def test_error?
    logger = logger()
    logger.error!
    assert_send_type  "() -> true",
                      logger, :error?
    logger.fatal!
    assert_send_type  "() -> false",
                      logger, :error?
  end

  def test_fatal
    assert_send_type  "() -> true",
                      logger, :fatal
    assert_send_type  "(String message) -> true",
                      logger, :fatal, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :fatal, 'progname' do 'msg' end
  end

  def test_fatal!
    assert_send_type  "() -> ::Integer",
                      logger, :fatal!
  end

  def test_fatal?
    logger = logger()
    logger.fatal!
    assert_send_type  "() -> true",
                      logger, :fatal?
    logger.level = Logger::UNKNOWN
    assert_send_type  "() -> false",
                      logger, :fatal?
  end

  def test_formatter
    logger = logger()
    assert_send_type  "() -> nil",
                      logger, :formatter
    logger.formatter = proc {}
    assert_send_type  "() -> Proc",
                      logger, :formatter
    logger.formatter = Logger::Formatter.new
    assert_send_type  "() -> Logger::Formatter",
                      logger, :formatter
  end

  def test_formatter=
    assert_send_type  "(nil) -> nil",
                      logger, :formatter=, nil
    assert_send_type  "(Proc) -> Proc",
                      logger, :formatter=, proc {}
    assert_send_type  "(Logger::Formatter) -> Logger::Formatter",
                      logger, :formatter=, Logger::Formatter.new
  end

  def test_info
    assert_send_type  "() -> true",
                      logger, :info
    assert_send_type  "(String message) -> true",
                      logger, :info, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :info, 'progname' do 'msg' end
  end

  def test_info!
    assert_send_type  "() -> ::Integer",
                      logger, :info!
  end

  def test_info?
    logger = logger()
    logger.info!
    assert_send_type  "() -> true",
                      logger, :info?
    logger.error!
    assert_send_type  "() -> false",
                      logger, :info?
  end

  def test_level
    assert_send_type  "() -> Integer",
                      logger, :level
  end

  def test_level=
    assert_send_type  "(Integer severity) -> Integer",
                      logger, :level=, Logger::DEBUG
    assert_send_type  "(String severity) -> Integer",
                      logger, :level=, 'debug'
    assert_send_type  "(Symbol severity) -> Integer",
                      logger, :level=, :debug
  end

  def test_progname
    logger = logger()
    assert_send_type  "() -> nil",
                      logger, :progname
    logger.progname = 'foo'
    assert_send_type  "() -> String",
                      logger, :progname
  end

  def test_progname=
    assert_send_type  "(nil) -> nil",
                      logger, :progname=, nil
    assert_send_type  "(String) -> String",
                      logger, :progname=, 'foo'
  end

  def test_reopen
    assert_send_type  "() -> self",
                      logger, :reopen
    assert_send_type  "(nil) -> self",
                      logger, :reopen, nil
    assert_send_type  "(LoggerTest::WriteCloser) -> self",
                      logger, :reopen, WriteCloser.new
  end

  def test_unknown
    assert_send_type  "() -> true",
                      logger, :unknown
    assert_send_type  "(String message) -> true",
                      logger, :unknown, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :unknown, 'progname' do 'msg' end
  end

  def test_warn
    assert_send_type  "() -> true",
                      logger, :warn
    assert_send_type  "(String message) -> true",
                      logger, :warn, 'msg'
    assert_send_type  "(String progname) { () -> String } -> true",
                      logger, :warn, 'progname' do 'msg' end
  end

  def test_warn!
    assert_send_type  "() -> Integer",
                      logger, :warn!
  end

  def test_warn?
    logger = logger()
    logger.info!
    assert_send_type  "() -> true",
                      logger, :warn?
    logger.error!
    assert_send_type  "() -> false",
                      logger, :warn?
  end
end
