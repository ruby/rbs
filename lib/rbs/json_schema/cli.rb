require "optparse"
require "uri"
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

      def run(args)
        OptionParser.new do |opts|
          opts.on("--[no-]stringify-keys", "Generate record types with string keys") do |bool|
            @options[:stringify_keys] = bool
          end

          opts.on("-o OUTPUT", "Output the generated RBS to a specific location") do |location|
            @options[:output] = location
          end
        end.parse!(args)

        generator = JSONSchema::Generator.new(stringify_keys: @options[:stringify_keys], output: @options[:output], stdout: stdout, stderr: stderr)
        args.each do |path|
          begin
            path = Pathname(path).realpath
          rescue Errno::ENOENT => _
            raise ValidationError.new(message: "#{path}: No such file or directory found!")
          end
          case
          when path.file?
            generator.generate(URI.parse("file://#{path}"))
          when path.directory?
            # Iterate over all JSON files present in the directory
            ## Ruby 3.0+ returns files in a sorted order & provides an option to obtain sorted result ##
            (RUBY_VERSION >= '3.0' ? Dir["#{path}/*.{json}", sort: true] : Dir["#{path}/*.{json}"].sort).each do |file|
              file = Pathname(file).realpath
              generator.generate(URI.parse("file://#{file}"))
            end
          else
            raise ValidationError.new(message: "#{path}: No such file or directory found!")
          end
        end
        generator.write_output
      end
    end
  end
end
