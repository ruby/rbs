# frozen_string_literal: true

module RBS
  class Environment
    class ModuleEntry
      attr_reader :name

      attr_reader :context_decls

      def initialize(name)
        @name = name
        @context_decls = []
      end

      def <<(context_decl)
        context_decls << context_decl
        self
      end

      def each_decl(&block)
        if block
          context_decls.each do |_, decl|
            yield decl
          end
        else
          enum_for(__method__ || raise)
        end
      end

      def empty?
        context_decls.empty?
      end

      def primary_decl
        each_decl.first or raise
      end

      def type_params
        validate_type_params
        primary_decl.type_params
      end

      def self_types
        params = type_params
        param_names = params.map(&:name)

        each_decl.flat_map do |decl|
          self_types = decl.self_types
          decl_param_names = decl.type_params.map(&:name)

          if self_types.empty? || decl_param_names == param_names
            self_types
          else
            # The declaration uses different type parameter names from the primary declaration.
            # Rename the type variables in the self types, so that they are aligned to `#type_params`.
            subst = Substitution.build(
              decl_param_names,
              params.map {|param| Types::Variable.new(name: param.name, location: param.location) }
            )

            self_types.map do |self_type|
              AST::Declarations::Module::Self.new(
                name: self_type.name,
                args: self_type.args.map {|type| type.sub(subst) },
                location: self_type.location
              )
            end
          end
        end.uniq
      end

      def validate_type_params
        unless context_decls.empty?
          first_decl, *rest_decls = each_decl.to_a
          first_decl or raise

          first_params = first_decl.type_params
          first_names = first_params.map(&:name)
          rest_decls.each do |other_decl|
            other_params = other_decl.type_params
            unless first_names.size == other_params.size && first_params == AST::TypeParam.rename(other_params, new_names: first_names)
              raise GenericParameterMismatchError.new(name: name, decl: other_decl)
            end
          end
        end
      end
    end
  end
end
