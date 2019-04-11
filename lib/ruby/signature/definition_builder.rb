module Ruby
  module Signature
    class DefinitionBuilder
      class InvalidTypeApplicationError < StandardError
        attr_reader :type_name
        attr_reader :args
        attr_reader :params
        attr_reader :location

        def initialize(type_name:, args:, params:, location:)
          @type_name = type_name
          @args = args
          @params = params
          @location = location
          loc = if location
                  "#{location.name}:#{location}"
                else
                  "*:*:*...*:*"
                end
          super "#{loc}: #{type_name} expects parameters [#{params.join(", ")}], but given args [#{args.join(", ")}]"
        end

        def self.check!(type_name:, args:, params:, location:)
          unless args.size == params.size
            raise new(type_name: type_name, args: args, params: params, location: location)
          end
        end
      end

      class RecursiveAncestorError < StandardError
        attr_reader :ancestors
        attr_reader :location

        def initialize(ancestors:, location:)
          loc = if location
                  "#{location.name}:#{location}"
                else
                  "*:*:*...*:*"
                end

          last = case last = ancestors.last
                 when Definition::Ancestor::Singleton
                   "singleton(#{last.name})"
                 when Definition::Ancestor::Instance
                   if last.args.empty?
                     last.name.to_s
                   else
                     "#{last.name}[#{last.args.join(", ")}]"
                   end
                 end
          super "#{loc}: Detected recursive ancestors: #{last}"
        end

        def self.check!(self_ancestor, ancestors:, location:)
          case self_ancestor
          when Definition::Ancestor::Instance
            if ancestors.any? {|a| a.is_a?(Definition::Ancestor::Instance) && a.name == self_ancestor.name }
              raise new(ancestors: ancestors + [self_ancestor], location: location)
            end
          when Definition::Ancestor::Singleton
            if ancestors.include?(self_ancestor)
              raise new(ancestors: ancestors + [self_ancestor], location: location)
            end
          end
        end
      end

      attr_reader :env
      attr_reader :instance_cache
      attr_reader :singleton_cache

      def initialize(env:)
        @env = env
        @instance_cache = {}
        @singleton_cache = {}
      end

      def build_ancestors(self_ancestor, ancestors: [], building_ancestors: [], location: nil)
        decl = env.find_class(self_ancestor.name)
        namespace = self_ancestor.name.absolute!.to_namespace

        RecursiveAncestorError.check!(self_ancestor,
                                      ancestors: building_ancestors,
                                      location: location || decl.location)
        building_ancestors.push self_ancestor

        case self_ancestor
        when Definition::Ancestor::Instance
          args = self_ancestor.args
          params = decl.type_params

          InvalidTypeApplicationError.check!(
            type_name: self_ancestor.name,
            args: args,
            params: params,
            location: location || decl.location
          )

          sub = Substitution.build(params, args)

          case decl
          when AST::Declarations::Class
            unless self_ancestor.name == BuiltinNames::BasicObject.name
              super_ancestor = decl.super_class&.yield_self do |super_class|
                Definition::Ancestor::Instance.new(
                  name: absolute_class_name(super_class.name, namespace: namespace),
                  args: super_class.args.map {|ty| absolute_type(ty.sub(sub), namespace: namespace) }
                )
              end || Definition::Ancestor::Instance.new(name: BuiltinNames::Object.name, args: [])

              build_ancestors(super_ancestor, ancestors: ancestors, building_ancestors: building_ancestors)
            end
          end

          decl.members.each do |member|
            case member
            when AST::Members::Include
              if member.name.class?
                ancestor = Definition::Ancestor::Instance.new(
                  name: absolute_class_name(member.name, namespace: namespace),
                  args: member.args.map {|ty| absolute_type(ty.sub(sub), namespace: namespace) }
                )
                build_ancestors ancestor, ancestors: ancestors, building_ancestors: building_ancestors, location: member.location
              end
            end
          end

          ancestors.unshift(self_ancestor)

          decl.members.each do |member|
            case member
            when AST::Members::Prepend
              ancestor = Definition::Ancestor::Instance.new(
                name: absolute_class_name(member.name, namespace: namespace),
                args: member.args.map {|ty| absolute_type(ty.sub(sub), namespace: namespace) }
              )
              build_ancestors ancestor, ancestors: ancestors, building_ancestors: building_ancestors, location: member.location
            end
          end
        when Definition::Ancestor::Singleton
          case decl
          when AST::Declarations::Class
            if self_ancestor.name == BuiltinNames::BasicObject.name
              class_ancestor = Definition::Ancestor::Instance.new(
                name: BuiltinNames::Class.name,
                args: []
              )
              build_ancestors class_ancestor, ancestors: ancestors, building_ancestors: building_ancestors
            else
              super_ancestor = decl.super_class&.yield_self do |super_class|
                Definition::Ancestor::Singleton.new(
                  name: absolute_class_name(super_class.name, namespace: namespace)
                )
              end || Definition::Ancestor::Singleton.new(name: BuiltinNames::Object.name)

              build_ancestors(super_ancestor, ancestors: ancestors, building_ancestors: building_ancestors)
            end
          when AST::Declarations::Module
            module_ancestor = Definition::Ancestor::Instance.new(
              name: BuiltinNames::Module.name,
              args: []
            )
            build_ancestors module_ancestor, ancestors: ancestors, building_ancestors: building_ancestors
          end

          decl.members.each do |member|
            case member
            when AST::Members::Extend
              if member.name.class?
                ancestor = Definition::Ancestor::Instance.new(
                  name: absolute_class_name(member.name, namespace: namespace),
                  args: member.args.map {|ty| absolute_type(ty.sub(sub), namespace: namespace) }
                )
                build_ancestors ancestor, ancestors: ancestors, building_ancestors: building_ancestors, location: member.location
              end
            end
          end

          ancestors.unshift(self_ancestor)
        end

        building_ancestors.pop

        ancestors
      end

      def build_one_instance(type_name)
        decl = env.find_class(type_name)

        case decl
        when AST::Declarations::Module, AST::Declarations::Class
          self_type = Types::ClassInstance.new(name: type_name,
                                               args: Types::Variable.build(decl.type_params),
                                               location: nil)

          ancestors = [Definition::Ancestor::Instance.new(name: type_name, args: self_type.args)]
          namespace = type_name.to_namespace

          Definition.new(declaration: decl, self_type: self_type, ancestors: ancestors).tap do |definition|
            each_member_with_accessibility decl.members do |member, accessibility|
              case member
              when AST::Members::MethodDefinition
                if member.instance?
                  name = member.name
                  method_types = member.types.map do |method_type|
                    method_type.map_type do |type|
                      absolute_type(type, namespace: namespace)
                    end
                  end
                  definition.methods[name] = Definition::Method.new(super_method: nil,
                                                                    method_types: method_types,
                                                                    defined_in: decl,
                                                                    implemented_in: decl,
                                                                    accessibility: accessibility)
                end
              when AST::Members::Include
                if member.name.interface?
                  interface_definition = build_one_instance(member.name)
                  sub = Substitution.build(interface_definition.type_params, member.args)
                  method_types = member.types.map do |method_type|
                    method_type.sub(sub).map_type do |type|
                      absolute_type(type, namespace: namespace)
                    end
                  end
                  interface_definition.methods.each do |name, method|
                    definition.methods[name] = Definition::Method.new(
                      super_method: nil,
                      method_types: method_types,
                      defined_in: method.defined_in,
                      implemented_in: decl,
                      accessibility: method.accessibility
                    )
                  end
                end
              end
            end
          end
        when AST::Declarations::Interface
          build_interface type_name, decl
        end
      end

      def each_member_with_accessibility(members, accessibility: :public)
        members.each do |member|
          case member
          when AST::Members::Public
            accessibility = :public
          when AST::Members::Private
            accessibility = :private
          else
            yield member, accessibility
          end
        end
      end

      def build_one_singleton(type_name)
        decl = env.find_class(type_name)

        case decl
        when AST::Declarations::Module, AST::Declarations::Class
          self_type = Types::ClassSingleton.new(name: type_name, location: nil)
          ancestors = [Definition::Ancestor::Singleton.new(name: type_name)]
          namespace = type_name.to_namespace

          Definition.new(declaration: decl, self_type: self_type, ancestors: ancestors).tap do |definition|
            each_member_with_accessibility decl.members do |member, accessibility|
              case member
              when AST::Members::MethodDefinition
                if member.singleton?
                  name = member.name
                  method_types = member.types.map do |method_type|
                    method_type.map_type do |type|
                      absolute_type(type, namespace: namespace)
                    end
                  end
                  definition.methods[name] = Definition::Method.new(super_method: nil,
                                                                    method_types: method_types,
                                                                    defined_in: decl,
                                                                    implemented_in: decl,
                                                                    accessibility: accessibility)
                end
              when AST::Members::Extend
                if member.name.interface?
                  interface_definition = build_one_instance(member.name)
                  sub = Substitution.build(interface_definition.type_params, member.args)
                  method_types = member.types.map do |method_type|
                    method_type.sub(sub).map_type do |type|
                      absolute_type(type, namespace: namespace)
                    end
                  end
                  interface_definition.methods.each do |name, method|
                    definition.methods[name] = Definition::Method.new(
                      super_method: nil,
                      method_types: method_types,
                      defined_in: method.defined_in,
                      implemented_in: decl,
                      accessibility: method.accessibility
                    )
                  end
                end
              end
            end
          end
        end
      end

      def build_instance(type_name)
        try_cache type_name, cache: instance_cache do
          decl = env.find_class(type_name)
          self_ancestor = Definition::Ancestor::Instance.new(name: type_name,
                                                             args: Types::Variable.build(decl.type_params))
          self_type = Types::ClassInstance.new(name: type_name, args: self_ancestor.args, location: nil)

          case decl
          when AST::Declarations::Class, AST::Declarations::Module
            ancestors = build_ancestors(self_ancestor)
            definition_pairs = ancestors.map do |ancestor|
              case ancestor
              when Definition::Ancestor::Instance
                [ancestor, build_one_instance(ancestor.name)]
              when Definition::Ancestor::Singleton
                [ancestor, build_one_singleton(ancestor.name)]
              end
            end

            merge_definitions(definition_pairs, decl: decl, self_type: self_type, ancestors: ancestors)
          end
        end
      end

      def build_singleton(type_name)
        try_cache type_name, cache: singleton_cache do
          decl = env.find_class(type_name)
          self_ancestor = Definition::Ancestor::Singleton.new(name: type_name)
          self_type = Types::ClassSingleton.new(name: type_name, location: nil)

          case decl
          when AST::Declarations::Class, AST::Declarations::Module
            ancestors = build_ancestors(self_ancestor)
            definition_pairs = ancestors.map do |ancestor|
              case ancestor
              when Definition::Ancestor::Instance
                [ancestor, build_one_instance(ancestor.name)]
              when Definition::Ancestor::Singleton
                [ancestor, build_one_singleton(ancestor.name)]
              end
            end

            definition_pairs.find {|ancestor, _| ancestor == self_ancestor }.tap do |_, definition|
              unless definition.methods[:new]&.implemented_in == decl
                instance_definition = build_instance(type_name)
                type_params = decl.type_params
                initialize_method = instance_definition.methods[:initialize]
                method_types = initialize_method.method_types.map do |method_type|
                  case method_type
                  when MethodType
                    fvs = method_type.free_variables
                    unless fvs.empty?
                      bound_variables = method_type.type_params
                      renamed_types = bound_variables.map {|x| Types::Variable.fresh(x) }
                      sub = Substitution.build(bound_variables, renamed_types)
                      type_params = renamed_types.unshift(*type_params)
                    else
                      sub = Substitution.build([], [])
                      type_params = method_type.type_params
                    end

                    MethodType.new(
                      type_params: type_params,
                      type: method_type.type.sub(sub).with_return_type(instance_definition.self_type),
                      block: method_type.block&.sub(sub),
                      location: method_type.location
                    )
                  end
                end.compact

                definition.methods[:new] = Definition::Method.new(
                  super_method: nil,
                  defined_in: nil,
                  implemented_in: decl,
                  method_types: method_types,
                  accessibility: :public
                )
              end
            end

            merge_definitions(definition_pairs, decl: decl, self_type: self_type, ancestors: ancestors)
          end
        end
      end

      def merge_definitions(pairs, decl:, self_type:, ancestors:)
        Definition.new(declaration: decl, self_type: self_type, ancestors: ancestors).tap do |definition|
          pairs.reverse_each do |(ancestor, current_definition)|
            sub = case ancestor
                  when Definition::Ancestor::Instance
                    Substitution.build(current_definition.type_params, ancestor.args)
                  when Definition::Ancestor::Singleton
                    Substitution.build([], [])
                  end
            namespace = current_definition.name.absolute!.to_namespace

            current_definition.methods.each do |name, method|
              merge_method definition.methods, name, method, sub, namespace
            end
          end
        end
      end

      def merge_method(methods, name, method, sub, namespace)
        super_method = methods[name]

        methods[name] = Definition::Method.new(
          method_types: method.method_types.flat_map do |method_type|
            case method_type
            when MethodType
              [absolute_type(method_type.sub(sub), namespace: namespace)]
            when :super
              super_method.method_types
            end
          end,
          super_method: super_method,
          defined_in: method.defined_in,
          implemented_in: method.implemented_in,
          accessibility: method.accessibility
        )
      end

      def try_cache(type_name, cache:)
        cached = cache[type_name]

        case cached
        when Definition
          cached
        when false
          raise
        when nil
          cache[type_name] = false
          cache[type_name] = yield
        end
      end

      def build_interface(type_name, declaration)
        self_type = Types::Interface.new(
          name: type_name,
          args: declaration.type_params.map {|x| Types::Variable.new(name: x, location: nil) },
          location: nil
        )

        namespace = type_name.to_namespace

        Definition.new(declaration: declaration, self_type: self_type, ancestors: []).tap do |definition|
          declaration.members.each do |member|
            case member
            when AST::Members::Include
              mixin_name = env.absolute_interface_name(member.name, namespace: namespace) || member.name.absolute!
              mixin = build_one_instance(mixin_name)

              args = member.args.map {|type| absolute_type(type, namespace: namespace) }
              type_params = mixin.declaration.type_params

              InvalidTypeApplicationError.check!(
                type_name: type_name,
                args: args,
                params: type_params,
                location: member.location
              )

              sub = Substitution.build(type_params, args)
              mixin.methods.each do |name, method|
                definition.methods[name] = method.sub(sub)
              end
            end
          end

          declaration.members.each do |member|
            case member
            when AST::Members::MethodDefinition
              method = Definition::Method.new(
                super_method: nil,
                method_types: member.types.map do |method_type|
                  method_type.map_type {|ty| absolute_type(ty, namespace: namespace) }
                end,
                defined_in: declaration,
                implemented_in: nil,
                accessibility: :public
              )
              definition.methods[member.name] = method
            end
          end
        end
      end

      def absolute_class_name(type_name, namespace:)
        env.absolute_class_name(type_name, namespace: namespace) || type_name.absolute!
      end

      def absolute_interface_name(type_name, namespace:)
        env.absolute_interface_name(type_name, namespace: namespace) || type_name.absolute!
      end

      def absolute_type(type, namespace:)
        case type
        when Types::ClassSingleton
          absolute_name = absolute_class_name(type.name, namespace: namespace)
          Types::ClassSingleton.new(name: absolute_name, location: type.location)
        when Types::ClassInstance
          absolute_name = absolute_class_name(type.name, namespace: namespace)
          Types::ClassInstance.new(name: absolute_name,
                                   args: type.args.map {|ty| absolute_type(ty, namespace: namespace) },
                                   location: type.location)
        when Types::Interface
          absolute_name = absolute_interface_name(type.name, namespace: namespace)
          Types::Interface.new(name: absolute_name,
                               args: type.args.map {|ty| absolute_type(ty, namespace: namespace) },
                               location: type.location)
        when Types::Alias
          absolute_name = env.absolute_alias_name(type.name, namespace: namespace) || type.name.absolute!
          Types::Alias.new(name: absolute_name, location: type.location)
        when Types::Tuple
          Types::Tuple.new(
            types: type.types.map {|ty| absolute_type(ty, namespace: namespace) },
            location: type.location
          )
        when Types::Record
          Types::Record.new(
            fields: type.fields.transform_values {|ty| absolute_type(ty, namespace: namespace) },
            location: type.location
          )
        when Types::Union
          Types::Union.new(
            types: type.types.map {|ty| absolute_type(ty, namespace: namespace) },
            location: type.location
          )
        when Types::Intersection
          Types::Intersection.new(
            types: type.types.map {|ty| absolute_type(ty, namespace: namespace) },
            location: type.location
          )
        when Types::Optional
          Types::Optional.new(
            type: absolute_type(type.type, namespace: namespace),
            location: type.location
          )
        when Types::Proc
          Types::Proc.new(
            type: type.type.map_type {|ty| absolute_type(ty, namespace: namespace) },
            location: type.location
          )
        else
          type
        end
      end
    end
  end
end
