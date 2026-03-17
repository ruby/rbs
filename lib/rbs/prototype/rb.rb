# frozen_string_literal: true

module RBS
  module Prototype
    module RB
      def self.new
        if ENV['RBS_RUBY_PARSER'] == 'prism'
          RB::Prism.new
        else
          RB::RubyVM.new
        end
      end

      class Context < Struct.new(:module_function, :singleton, :namespace, :in_def, keyword_init: true)
        # @implements Context

        def self.initial(namespace: Namespace.root)
          self.new(module_function: false, singleton: false, namespace: namespace, in_def: false)
        end

        def method_kind
          if singleton
            :singleton
          elsif module_function
            :singleton_instance
          else
            :instance
          end
        end

        def attribute_kind
          if singleton
            :singleton
          else
            :instance
          end
        end

        def enter_namespace(namespace)
          Context.initial(namespace: self.namespace + namespace)
        end

        def update(module_function: self.module_function, singleton: self.singleton, in_def: self.in_def)
          Context.new(module_function: module_function, singleton: singleton, namespace: namespace, in_def: in_def)
        end
      end

      class Base
        include CommentParser

        attr_reader :source_decls
        attr_reader :toplevel_members

        def initialize
          @source_decls = []
        end

        def decls
          # @type var decls: Array[AST::Declarations::t]
          decls = []

          # @type var top_decls: Array[AST::Declarations::t]
          # @type var top_members: Array[AST::Members::t]
          top_decls, top_members = _ = source_decls.partition {|decl| decl.is_a?(AST::Declarations::Base) }

          decls.push(*top_decls)

          unless top_members.empty?
            top = AST::Declarations::Class.new(
              name: TypeName.new(name: :Object, namespace: Namespace.empty),
              super_class: nil,
              members: top_members,
              annotations: [],
              comment: nil,
              location: nil,
              type_params: []
            )
            decls << top
          end

          decls
        end

        def types_to_union_type(types)
          return untyped if types.empty?

          uniq = types.uniq
          if uniq.size == 1
            return uniq.first || raise
          end

          Types::Union.new(types: uniq, location: nil)
        end

        def range_element_type(types)
          types = types.reject { |t| t == untyped }
          return untyped if types.empty?

          types = types.map do |t|
            if t.is_a?(Types::Literal)
              type_name = TypeName.new(name: t.literal.class.name&.to_sym || raise, namespace: Namespace.root)
              Types::ClassInstance.new(name: type_name, args: [], location: nil)
            else
              t
            end
          end.uniq

          if types.size == 1
            types.first or raise
          else
            untyped
          end
        end

        def untyped
          @untyped ||= Types::Bases::Any.new(location: nil)
        end

        def private
          @private ||= AST::Members::Private.new(location: nil)
        end

        def public
          @public ||= AST::Members::Public.new(location: nil)
        end

        def current_accessibility(decls, index = decls.size)
          slice = decls.slice(0, index) or raise
          idx = slice.rindex { |decl| decl == private || decl == public }
          if idx
            _ = decls[idx]
          else
            public
          end
        end

        def remove_unnecessary_accessibility_methods!(decls)
          # @type var current: decl
          current = public
          idx = 0

          loop do
            decl = decls[idx] or break
            if current == decl
              decls.delete_at(idx)
              next
            end

            if 0 < idx && is_accessibility?(decls[idx - 1]) && is_accessibility?(decl)
              decls.delete_at(idx - 1)
              idx -= 1
              current = current_accessibility(decls, idx)
              next
            end

            current = decl if is_accessibility?(decl)
            idx += 1
          end

          decls.pop while decls.last && is_accessibility?(decls.last || raise)
        end

        def is_accessibility?(decl)
          decl == public || decl == private
        end

        def find_def_index_by_name(decls, name)
          index = decls.find_index do |decl|
            case decl
            when AST::Members::MethodDefinition, AST::Members::AttrReader
              decl.name == name
            when AST::Members::AttrWriter
              :"#{decl.name}=" == name
            end
          end

          if index
            [
              index,
              _ = decls[index]
            ]
          end
        end

        def sort_members!(decls)
          i = 0
          orders = {
            AST::Members::ClassVariable => -3,
            AST::Members::ClassInstanceVariable => -2,
            AST::Members::InstanceVariable => -1,
          } #: Hash[Class, Integer]
          decls.sort_by! { |decl| [orders.fetch(decl.class, 0), i += 1] }
        end
      end
    end
  end
end
