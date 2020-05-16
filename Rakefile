require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].reject do |path|
    path =~ %r{test/stdlib/}
  end
end

multitask :default => [:test, :stdlib_test, :rubocop, :validate]

task :validate => :parser do
  sh "rbs validate"
end

FileList["test/stdlib/**/*_test.rb"].each do |test|
  multitask test => :parser do
    sh "ruby bin/test_runner.rb #{test}"
  end
  multitask stdlib_test: test
end

task :rubocop do
  sh "rubocop --parallel"
end

rule ".rb" => ".y" do |t|
  sh "racc -v -o #{t.name} #{t.source}"
end

task :parser => "lib/rbs/parser.rb"
task :test => :parser
task :stdlib_test => :parser
task :build => :parser

namespace :generate do
  task :stdlib_test, [:class] do |_task, args|
    klass = args.fetch(:class) do
      raise "Class name is necessary. e.g. rake 'generate:stdlib_test[String]'"
    end

    path = Pathname("test/stdlib/#{klass}_test.rb")
    raise "#{path} already exists!" if path.exist?

    require "erb"
    require "ruby/signature"

    class TestTemplateBuilder
      attr_reader :klass, :env

      def initialize(klass)
        @klass = klass

        @env = Ruby::Signature::Environment.new
        Ruby::Signature::EnvironmentLoader.new.load(env: @env)
      end

      def call
        ERB.new(<<~ERB, trim_mode: "-").result(binding)
          require_relative "test_helper"

          class <%= klass %>Test < StdlibTest
            target <%= klass %>
            # library "pathname", "set", "securerandom"     # Declare library signatures to load
            using hook.refinement
          <%- class_methods.each do |method_name, definition| %>
            def test_class_method_<%= test_name_for(method_name) %>
            <%- definition.method_types.each do |method_type| -%>
              # <%= method_type %>
              <%= klass %>.<%= method_name %>
            <%- end -%>
            end
          <%- end -%>
          <%- instance_methods.each do |method_name, definition| %>
            def test_<%= test_name_for(method_name) %>
            <%- definition.method_types.each do |method_type| -%>
              # <%= method_type %>
              <%= klass %>.new.<%= method_name %>
            <%- end -%>
            end
          <%- end -%>
          end
        ERB
      end

      private

      def test_name_for(method_name)
        {
          :==  => 'double_equal',
          :!=  => 'not_equal',
          :=== => 'triple_equal',
          :[]  => 'square_bracket',
          :[]= => 'square_bracket_assign',
          :>   => 'greater_than',
          :<   => 'less_than',
          :>=  => 'greater_than_equal_to',
          :<=  => 'less_than_equal_to',
          :<=> => 'spaceship',
          :+   => 'plus',
          :-   => 'minus',
          :*   => 'multiply',
          :/   => 'divide',
          :**  => 'power',
          :%   => 'modulus',
          :&   => 'and',
          :|   => 'or',
          :^   => 'xor',
          :>>  => 'right_shift',
          :<<  => 'left_shift',
          :=~  => 'pattern_match',
          :!~  => 'does_not_match',
          :~   => 'tilde'
        }.fetch(method_name, method_name)
      end

      def type_name
        @type_name ||= Ruby::Signature::TypeName.new(name: klass.to_sym, namespace: Ruby::Signature::Namespace.new(path: [], absolute: true))
      end

      def class_methods
        @class_methods ||= Ruby::Signature::DefinitionBuilder.new(env: env).build_singleton(type_name).methods.select {|_, definition|
          definition.implemented_in.name.absolute! == type_name
        }
      end

      def instance_methods
        @instance_methods ||= Ruby::Signature::DefinitionBuilder.new(env: env).build_instance(type_name).methods.select {|_, definition|
          definition.implemented_in.name.absolute! == type_name
        }
      end
    end

    path.write TestTemplateBuilder.new(klass).call

    puts "Created: #{path}"
  end
end

CLEAN.include("lib/rbs/parser.rb")
