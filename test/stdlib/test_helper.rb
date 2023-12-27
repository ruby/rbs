require "rbs"
require "rbs/test"
require "rbs/unit_test"
require "test/unit"
require "tmpdir"
require "stringio"
require "tempfile"
require_relative "../test_skip"

class Test::Unit::TestCase
  prepend TestSkip
end

class Test::Unit::TestCase
  module Printer
    def setup
      STDERR.puts name
      super
    end
  end

  # prepend Printer
end

module VersionHelper
  def if_ruby(range)
    r = Range.new(
      range.begin&.yield_self {|b| Gem::Version.new(b) },
      range.end&.yield_self {|e| Gem::Version.new(e) },
      range.exclude_end?
    )

    if r === Gem::Version.new(RUBY_VERSION)
      yield
    else
      notify "Skipping test: #{r} !== #{RUBY_VERSION}"
    end
  end

  def if_ruby3(&block)
    if_ruby("3.0.0"..."4.0.0", &block)
  end

  def if_ruby30(&block)
    if_ruby("3.0.0"..."3.1.0", &block)
  end

  def if_ruby31(&block)
    if_ruby("3.1.0"..."3.2.0", &block)
  end
end

module WithStdlibAliases
  def with_timeout(seconds: 1, nanoseconds: 0)
    unless block_given?    
      return RBS::UnitTest::Convertibles::WithAliases::WithEnum.new(
        to_enum(__method__, seconds: seconds, nanoseconds: nanoseconds)
      )
    end

    timeout_obj = RBS::UnitTest::Convertibles::BlankSlate.new.__with_object_methods(:define_singleton_method)
    nanosecs_obj = RBS::UnitTest::Convertibles::BlankSlate.new.__with_object_methods(:define_singleton_method)

    secs = nanosecs = nil
    timeout_obj.define_singleton_method :divmod do |x|
      flunk "Expected `1` for argument to divmod, got #{x.inspect}" unless 1.equal? x
      [secs, nanosecs_obj]
    end
    nanosecs_obj.define_singleton_method :* do |x|
      flunk "Expected `1000000000` for argument to *, got #{x.inspect}" unless 1000000000.equal? x
      nanosecs
    end

    with_int seconds do |s|
      secs = s
      with_int nanoseconds do |ns|
        nanosecs = ns
        yield timeout_obj
      end
    end
  end

  def with_to_s(&block)
    return WithEnum.new to_enum(__method__ || raise) unless block
    with_bool(&block)
    [nil, 1, Object.new, ToS.new, "hello, world!"].each(&block)
  end
end

class Writer
  attr_reader :buffer

  def initialize
    @buffer = ""
  end

  def write(*vals)
    @buffer.concat vals.join
  end
end

class ToJson
end

class Rand < RBS::UnitTest::Convertibles::BlankSlate
  def rand(max)
    max - 1
  end
end

class JsonWrite
  def write(_str)
  end
end

class JsonToWritableIO
  def to_io
    JsonWrite.new
  end
end

class JsonRead
  def read
    "42"
  end
end

class JsonToReadableIO
  def to_io
    JsonRead.new
  end
end

class Enum < RBS::UnitTest::Convertibles::BlankSlate
  def initialize(*args)
    @args = args
  end

  include ::Enumerable

  def each(&block)
    @args.each(&block)
  end
end

include RBS::UnitTest::Convertibles

module TestHelper
  include RBS::UnitTest::TypeAssertions
  include RBS::UnitTest::Convertibles
  include RBS::UnitTest::WithAliases
  include VersionHelper
  include WithStdlibAliases

  # The current ruby executable path; used in some functions which spawn shells, as the only 
  # executable we can be guaranteed to exist is ruby itself.
  RUBY_EXE = ENV['RUBY'] || RbConfig.ruby

  def self.included(base)
    base.extend RBS::UnitTest::TypeAssertions::ClassMethods
  end
end

class StdlibTest < Test::Unit::TestCase
  RBS.logger_level = ENV["RBS_TEST_LOGLEVEL"] || "info"

  include VersionHelper

  loader = RBS::EnvironmentLoader.new
  DEFAULT_ENV = RBS::Environment.new.yield_self do |env|
    loader.load(env: env)
    env.resolve_type_names
  end

  def self.target(klass)
    @target = klass
  end

  def self.env
    @env || DEFAULT_ENV
  end

  def self.library(*libs)
    loader = RBS::EnvironmentLoader.new
    libs.each do |lib|
      loader.add library: lib
    end

    @env = RBS::Environment.from_loader(loader).resolve_type_names
  end

  def self.hook
    @hook ||= begin
                RBS::Test::Tester.new(env: env).tap do |tester|
                  tester.install!(@target)
                end
              end
  end

  # def setup
  #   STDERR.puts name
  #   super
  # end

  def hook
    self.class.hook
  end

  def self.discard_output
    include DiscardOutput
  end

  module DiscardOutput
    def setup
      null = StringIO.new
      @stdout, @stderr = $stdout, $stderr
      $stderr = $stdout = null
      super
    end

    def teardown
      super
      $stderr, $stdout = @stderr, @stdout
    end
  end
end
