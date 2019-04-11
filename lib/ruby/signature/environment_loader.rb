module Ruby
  module Signature
    class EnvironmentLoader
      attr_reader :env
      attr_reader :paths
      attr_accessor :stdlib_root

      def initialize(env:, stdlib_root: Pathname(__dir__) + "../../../stdlib")
        @env = env
        @stdlib_root = stdlib_root
        @paths = []
      end

      def add(path: nil, library: nil)
        case
        when path
          @paths << path
        when library
          @paths << library
        end
      end

      def stdlib?(name)
        stdlib_root && (stdlib_root + name).directory?
      end

      def each_signature(path, immediate: true, &block)
        if block_given?
          case
          when path.file?
            if path.extname == ".rbi" || immediate
              yield path
            end
          when path.directory?
            path.children.each do |child|
              each_signature child, immediate: false, &block
            end
          end
        else
          enum_for :each_signature, path, immediate: immediate
        end
      end

      def library_path(name)
        if stdlib?(name)
          stdlib_root + name
        else
          raise "Unknown library: name=#{name}"
        end
      end

      def load
        signature_files = []

        if stdlib_root
          signature_files.push *each_signature(stdlib_root + "builtin")
        end

        paths.each do |path|
          case path
          when Pathname
            signature_files.push *each_signature(path)
          when String
            signature_files.push *each_signature(library_path(path))
          end
        end

        signature_files.each do |file|
          buffer = Buffer.new(name: file.to_s, content: file.read)
          env.buffers.push(buffer)
          Parser.parse_signature(buffer).each do |decl|
            env << decl
          end
        end
      end
    end
  end
end
