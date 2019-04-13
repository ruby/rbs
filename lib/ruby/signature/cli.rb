require "optparse"

module Ruby
  module Signature
    class CLI
      class LibraryOptions
        attr_reader :libs
        attr_reader :dirs
        attr_accessor :no_stdlib

        def initialize()
          @libs = []
          @dirs = []
          @no_stdlib = false
        end

        def setup(loader)
          libs.each do |lib|
            loader.add(library: lib)
          end

          dirs.each do |dir|
            loader.add(path: Pathname(dir))
          end

          loader.stdlib_root = nil if no_stdlib

          loader
        end
      end

      attr_reader :stdout
      attr_reader :stderr

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      COMMANDS = [:ast, :version]

      def library_parse(opts, options:)
        opts.on("-r LIBRARY") do |lib|
          options.libs << lib
        end

        opts.on("-I DIR") do |dir|
          options.dirs << dir
        end

        opts.on("--no-stdlib") do
          options.no_stdlib = true
        end

        opts
      end

      def run(args)
        options = LibraryOptions.new

        OptionParser.new do |opts|
          library_parse(opts, options: options)
        end.parse!(args)

        command = args.shift&.to_sym

        if COMMANDS.include?(command)
          __send__ :"run_#{command}", args, options
        else
          run_help()
        end
      end

      def run_help
        stdout.puts "Available commands: #{COMMANDS.join(", ")}"
      end

      def run_ast(args, options)
        env = Environment.new()
        loader = EnvironmentLoader.new(env: env)

        options.setup(loader)

        loader.load

        stdout.print JSON.generate(env.declarations)
        stdout.flush
      end

      def run_version(args)
        stdout.puts "ruby-signature #{VERSION}"
      end
    end
  end
end
