require "rbs"
require "rbs/test"
require "test/unit"
require "tmpdir"
require "stringio"
require "tempfile"

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
            return_value = spy.object.__send__(spy.method_name, *args, &spy_block)
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

    def env
      @env ||= begin
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
                              required: mt.block.required
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

  def ci?
    ENV["CI"] == "true"
  end

  def allows_error(*errors)
    yield
  rescue *errors => exn
    notify "Error allowed: #{exn.inspect}"
  end

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

class ToS
  def initialize(value = "")
    @value = value
  end

  def to_s
    @value
  end
end

class ToArray
  def initialize(*args)
    @args = args
  end

  def to_ary
    @args
  end
end

class ToPath
  def initialize(value = "")
    @value = value
  end

  def to_path
    @value
  end
end

class ToJson
end

class Rand
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

class Enum
  def initialize(*args)
    @args = args
  end

  include Enumerable

  def each(&block)
    @args.each(&block)
  end
end

class ArefFromStringToString
  def [](str)
    "!"
  end
end

class StdlibTest < Test::Unit::TestCase
  RBS.logger_level = ENV["RBS_TEST_LOGLEVEL"] || "info"

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

  def hook
    self.class.hook
  end
end
