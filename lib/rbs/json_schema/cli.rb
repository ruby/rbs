require "optparse"
require_relative "generator"

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
        opts.on("-sBOOL", "--symbolize-keys=BOOL", "Generate types with symbolized keys") do |bool|
          @options[:symbolize_keys] = bool
        end
      end

      def run
        OptionParser.new do |opts|
          setup_initial_options(opts)

          opts.on("-I DIR", "Directory containing a collection of JSON schema from which RBS is to be generated") do |dir|
            @options[:dir] = dir
          end
          opts.on("-o OUTPUT", "Output the generated RBS to a specific location") do |location|
            @options[:output] = location
          end
        end.parse!(ARGV)

        @options[:file] = ARGV[0] if ARGV[0]
        JSONSchema::Generator.new(options: @options, stdout: STDOUT, stderr: STDERR).generate
      end
    end
  end
end