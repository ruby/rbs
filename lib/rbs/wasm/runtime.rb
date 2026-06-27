# frozen_string_literal: true

require "java"
require "monitor"
require_relative "jars"

module RBS
  module WASM
    # Loads rbs_parser.wasm into a JVM WebAssembly runtime (Chicory) and drives
    # it. This is the JRuby counterpart of the C extension's main.c: it copies a
    # source string into the module's linear memory, runs the parser, and returns
    # the serialized result for RBS::WASM::Deserializer to rebuild.
    #
    # Chicory is a pure-Java runtime, so there is no native dependency: only the
    # `.wasm` and the Chicory jars need to ship with the gem.
    class Runtime
      include MonitorMixin

      class << self
        def instance
          @instance ||= new
        end

        def wasm_path
          ENV["RBS_WASM_PARSER"] || File.expand_path("rbs_parser.wasm", __dir__)
        end

        # A directory of jars vendored for running from source (development/CI),
        # set by `rake wasm:vendor_jars` or `RBS_WASM_JARS`. Returns nil for an
        # installed gem, where the jars come from Maven via jar-dependencies.
        def local_jars_dir
          dir = ENV["RBS_WASM_JARS"] || File.expand_path("jars", __dir__)
          File.directory?(dir) ? dir : nil
        end
      end

      def initialize
        super()
        load_jars
        @wasm = build_instance
        @memory = @wasm.memory
        @alloc = @wasm.export("rbs_wasm_alloc")
        @free = @wasm.export("rbs_wasm_free")
        @result_ptr = @wasm.export("rbs_wasm_result_ptr")
        @result_len = @wasm.export("rbs_wasm_result_len")
        @parse_signature = @wasm.export("rbs_wasm_parse_signature")
        @parse_type = @wasm.export("rbs_wasm_parse_type")
        @parse_method_type = @wasm.export("rbs_wasm_parse_method_type")
        @parse_type_params = @wasm.export("rbs_wasm_parse_type_params")
        @parse_inline_leading_annotation = @wasm.export("rbs_wasm_parse_inline_leading_annotation")
        @parse_inline_trailing_annotation = @wasm.export("rbs_wasm_parse_inline_trailing_annotation")
        @lex = @wasm.export("rbs_wasm_lex")
      end

      # `content` is the whole buffer; `start_pos`/`end_pos` are the character
      # range within it to parse. Each method returns [success, bytes]: on success
      # `bytes` is the serialized AST, otherwise it is the error blob (see
      # set_error_result in rbs_wasm.c).

      def parse_signature(content, encoding, start_pos, end_pos)
        run(content, encoding) { |ptr, len, enc_ptr, enc_len| @parse_signature.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos)[0] }
      end

      def parse_type(content, encoding, start_pos, end_pos, variables, require_eof, void_allowed, self_allowed, classish_allowed)
        with_variables(variables) do |vars_ptr, vars_len|
          run(content, encoding) do |ptr, len, enc_ptr, enc_len|
            @parse_type.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos, vars_ptr, vars_len, bool(require_eof), bool(void_allowed), bool(self_allowed), bool(classish_allowed))[0]
          end
        end
      end

      def parse_method_type(content, encoding, start_pos, end_pos, variables, require_eof)
        with_variables(variables) do |vars_ptr, vars_len|
          run(content, encoding) do |ptr, len, enc_ptr, enc_len|
            @parse_method_type.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos, vars_ptr, vars_len, bool(require_eof))[0]
          end
        end
      end

      def parse_type_params(content, encoding, start_pos, end_pos, module_type_params)
        run(content, encoding) do |ptr, len, enc_ptr, enc_len|
          @parse_type_params.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos, bool(module_type_params))[0]
        end
      end

      def parse_inline_leading_annotation(content, encoding, start_pos, end_pos, variables)
        with_variables(variables) do |vars_ptr, vars_len|
          run(content, encoding) do |ptr, len, enc_ptr, enc_len|
            @parse_inline_leading_annotation.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos, vars_ptr, vars_len)[0]
          end
        end
      end

      def parse_inline_trailing_annotation(content, encoding, start_pos, end_pos, variables)
        with_variables(variables) do |vars_ptr, vars_len|
          run(content, encoding) do |ptr, len, enc_ptr, enc_len|
            @parse_inline_trailing_annotation.apply(ptr, len, enc_ptr, enc_len, start_pos, end_pos, vars_ptr, vars_len)[0]
          end
        end
      end

      def lex(content, encoding, end_pos)
        run(content, encoding) do |ptr, len, enc_ptr, enc_len|
          @lex.apply(ptr, len, enc_ptr, enc_len, end_pos)[0]
        end
      end

      private

      # Copies `source` and its encoding name into linear memory, yields their
      # pointers/lengths to the block (which invokes the parser and returns its
      # status), then reads the result back out. Serialized through the monitor
      # because the module keeps its result in a single shared location.
      def run(source, encoding)
        synchronize do
          bytes = source.b
          length = bytes.bytesize
          name = encoding.to_s.b
          name_length = name.bytesize
          source_ptr = @alloc.apply(length)[0]
          name_ptr = @alloc.apply(name_length)[0]
          begin
            @memory.write(source_ptr, bytes.to_java_bytes)
            @memory.write(name_ptr, name.to_java_bytes) unless name_length.zero?
            status = yield(source_ptr, length, name_ptr, name_length)
            [status == 1, read_result]
          ensure
            @free.apply(source_ptr)
            @free.apply(name_ptr)
          end
        end
      end

      def read_result
        pointer = @result_ptr.apply[0]
        length = @result_len.apply[0]
        return "".b if length.zero?

        String.from_java_bytes(@memory.read_bytes(pointer, length)).b
      end

      # Allocates a buffer of newline-separated variable names and yields its
      # pointer/length. A nil `variables` is passed as length -1 ("no variables").
      def with_variables(variables)
        names = variables&.map(&:to_s)&.join("\n")

        if names.nil? || names.empty?
          return yield(0, variables.nil? ? -1 : 0)
        end

        bytes = names.b
        length = bytes.bytesize
        synchronize do
          pointer = @alloc.apply(length)[0]
          begin
            @memory.write(pointer, bytes.to_java_bytes)
            yield(pointer, length)
          ensure
            @free.apply(pointer)
          end
        end
      end

      def bool(value)
        value ? 1 : 0
      end

      def build_instance
        parser = Java::ComDylibsoChicoryWasm::Parser
        instance_class = Java::ComDylibsoChicoryRuntime::Instance
        import_values = Java::ComDylibsoChicoryRuntime::ImportValues
        wasi_preview1 = Java::ComDylibsoChicoryWasi::WasiPreview1
        wasi_options = Java::ComDylibsoChicoryWasi::WasiOptions

        wasm_module = parser.parse(java.io.File.new(self.class.wasm_path))
        wasi = wasi_preview1.builder.with_options(wasi_options.builder.build).build
        imports = import_values.builder.add_function(wasi.to_host_functions).build

        builder = instance_class.builder(wasm_module).with_import_values(imports)
        if (factory = machine_factory(wasm_module))
          builder = builder.with_machine_factory(factory)
        end

        wasm = builder.build
        wasm.export("_initialize").apply
        wasm
      end

      # Chicory's AOT compiler when its jars are present and usable, otherwise nil
      # (the builder then uses the interpreter). NameError covers a missing
      # compiler class; LinkageError covers an incompatible/missing ASM (so a bad
      # jar set degrades to the interpreter instead of crashing).
      def machine_factory(wasm_module)
        Java::ComDylibsoChicoryCompiler::MachineFactoryCompiler.compile(wasm_module)
      rescue NameError, Java::JavaLang::LinkageError
        nil
      end

      # Puts the Chicory/ASM jars on the classpath. When running from source the
      # jars are vendored into a local directory (see `rake wasm:vendor_jars`) and
      # loaded by path; in the installed `-java` gem they are fetched from Maven
      # by jar-dependencies and loaded with `require_jar`. The optional AOT
      # compiler jars degrade gracefully: a missing or incompatible jar just
      # leaves Chicory on the interpreter (see #machine_factory).
      def load_jars
        if (dir = self.class.local_jars_dir)
          RBS::WASM::REQUIRED_JARS.each { |_group, artifact, _version| require File.join(dir, "#{artifact}.jar") }
          RBS::WASM::OPTIONAL_JARS.each do |_group, artifact, _version|
            path = File.join(dir, "#{artifact}.jar")
            require path if File.exist?(path)
          end
        else
          require "jar_dependencies"
          RBS::WASM::REQUIRED_JARS.each { |group, artifact, version| require_jar(group, artifact, version) }
          RBS::WASM::OPTIONAL_JARS.each do |group, artifact, version|
            begin
              require_jar(group, artifact, version)
            rescue LoadError, StandardError, Java::JavaLang::LinkageError
              # AOT compiler unavailable; the interpreter is used instead.
            end
          end
        end
      end
    end
  end
end
