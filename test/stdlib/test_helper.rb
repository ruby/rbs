RUBY_27_OR_LATER = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
unless RUBY_27_OR_LATER
  STDERR.puts "🚨🚨🚨 stdlib test requires Ruby 2.7 but RUBY_VERSION==#{RUBY_VERSION}, exiting... 🚨🚨🚨"
  exit
end

require "ruby/signature"
require "ruby/signature/test"
require "minitest/autorun"

require "minitest/reporters"
Minitest::Reporters.use!

class StdlibTest < Minitest::Test
  class ToInt
    def initialize(value = 3)
      @value = value
    end

    def to_int
      @value
    end
  end

  class ToStr
    def initialize(value = "")
      @value = value
    end

    def to_str
      @value
    end
  end


  DEFAULT_LOGGER = Logger.new(STDERR)
  DEFAULT_LOGGER.level = ENV["RBS_TEST_LOGLEVEL"] || "info"

  loader = Ruby::Signature::EnvironmentLoader.new
  DEFAULT_ENV = Ruby::Signature::Environment.new
  loader.load(env: DEFAULT_ENV)

  def self.target(klass)
    @target = klass
  end

  def self.env
    @env || DEFAULT_ENV
  end

  def self.library(*libs)
    loader = Ruby::Signature::EnvironmentLoader.new
    libs.each do |lib|
      loader.add library: lib
    end

    @env = Ruby::Signature::Environment.new
    loader.load(env: @env)
  end

  def self.hook
    @hook ||= Ruby::Signature::Test::Hook.new(env, @target, logger: DEFAULT_LOGGER).verify_all
  end

  def hook
    self.class.hook
  end

  def setup
    super
    self.hook.errors.clear
    @assert = true
  end

  def teardown
    super
    assert_empty self.hook.errors.map {|x| Ruby::Signature::Test::Hook::Errors.to_string(x) }
  end
end
