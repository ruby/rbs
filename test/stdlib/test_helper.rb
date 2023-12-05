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

module WithAliases
  class WithEnum
    include Enumerable

    def initialize(enum) = @enum = enum

    def each(&block) = @enum.each(&block)

    def and_nil(&block)
      self.and(nil, &block)
    end

    def but(*cases)
      return WithEnum.new to_enum(__method__, *args) unless block_given?

      each do |arg|
        yield arg unless cases.any? { _1 === arg }
      end
    end

    def and(*args, &block)
      return WithEnum.new to_enum(__method__, *args) unless block_given?

      each(&block)
      args.each do |arg|
        if WithEnum === arg # use `===` as `arg` might not have `.is_a?` on it
          arg.each(&block)
        else
          block.call(arg)
        end
      end
    end
  end

  def with(*args, &block)
    return WithEnum.new to_enum(__method__, *args) unless block_given?
    args.each(&block)
  end

  def with_int(value = 3)
    return WithEnum.new to_enum(__method__, value) unless block_given?
    yield value
    yield ToInt.new(value)
  end

  def with_float(value = 0.1)
    return WithEnum.new to_enum(__method__, value) unless block_given?
    yield value
    yield ToF.new(value)
  end

  def with_string(value = '')
    return WithEnum.new to_enum(__method__, value) unless block_given?
    yield value
    yield ToStr.new(value)
  end

  def with_array(*elements)
    return WithEnum.new to_enum(__method__, *elements) unless block_given?

    yield elements
    yield ToArray.new(*elements)
  end

  def with_hash(hash = {})
    return WithEnum.new to_enum(__method__, hash) unless block_given?

    yield hash
    yield ToHash.new(hash)
  end

  def with_io(io = $stdout)
    return WithEnum.new to_enum(__method__, io) unless block_given?
    yield io
    yield ToIO.new(io)
  end

  def with_path(path = "/tmp/foo.txt", &block)
    return WithEnum.new to_enum(__method__, path) unless block_given?

    with_string(path, &block)
    block.call ToPath.new(path)
  end

  def with_encoding(encoding = Encoding::UTF_8, &block)
    return WithEnum.new to_enum(__method__, encoding) unless block_given?

    block.call encoding
    with_string(encoding.to_s, &block)
  end

  def with_interned(value = :&, &block)
    return WithEnum.new to_enum(__method__, value) unless block_given?

    with_string(value.to_s, &block)
    block.call value.to_sym
  end

  def with_bool
    return WithEnum.new to_enum(__method__) unless block_given?
    yield true
    yield false
  end

  def with_boolish(&block)
    return WithEnum.new to_enum(__method__) unless block_given?
    with_bool(&block)
    [nil, 1, Object.new, BlankSlate.new, "hello, world!"].each(&block)
  end

  alias with_untyped with_boolish

  def with_range(start, stop, exclude_end = false)
    # If you need fixed starting and stopping points, you can just do `with_range with(1), with(2)`.
    raise ArgumentError, '`start` must be from a `with` method' unless start.is_a? WithEnum
    raise ArgumentError, '`stop` must be from a `with` method' unless stop.is_a? WithEnum

    start.each do |lower|
      stop.each do |upper|
        yield CustomRange.new(lower, upper, exclude_end)

        # `Range` requires `begin <=> end` to return non-nil, but doesn't actually
        # end up using the return value of it. This is to add that in when needed.
        def lower.<=>(rhs) = :not_nil unless defined? lower.<=>

        # If `lower <=> rhs` is defined but nil, then that means we're going to be constructing
        # an illegal range (eg `3..ToInt.new(4)`). So, we need to skip yielding an invalid range
        # in that case.
        next if defined?(lower.<=>) && nil == (lower <=> upper)

        yield Range.new(lower, upper, exclude_end)
      end
    end
  end
end

class BlankSlate < BasicObject
  instance_methods.each do |im|
    next if %i[__send__ __id__].include? im
    undef_method im
  end

  def __with_object_methods(*methods)
    methods.each do |method|
      singleton_class = ::Object.instance_method(:singleton_class).bind_call(self)
      singleton_class.instance_eval do
        define_method method, ::Object.instance_method(method)
      end
    end
    self
  end
end

class ToIO < BlankSlate
  def initialize(io = $stdout)
    @io = io
  end

  def to_io
    @io
  end
end

class ToI < BlankSlate
  def initialize(value = 3)
    @value = value
  end

  def to_i
    @value
  end
end

class ToInt < BlankSlate
  def initialize(value = 3)
    @value = value
  end

  def to_int
    @value
  end
end

class ToF < BlankSlate
  def initialize(value = 0.1)
    @value = value
  end

  def to_f
    @value
  end
end

class ToR < BlankSlate
  def initialize(value = 1r)
    @value = value
  end

  def to_r
    @value
  end
end

class ToC < BlankSlate
  def initialize(value = 1i)
    @value = value
  end

  def to_c
    @value
  end
end

class ToStr < BlankSlate
  def initialize(value = "")
    @value = value
  end

  def to_str
    @value
  end
end

class ToS < BlankSlate
  def initialize(value = "")
    @value = value
  end

  def to_s
    @value
  end
end

class ToSym < BlankSlate
  def initialize(value = :&)
    @value = value
  end

  def to_sym
    @value
  end
end

class ToA < BlankSlate
  def initialize(*args)
    @args = args
  end

  def to_a
    @args
  end
end

class ToArray < BlankSlate
  def initialize(*args)
    @args = args
  end

  def to_ary
    @args
  end
end

class ToHash < BlankSlate
  def initialize(hash = { 'hello' => 'world' })
    @hash = hash
  end

  def to_hash
    @hash
  end
end

class ToPath < BlankSlate
  def initialize(value = "")
    @value = value
  end

  def to_path
    @value
  end
end

class CustomRange < BlankSlate
  attr_reader :begin, :end

  def initialize(begin_, end_, exclude_end = false)
    @begin = begin_
    @end = end_
    @exclude_end = exclude_end
  end

  def exclude_end? = @exclude_end
end

class Each < BlankSlate
  def initialize(*args)
    @args = args
  end

  def each(&block)
    @args.each(&block)
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

class Rand < BlankSlate
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

class Enum < BlankSlate
  def initialize(*args)
    @args = args
  end

  include ::Enumerable

  def each(&block)
    @args.each(&block)
  end
end

class ArefFromStringToString < BlankSlate
  def [](str)
    "!"
  end
end

module TestHelper
  include RBS::UnitTest::TypeAssertions
  include WithAliases
  include VersionHelper

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
