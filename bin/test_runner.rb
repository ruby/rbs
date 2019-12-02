require "ruby/signature"
require "ruby/signature/test"
require "minitest/autorun"

# stdlibs
require "base64"
require "erb"

logger = Logger.new(STDERR)
logger.level = ENV["RBS_TEST_LOGLEVEL"] || "info"

env = Ruby::Signature::Environment.new
loader = Ruby::Signature::EnvironmentLoader.new
loader.load(env: env)

HOOKS = {}

class StdlibTest < Minitest::Test
  def self.target(klass)
    @target = klass
  end

  def self.hook
    HOOKS[@target]
  end

  def hook
    self.class.hook
  end

  def setup
    super
    self.class.hook.errors.clear
    @assert = true
  end

  def teardown
    super
    assert_empty self.class.hook.errors.map {|x| Ruby::Signature::Test::Hook::Errors.to_string(x) }
  end
end

class_names = if ARGV.empty?
                Pathname("test/stdlib").children.map do |path|
                  basename = path.basename.to_s
                  if (m = basename.match(/(?<name>(?~_test))_test.rb/))
                    m[:name].gsub(/__/, "::")
                  end
                end.compact
              else
                ARGV
              end

class_names.each do |class_name|
  klass = ::Object.const_get(class_name)
  HOOKS[klass] = Ruby::Signature::Test::Hook.new(env, klass, logger: logger).verify_all
  load "test/stdlib/#{class_name.gsub(/::/, "__")}_test.rb"
end
