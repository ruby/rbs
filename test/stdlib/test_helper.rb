require "rbs"
require "rbs/test"
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

module Spy
  def self.wrap(object, method_name)
    spy = WrapSpy.new(object: object, method_name: method_name)

    if block_given?
      begin
        yield spy, spy.wrapped_object
      end
    else
      spy
    end
  end

  class WrapSpy
    attr_accessor :callback
    attr_reader :object
    attr_reader :method_name

    def initialize(object:, method_name:)
      @callback = -> (_) { }
      @object = object
      @method_name = method_name
    end

    def wrapped_object
      spy = self

      Class.new(BasicObject) do
        define_method(:method_missing) do |name, *args, &block|
          spy.object.__send__(name, *args, &block)
        end

        define_method(spy.method_name, -> (*args, &block) {
          return_value = nil
          exception = nil
          block_calls = []

          spy_block = if block
                        Object.new.instance_eval do |fresh|
                          -> (*block_args) do
                            block_exn = nil
                            block_return = nil

                            begin
                              block_return = if self.equal?(fresh)
                                               # no instance eval
                                               block.call(*block_args)
                                             else
                                               self.instance_exec(*block_args, &block)
                                             end
                            rescue Exception => exn
                              block_exn = exn
                            end

                            if block_exn
                              block_calls << RBS::Test::ArgumentsReturn.exception(
                                arguments: block_args,
                                exception: block_exn
                              )
                            else
                              block_calls << RBS::Test::ArgumentsReturn.return(
                                arguments: block_args,
                                value: block_return
                              )
                            end

                            if block_exn
                              raise block_exn
                            else
                              block_return
                            end
                          end.ruby2_keywords
                        end
                      end

          begin
            if spy_block
              return_value = spy.object.__send__(spy.method_name, *args) do |*a, **k, &b|
                spy_block.call(*a, **k, &b)
              end
            else
              return_value = spy.object.__send__(spy.method_name, *args, &spy_block)
            end
          rescue ::Exception => exn
            exception = exn
          end

          call = if exception
                   RBS::Test::ArgumentsReturn.exception(
                     arguments: args,
                     exception: exception
                   )
                 else
                   RBS::Test::ArgumentsReturn.return(
                     arguments: args,
                     value: return_value
                   )
                 end
          trace = RBS::Test::CallTrace.new(
            method_name: spy.method_name,
            method_call: call,
            block_calls: block_calls,
            block_given: block != nil
          )

          spy.callback.call(trace)

          if exception
            spy.object.__send__(:raise, exception)
          else
            return_value
          end
        }.ruby2_keywords)
      end.new()
    end
  end
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

module TypeAssertions
  module ClassMethods
    attr_reader :target

    def library(*libs)
      if @libs
        raise "Multiple #library calls are not allowed"
      end

      @libs = libs
      @env = nil
      @target = nil
    end

    @@env_cache = {}

    def env
      @env = @@env_cache[@libs] ||=
        begin
          loader = RBS::EnvironmentLoader.new
          (@libs || []).each do |lib|
            loader.add library: lib
          end

          RBS::Environment.from_loader(loader).resolve_type_names
        end
    end

    def builder
      @builder ||= RBS::DefinitionBuilder.new(env: env)
    end

    def testing(type_or_string)
      type = case type_or_string
             when String
               RBS::Parser.parse_type(type_or_string, variables: [])
             else
               type_or_string
             end

      definition = case type
                   when RBS::Types::ClassInstance
                     builder.build_instance(type.name)
                   when RBS::Types::ClassSingleton
                     builder.build_singleton(type.name)
                   else
                     raise "Test target should be class instance or class singleton: #{type}"
                   end

      @target = [type, definition]
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  def env
    self.class.env
  end

  def builder
    self.class.builder
  end

  def targets
    @targets ||= []
  end

  def target
    targets.last || self.class.target
  end

  def testing(type_or_string)
    type = case type_or_string
           when String
             RBS::Parser.parse_type(type_or_string, variables: [])
           else
             type_or_string
           end

    definition = case type
                 when RBS::Types::ClassInstance
                   builder.build_instance(type.name)
                 when RBS::Types::ClassSingleton
                   builder.build_singleton(type.name)
                 else
                   raise "Test target should be class instance or class singleton: #{type}"
                 end

    targets.push [type, definition]

    if block_given?
      begin
        yield
      ensure
        targets.pop
      end
    else
      [type, definition]
    end
  end

  def instance_class
    type, _ = target

    case type
    when RBS::Types::ClassSingleton, RBS::Types::ClassInstance
      Object.const_get(type.name.to_s)
    end
  end

  def class_class
    type, _ = target

    case type
    when RBS::Types::ClassSingleton, RBS::Types::ClassInstance
      Object.const_get(type.name.to_s).singleton_class
    end
  end

  ruby2_keywords def assert_send_type(method_type, receiver, method, *args, &block)
    trace = []
    spy = Spy.wrap(receiver, method)
    spy.callback = -> (result) { trace << result }

    result = nil
    exception = nil

    begin
      result = spy.wrapped_object.__send__(method, *args, &block)
    rescue Exception => exn
      exception = exn
    end

    mt = case method_type
         when String
           RBS::Parser.parse_method_type(method_type, variables: [])
         when RBS::MethodType
           method_type
         end

    typecheck = RBS::Test::TypeCheck.new(
      self_class: receiver.class,
      builder: builder,
      sample_size: 100,
      unchecked_classes: [],
      instance_class: instance_class,
      class_class: class_class
    )
    errors = typecheck.method_call(method, mt, trace.last, errors: [])

    assert_empty errors.map {|x| RBS::Test::Errors.to_string(x) }, "Call trace does not match with given method type: #{trace.last.inspect}"

    method_types = method_types(method)
    all_errors = method_types.map {|t| typecheck.method_call(method, t, trace.last, errors: []) }
    assert all_errors.any? {|es| es.empty? }, "Call trace does not match one of method definitions:\n  #{trace.last.inspect}\n  #{method_types.join(" | ")}"

    raise exception if exception

    result
  end

  ruby2_keywords def refute_send_type(method_type, receiver, method, *args, &block)
    trace = []
    spy = Spy.wrap(receiver, method)
    spy.callback = -> (result) { trace << result }

    result = nil
    exception = nil

    begin
      result = spy.wrapped_object.__send__(method, *args, &block)
    rescue Exception => exn
      exception = exn
    end

    mt = case method_type
         when String
           RBS::Parser.parse_method_type(method_type, variables: [])
         when RBS::MethodType
           method_type
         end

    mt = mt.update(block: if mt.block
                            RBS::Types::Block.new(
                              type: mt.block.type.with_return_type(RBS::Types::Bases::Any.new(location: nil)),
                              required: mt.block.required,
                              self_type: nil
                            )
                          end,
                   type: mt.type.with_return_type(RBS::Types::Bases::Any.new(location: nil)))

    typecheck = RBS::Test::TypeCheck.new(
      self_class: receiver.class,
      instance_class: instance_class,
      class_class: class_class,
      builder: builder,
      sample_size: 100,
      unchecked_classes: []
    )
    errors = typecheck.method_call(method, mt, trace.last, errors: [])

    assert_operator exception, :is_a?, ::Exception
    assert_empty errors.map {|x| RBS::Test::Errors.to_string(x) }

    method_types = method_types(method)
    all_errors = method_types.map {|t| typecheck.method_call(method, t, trace.last, errors: []) }
    assert all_errors.all? {|es| es.size > 0 }, "Call trace unexpectedly matches one of method definitions:\n  #{trace.last.inspect}\n  #{method_types.join(" | ")}"

    result
  end

  def method_types(method)
    type, definition = target

    case
    when definition.instance_type?
      subst = RBS::Substitution.build(definition.type_params, type.args)
      definition.methods[method].method_types.map do |method_type|
        method_type.sub(subst)
      end
    when definition.class_type?
      definition.methods[method].method_types
    end
  end

  def allows_error(*errors)
    yield
  rescue *errors => exn
    notify "Error allowed: #{exn.inspect}"
  end

  include VersionHelper
  include WithAliases

  def assert_const_type(type, constant_name)
    constant = Object.const_get(constant_name)

    typecheck = RBS::Test::TypeCheck.new(
      self_class: constant.class,
      instance_class: instance_class,
      class_class: class_class,
      builder: builder,
      sample_size: 100,
      unchecked_classes: []
    )

    value_type =
      case type
      when String
        RBS::Parser.parse_type(type, variables: [])
      else
        type
      end

    assert typecheck.value(constant, value_type), "`#{constant_name}` (#{constant.inspect}) must be compatible with given type `#{value_type}`"

    type_name = TypeName(constant_name).absolute!
    definition = env.constant_entry(type_name)
    assert definition, "Cannot find RBS type definition of `#{constant_name}`"

    case definition
    when RBS::Environment::ClassEntry, RBS::Environment::ModuleEntry
      definition_type = RBS::Types::ClassSingleton.new(name: type_name, location: nil)
    when RBS::Environment::ClassAliasEntry, RBS::Environment::ModuleAliasEntry
      type_name = env.normalize_type_name!(type_name)
      definition_type = RBS::Types::ClassSingleton.new(name: type_name, location: nil)
    when RBS::Environment::ConstantEntry
      definition_type = definition.decl.type
    end

    assert typecheck.value(constant, definition_type), "`#{constant_name}` (#{constant.inspect}) must be compatible with RBS type definition `#{definition_type}`"
  end

  def assert_type(type, value)
    typecheck = RBS::Test::TypeCheck.new(
      self_class: value.class,
      instance_class: "No `instance` class allowed",
      class_class: "No `class` class allowed",
      builder: builder,
      sample_size: 100,
      unchecked_classes: []
    )

    type =
      case type
      when String
        RBS::Parser.parse_type(type, variables: [])
      else
        type
      end

    assert typecheck.value(value, type), "`#{value.inspect}` must be compatible with given type `#{type}`"
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
