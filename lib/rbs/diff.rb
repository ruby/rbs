# frozen_string_literal: true

module RBS
  class Diff
    class CLI
      def initialize(argv:, library_options:, stdout: $stdout, stderr: $stderr)
        @format = nil
        @stdout = stdout
        @stderr = stderr

        type_name = nil
        library_options = library_options
        before_path = []
        after_path = []

        opt = OptionParser.new do |o|
          o.banner = <<~HELP
            [Experimental] This command is experimental. API and output compatibility is not guaranteed.

            Usage:
              rbs diff --format markdown --type-name Foo --before before_sig --after after_sig

            Print diff for rbs environment dir

            Examples:

              # Diff dir1 and dir2 for Foo
              $ rbs diff --format markdown --type-name Foo --before dir1 --after dir2

              # Confirmation of methods related to Time class added by including stdlib/time
              $ rbs diff --format diff --type-name Time --after stdlib/time
          HELP
          o.on("--format NAME")    { |arg| @format = arg }
          o.on("--type-name NAME") { |arg| type_name = arg }
          o.on("--before DIR")     { |arg| before_path << arg }
          o.on("--after DIR")      { |arg| after_path << arg }
        end
        opt.parse!(argv)

        unless @format && type_name && ["markdown", "diff"].include?(@format)
          @stderr.puts opt.banner
          exit 1
        end

        @diff = Diff.new(
          type_name: TypeName(type_name).absolute!,
          library_options: library_options,
          after_path: after_path,
          before_path: before_path
        )
      end

      def run
        public_send("run_#{@format}")
      end

      def run_diff
        first = true
        @diff.each_diff do |before, after|
          @stdout.puts if !first
          @stdout.puts "- #{before}"
          @stdout.puts "+ #{after}"
          first = false
        end
      end

      def run_markdown
        @stdout.puts "| before | after |"
        @stdout.puts "| --- | --- |"
        @diff.each_diff do |before, after|
          before.gsub!("|", "\\|")
          after.gsub!("|", "\\|")
          @stdout.puts "| `#{before}` | `#{after}` |"
        end
      end
    end

    def initialize(type_name:, library_options:, after_path: [], before_path: [])
      @type_name = type_name
      @library_options = library_options
      @after_path = after_path
      @before_path = before_path
    end

    def each_diff(&block)
      return to_enum(:each_diff) unless block

      before_instance_methods, before_singleton_methods, before_constant_decls = build_methods(@before_path)
      after_instance_methods, after_singleton_methods, after_constant_decls = build_methods(@after_path)

      each_diff_methods(:instance, before_instance_methods, after_instance_methods, &block)
      each_diff_methods(:singleton, before_singleton_methods, after_singleton_methods, &block)

      each_diff_constants(before_constant_decls, after_constant_decls, &block)
    end

    private

    def each_diff_methods(kind, before_methods, after_methods)
      all_keys = before_methods.keys.to_set + after_methods.keys.to_set
      all_keys.each do |key|
        before = definition_method_to_s(key, kind, before_methods[key]) or next
        after = definition_method_to_s(key, kind, after_methods[key]) or next
        next if before == after

        yield before, after
      end
    end

    def each_diff_constants(before_constant_decls, after_constant_decls)
      all_keys = before_constant_decls.keys.to_set + after_constant_decls.keys.to_set
      all_keys.each do |key|
        before = constant_to_s(key, before_constant_decls[key]) or next
        after = constant_to_s(key, after_constant_decls[key]) or next
        next if before == after

        yield before, after
      end
    end

    def build_methods(path)
      env = build_env(path)
      builder = build_builder(env)

      instance_methods = begin
        builder.build_instance(@type_name).methods
      rescue => e
        RBS.logger.warn("#{path}: #{e.message}")
        {}
      end
      singleton_methods = begin
        builder.build_singleton(@type_name).methods
      rescue => e
        RBS.logger.warn("#{path}: #{e.message}")
        {}
      end
      type_name_to_s = @type_name.to_s
      constant_decls = env.constant_decls.select { |key| key.to_s.start_with?(type_name_to_s) }

      [ instance_methods, singleton_methods, constant_decls ]
    end

    def build_env(path)
      loader = @library_options.loader()
      path&.each do |dir|
        loader.add(path: Pathname(dir))
      end
      Environment.from_loader(loader)
    end

    def build_builder(env)
      DefinitionBuilder.new(env: env.resolve_type_names)
    end

    def definition_method_to_s(key, kind, definition_method)
      if definition_method
        prefix = kind == :instance ? "" : "self."

        if definition_method.alias_of
          "alias #{prefix}#{key} #{prefix}#{definition_method.alias_of.defs.first.member.name}"
        else
          "def #{prefix}#{key}: #{definition_method.method_types.join(" | ")}"
        end
      else
        "-"
      end
    end

    def constant_to_s(key, constant)
      if constant
        "#{key}: #{constant.decl.type}"
      else
        "-"
      end
    end
  end
end
