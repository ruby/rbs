require "optparse"
require "rbs/json_schema/generator"

module RBS
  module JSONSchema
    class CLI
      attr_reader :stdout
      attr_reader :stderr

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
        @options = {}
      end

      def setup_initial_options(opts)
        opts.on("--[no-]stringify-keys", "Generate record types with string keys") do |bool|
          @options[:stringify_keys] = bool
        end
      end

      def run(args)
        OptionParser.new do |opts|
          setup_initial_options(opts)

          opts.on("-I DIR", "Directory containing a collection of JSON schema from which RBS is to be generated") do |dir|
            @options[:dir] = dir
          end
          opts.on("-o OUTPUT", "Output the generated RBS to a specific location") do |location|
            @options[:output] = location
          end
        end.parse!(args)

        @options[:file] = args[0] if args[0]
        JSONSchema::Generator.new(options: @options, stdout: stdout, stderr: stderr).generate
      end
    end
  end
end
