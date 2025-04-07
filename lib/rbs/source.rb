# frozen_string_literal: true

module RBS
  module Source
    class RBS
      attr_reader :buffer, :directives, :declarations

      def initialize(buffer, directives, decls)
        @buffer = buffer
        @directives = directives
        @declarations = decls
      end

      def each_type_name(&block)
        if block
          set = Set[] #: Set[TypeName]
          declarations.each do |decl|
            each_declaration_type_name(set, decl, &block)
          end
        else
          enum_for :each_type_name
        end
      end

      def each_declaration_type_name(names, decl, &block)
        case decl
        when AST::Declarations::Class
          decl.each_decl { each_declaration_type_name(names, _1, &block) }
          type_name = decl.name
        when AST::Declarations::Module
          decl.each_decl { each_declaration_type_name(names, _1, &block) }
          type_name = decl.name
        when AST::Declarations::Interface
          type_name = decl.name
        when AST::Declarations::TypeAlias
          type_name = decl.name
        when AST::Declarations::ModuleAlias
          type_name = decl.new_name
        when AST::Declarations::ClassAlias
          type_name = decl.new_name
        end

        if type_name
          unless names.include?(type_name)
            yield type_name
            names << type_name
          end
        end
      end
    end

    class Ruby
      attr_reader :buffer
      attr_reader :prism_result
      attr_reader :declarations
      attr_reader :diagnostics

      def initialize(buffer, prism, declarations, diagnostics)
        @buffer = buffer
        @prism_result = prism
        @declarations = declarations
        @diagnostics = diagnostics
      end

      def each_type_name(&block)
        if block
          names = Set[] #: Set[TypeName]
          declarations.each do |decl|
            each_declaration_type_name(names, decl, &block)
          end
        else
          enum_for :each_type_name
        end
      end

      def each_declaration_type_name(names, decl, &block)
        case decl
        when AST::Ruby::Declarations::ClassDecl
          decl.each_decl do |d|
            each_declaration_type_name(names, d, &block)
          end
          type_name = decl.class_name
        when AST::Ruby::Declarations::ModuleDecl
          decl.each_decl do |d|
            each_declaration_type_name(names, d, &block)
          end
          type_name = decl.module_name
        end

        if type_name
          unless names.include?(type_name)
            yield type_name
            names << type_name
          end
        end
      end
    end
  end
end
