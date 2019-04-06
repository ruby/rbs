require "optparse"

module Ruby
  module Signature
    class CLI
      attr_reader :stdout
      attr_reader :stderr

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      COMMANDS = [:ast, :version]

      def run(args)
        command = args.shift&.to_sym

        if COMMANDS.include?(command)
          __send__ :"run_#{command}", args
        else
          run_help()
        end
      end

      def run_help
        stdout.puts "Available commands: #{COMMANDS.join(", ")}"
      end

      def run_ast(args)
        env = Environment.new()
        loader = EnvironmentLoader.new(env: env)

        OptionParser.new do |opts|
          opts.on("-r LIBRARY") do |lib|
            loader.add(library: lib)
          end

          opts.on("--no-stdlib") do
            loader.stdlib_root = nil
          end
        end.parse!

        args.each do |path|
          loader.add(path: Pathname(path))
        end

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
