# frozen_string_literal: true

module RBS
  module Prototype
    module RBI
      def self.new
        if ENV['RBS_RUBY_PARSER'] == 'prism'
          RBI::Prism.new
        else
          RBI::RubyVM.new
        end
      end

      class Base
        include CommentParser

        attr_reader :decls
        attr_reader :modules
        attr_reader :last_sig

        def initialize
          @decls = []
          @modules = []
        end

        def nested_name(name)
          (current_namespace + const_to_name(name).to_namespace).to_type_name.relative!
        end

        def current_namespace
          modules.inject(Namespace.empty) do |parent, mod|
            parent + mod.name.to_namespace
          end
        end

        def push_class(name, super_class, comment:)
          class_decl = AST::Declarations::Class.new(
            name: nested_name(name),
            super_class: super_class && AST::Declarations::Class::Super.new(name: const_to_name(super_class), args: [], location: nil),
            type_params: [],
            members: [],
            annotations: [],
            location: nil,
            comment: comment
          )

          modules << class_decl
          decls << class_decl

          yield
        ensure
          modules.pop
        end

        def push_module(name, comment:)
          module_decl = AST::Declarations::Module.new(
            name: nested_name(name),
            type_params: [],
            members: [],
            annotations: [],
            location: nil,
            self_types: [],
            comment: comment
          )

          modules << module_decl
          decls << module_decl

          yield
        ensure
          modules.pop
        end

        def current_module
          modules.last
        end

        def current_module!
          current_module or raise
        end

        def push_sig(node)
          if last_sig = @last_sig
            last_sig << node
          else
            @last_sig = [node]
          end
        end

        def pop_sig
          @last_sig.tap do
            @last_sig = nil
          end
        end
      end
    end
  end
end
