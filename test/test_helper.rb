$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "rbs"
require "tmpdir"
require "stringio"
require "open3"

begin
  require 'minitest/reporters'
  Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]
rescue LoadError
end

module TestHelper
  def has_gem?(*gems)
    gems.each do |gem|
      Gem::Specification.find_by_name(gem)
    end

    true
  rescue Gem::MissingSpecError
    false
  end

  def parse_type(string, variables: Set.new)
    RBS::Parser.parse_type(string, variables: variables)
  end

  def parse_method_type(string, variables: Set.new)
    RBS::Parser.parse_method_type(string, variables: variables)
  end

  def type_name(string)
    RBS::Namespace.parse(string).yield_self do |namespace|
      last = namespace.path.last
      RBS::TypeName.new(name: last, namespace: namespace.parent)
    end
  end

  def silence_errors
    RBS.logger.stub :error, nil do
      yield
    end
  end

  def silence_warnings
    RBS.logger.stub :warn, nil do
      yield
    end
  end

  class SignatureManager
    attr_reader :files
    attr_reader :system_builtin

    def initialize(system_builtin: false)
      @files = {}
      @system_builtin = system_builtin

      files[Pathname("builtin.rbs")] = BUILTINS unless system_builtin
    end

    def self.new(**kw)
      instance = super(**kw)

      if block_given?
        yield instance
      else
        instance
      end
    end

    BUILTINS = <<SIG
class BasicObject
  def __id__: -> Integer

  private
  def initialize: -> void
end

class Object < BasicObject
  include Kernel

  public
  def __id__: -> Integer

  private
  def respond_to_missing?: (Symbol, bool) -> bool
end

module Kernel
  private
  def puts: (*untyped) -> nil
  def to_i: -> Integer
end

class Class < Module
end

class Module
end

class String
  include Comparable

  def self.try_convert: (untyped) -> String?
end

class Integer
end

class Symbol
end

module Comparable
end

module Enumerable[A, B]
end
SIG

    def add_file(path, content)
      files[Pathname(path)] = content
    end

    def build
      Dir.mktmpdir do |tmpdir|
        tmppath = Pathname(tmpdir)

        files.each do |path, content|
          absolute_path = tmppath + path
          absolute_path.parent.mkpath
          absolute_path.write(content)
        end

        loader = RBS::EnvironmentLoader.new()
        loader.no_builtin! unless system_builtin
        loader.add path: tmppath

        yield RBS::Environment.from_loader(loader).resolve_type_names, tmppath
      end
    end
  end

  def assert_write(decls, string)
    writer = RBS::Writer.new(out: StringIO.new)
    writer.write(decls)

    assert_equal string, writer.out.string

    # Check syntax error
    RBS::Parser.parse_signature(writer.out.string)
  end

  def assert_sampling_check(builder, sample_size, array)
    checker = RBS::Test::TypeCheck.new(self_class: Integer, builder: builder, sample_size: sample_size, unchecked_classes: [])

    sample = checker.each_sample(array).to_a

    assert_operator(sample.size, :<=, array.size)
    assert_operator(sample.size, :<=, sample_size) unless sample_size.nil?
    assert_empty(sample - array)
  end
end

require "minitest/autorun"
