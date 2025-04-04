$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

require "tmpdir"
require "stringio"
require "open3"
require "bundler" # Explicitly require bundler because ruby CI runs without bundler

require "rbs"
require "rbs/annotate"
require "test_skip"

unless ENV["XDG_CACHE_HOME"]
  tmpdir = Dir.mktmpdir("rbs-test-")
  ENV["XDG_CACHE_HOME"] = tmpdir

  at_exit do
    FileUtils.rmtree(tmpdir)
    ENV.delete("XDG_CACHE_HOME")
  end
end

require "test/unit"

begin
  require "amber"
rescue LoadError
end

class Test::Unit::TestCase
  prepend TestSkip
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

  def skip_minitest?
    ENV.key?("NO_MINITEST")
  end

  def parse_type(string, variables: [])
    RBS::Parser.parse_type(string, variables: variables)
  end

  def parse_method_type(string, variables: [])
    RBS::Parser.parse_method_type(string, variables: variables)
  end

  def type_name(string)
    RBS::Namespace.parse(string).yield_self do |namespace|
      last = namespace.path.last
      RBS::TypeName.new(name: last, namespace: namespace.parent)
    end
  end

  def silence_warnings
    klass = RBS.logger.class
    original_method = klass.instance_method(:warn)

    klass.remove_method(:warn)
    klass.define_method(:warn) do |*args, &block|
      block&.call()
    end

    yield
  ensure
    klass.remove_method(:warn)
    klass.define_method(:warn, original_method)
  end

  class SignatureManager
    attr_reader :files
    attr_reader :ruby_files
    attr_reader :system_builtin

    def initialize(system_builtin: false)
      @files = {}
      @ruby_files = {}
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

  def to_i: -> Integer

  private
  def respond_to_missing?: (Symbol, bool) -> bool
end

module Kernel : BasicObject
  private
  def puts: (*untyped) -> nil
end

class Class < Module
  def new: (*untyped, **untyped) ?{ (*untyped, **untyped) -> untyped } -> untyped
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

module Enumerable[A]
end

class Hash[unchecked out K, unchecked out V]
  include Enumerable[[K, V]]
end

class Struct[Elem]
  include Enumerable[Elem?]
end
SIG

    def add_file(path, content)
      files[Pathname(path)] = content
    end

    def add_ruby_file(path, content)
      ruby_files[Pathname(path)] = content
    end

    def build
      Dir.mktmpdir do |tmpdir|
        tmppath = Pathname(tmpdir)

        files.each do |path, content|
          absolute_path = tmppath + path
          absolute_path.parent.mkpath
          absolute_path.write(content)
        end

        root =
          if system_builtin
            RBS::EnvironmentLoader::DEFAULT_CORE_ROOT
          else
            nil
          end

        loader = RBS::EnvironmentLoader.new(core_root: root)
        loader.add(path: tmppath)

        env = RBS::Environment.from_loader(loader)

        ruby_files.each do |path, content|
          buffer = RBS::Buffer.new(name: path, content: content)
          prism = Prism.parse(content)
          result = RBS::InlineParser.parse(buffer, prism)
          source = RBS::Source::Ruby.new(buffer, prism, result.declarations, result.diagnostics)
          env.add_source(source)
        end

        env = env.resolve_type_names

        yield env, tmppath
      end
    end
  end

  def assert_any(collection, size: nil)
    assert_any!(collection, size: size) do |item|
      assert yield(item)
    end
  end

  def assert_any!(collection, size: nil)
    assert_equal size, collection.size if size

    *items, last = collection

    if last
      items.each do |item|
        begin
          yield item
        rescue Test::Unit::AssertionFailedError
          next
        else
          # Pass test
          return
        end
      end

      yield last
    else
      assert_block("assert_any! cannot hold for empty collection") { false }
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

  class ArgumentChecker
    def initialize(builder:, interface:)
      @builder = builder
      @interface = interface
    end

    def no_argument_error?(method_name)
      method = @builder.build_interface(RBS::TypeName.parse(@interface)).methods[method_name]
      method.defs.any? do |type_def|
        type_def.member.overloads.all? do |overload|
          fun = overload.method_type.type
          build_args(fun) do |args|
            build_kwargs(fun) do |kwargs|
              yield args, kwargs, nil
            end
          end
          true
        rescue ArgumentError
          false
        end
      end
    end

    private

    def build_args(fun)
      reqs = fun.required_positionals.map { :req }
      tras = fun.trailing_positionals.map { :trail }
      opts = [[]].concat(fun.optional_positionals.map.with_index do |_, i|
        fun.optional_positionals[0..i].map { :opt }
      end)
      rest = [[]]
      if fun.rest_positionals
        rest << [:rest, :rest, :rest]
      end
      opts.each do |o|
        rest.each do |r|
          yield (reqs + o + r + tras).flatten
        end
      end
    end

    def build_kwargs(fun)
      reqs = fun.required_keywords.map { |name, _| [name, :req] }
      opts = fun.optional_keywords.map { |name, _| [name, :opt] }
      opts_comb = opts.filter_map.with_index do |_, i|
        next if i == 0
        opts.combination(i).map(&:to_h)
      end.flatten
      opts_comb.unshift({})
      opts_comb.each do |opt|
        kwargs = reqs.to_h.merge(opt)
        yield kwargs
        if fun.rest_keywords
          yield kwargs.merge({ random_key => :rest, random_key => :rest, random_key => :rest })
        end
      end
    end

    def random_key
      ('a'..'z').to_a.shuffle.take(5).join.to_sym
    end
  end
end

# if $0.end_with?("_test.rb")
#   at_exit do
#     argv = ARGV.dup
#     test_unit_args = []

#     OptionParser.new do |opts|
#       opts.on("--name NAME") do |name|
#         name = name.gsub(/(\A\/)|(\/\Z)/, '')
#         klass_name, method_name = name.split("#", 2)

#         constant = ObjectSpace.each_object(Class).find do |klass|
#           if klass.name
#             klass.name == klass_name || klass.name.end_with?("::#{klass_name}")
#           end
#         end

#         if constant
#           if method_name
#             test_unit_args << "--name"
#             test_unit_args << "#{constant.name}##{method_name}"
#           else
#             test_unit_args << "--testcase"
#             test_unit_args << constant.name
#           end
#         end
#       end
#     end.order!(argv)
#     test_unit_args.push(*argv)

#     RBS.logger.info { "Forwarding to test-unit command line: #{test_unit_args.inspect}" }

#     Test::Unit::AutoRunner.run(false, nil, test_unit_args)
#   end
# end
