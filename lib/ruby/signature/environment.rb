module Ruby
  module Signature
    class Environment
      attr_reader :buffers
      attr_reader :declarations

      attr_reader :name_to_decl
      attr_reader :name_to_extensions
      attr_reader :name_to_constant
      attr_reader :name_to_global
      attr_reader :name_to_alias

      def initialize
        @buffers = []
        @declarations = []

        @name_to_decl = {}
        @name_to_extensions = {}
        @name_to_constant = {}
        @name_to_global = {}
        @name_to_alias = {}
      end

      def <<(decl)
        declarations << decl
        case decl
        when AST::Declarations::Class, AST::Declarations::Module, AST::Declarations::Interface
          name_to_decl[decl.name.absolute!] = decl
        when AST::Declarations::Extension
          yield_self do
            name = decl.name.absolute!
            exts = name_to_extensions.fetch(name) do
              name_to_extensions[name] = []
            end
            exts << decl
          end
        when AST::Declarations::Alias
          name_to_alias[decl.name.absolute!] = decl
        when AST::Declarations::Constant
          name_to_constant[decl.name.absolute!] = decl
        when AST::Declarations::Global
          name_to_global[decl.name] = decl
        end
      end

      def find_class(type_name)
        name_to_decl[type_name]
      end

      def each_decl
        if block_given?
          name_to_decl.each_key do |name|
            yield name
          end
        else
          enum_for :each_decl
        end
      end

      def each_class_name(&block)
        each_decl.select {|name| class?(name) }.each &block
      end

      def class?(type_name)
        find_class(type_name)&.is_a?(AST::Declarations::Class)
      end

      def find_type_decl(type_name)
        name_to_decl[type_name]
      end

      def find_extensions(type_name)
        name_to_extensions[type_name] || []
      end

      def absolute_type_name(name, environment:, namespace:)
        raise "Namespace should be absolute: #{namespace}" unless namespace.absolute?
        raise "Namespace cannot be empty: #{namespace}" if namespace.empty?

        if name.absolute?
          name
        else
          absolute_name = name.with_prefix(namespace)

          if environment.key?(absolute_name)
            absolute_name
          else
            parent = namespace.parent
            if parent.empty?
              nil
            else
              absolute_type_name name, environment: environment, namespace: parent
            end
          end
        end
      end

      def absolute_class_name(name, namespace:)
        raise "Class name expected: #{name}" unless name.class?
        absolute_type_name name, environment: name_to_decl, namespace: namespace
      end

      def absolute_interface_name(name, namespace:)
        raise "Interface name expected: #{name}" unless name.interface?
        absolute_type_name name, environment: name_to_decl, namespace: namespace
      end

      def absolute_alias_name(name, namespace:)
        raise "Alias name expected: #{name}" unless name.alias?
        absolute_type_name name, environment: name_to_alias, namespace: namespace
      end
    end
  end
end
