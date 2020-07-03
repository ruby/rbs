require "rbs"
require "rbs/test"

require "optparse"
require "shellwords"

logger = Logger.new(STDERR)

begin
  opts = Shellwords.shellsplit(ENV["RBS_TEST_OPT"] || "-I sig")
  filter = ENV.fetch("RBS_TEST_TARGET").split(",")
  skips = (ENV["RBS_TEST_SKIP"] || "").split(",")
  RBS.logger_level = (ENV["RBS_TEST_LOGLEVEL"] || "info")
rescue
  STDERR.puts "rbs/test/setup handles the following environment variables:"
  STDERR.puts "  [REQUIRED] RBS_TEST_TARGET: test target class name, `Foo::Bar,Foo::Baz` for each class or `Foo::*` for all classes under `Foo`"
  STDERR.puts "  [OPTIONAL] RBS_TEST_SKIP: skip testing classes"
  STDERR.puts "  [OPTIONAL] RBS_TEST_OPT: options for signatures (`-r` for libraries or `-I` for signatures)"
  STDERR.puts "  [OPTIONAL] RBS_TEST_LOGLEVEL: one of debug|info|warn|error|fatal (defaults to info)"
  STDERR.puts "  [OPTIONAL] RBS_TEST_ARRAY_NO_SAMPLE: if set, all the values of an Array object would be type-checked"
  STDERR.puts "  [OPTIONAL] RBS_TEST_ENUMERATOR_NO_SAMPLE: if set, all the values of an Enumerator object would be type-checked"
  STDERR.puts "  [OPTIONAL] RBS_TEST_HASH_NO_SAMPLE: if set, all the values of a Hash object would be type-checked"
  STDERR.puts "  [OPTIONAL] RBS_TEST_NO_SAMPLING: if set, all the values of any type of collection would be type-checked"
  STDERR.puts "  [OPTIONAL] RBS_TEST_SAMPLE_SIZE: sets the amount of values in a collection to be type-checked"
  exit 1
end

loader = RBS::EnvironmentLoader.new
OptionParser.new do |opts|
  opts.on("-r [LIB]") do |name| loader.add(library: name) end
  opts.on("-I [DIR]") do |dir| loader.add(path: Pathname(dir)) end
end.parse!(opts)

env = RBS::Environment.from_loader(loader).resolve_type_names

def match(filter, name)
  if filter.end_with?("*")
    name.start_with?(filter[0, filter.size - 1]) || name == filter[0, filter.size-3]
  else
    filter == name
  end
end

def true? obj
  !!obj || obj == "false"
end

factory = RBS::Factory.new()
tester = RBS::Test::Tester.new(env: env)

TracePoint.trace :end do |tp|
  class_name = tp.self.name&.yield_self {|name| factory.type_name(name).absolute! }

  if class_name
    if filter.any? {|f| match(f, class_name.to_s) } && skips.none? {|f| match(f, class_name.to_s) }
      if tester.checkers.none? {|hook| hook.klass == tp.self }
        if env.class_decls.key?(class_name)
          logger.info "Setting up hooks for #{class_name}"
          tester.install!(tp.self)
          # hooks << RBS::Test::Hook.install(env, tp.self, logger: logger, array_no_sample: true?(ENV['RBS_TEST_ARRAY_NO_SAMPLE']) ).verify_all.raise_on_error!(raise_on_error)
        end
      end
    end
  end
end
