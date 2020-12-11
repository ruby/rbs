module RBS
  class DefinitionBuilder
    attr_reader :env
    attr_reader :type_name_resolver
    attr_reader :ancestor_builder

    attr_reader :instance_cache
    attr_reader :singleton_cache
    attr_reader :interface_cache

    attr_reader :one_instance_cache
    attr_reader :one_singleton_cache

    def initialize(env:)
      @env = env
      @type_name_resolver = TypeNameResolver.from_env(env)
      @ancestor_builder = AncestorBuilder.new(env: env)

      @instance_cache = {}
      @singleton_cache = {}
      @interface_cache = {}

      @one_instance_cache = {}
      @one_singleton_cache = {}
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

    def ensure_namespace!(namespace, location:)
      namespace.ascend do |ns|
        unless ns.empty?
          NoTypeFoundError.check!(ns.to_type_name, env: env, location: location)
        end
      end
    end

    def build_instance(type_name)
      try_cache type_name, cache: instance_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        case entry
        when Environment::ClassEntry, Environment::ModuleEntry
          ancestors = ancestor_builder.instance_ancestors(type_name)
          self_type = Types::ClassInstance.new(name: type_name,
                                               args: Types::Variable.build(entry.type_params.each.map(&:name)),
                                               location: nil)

          definition_pairs = ancestors.ancestors.map do |ancestor|
            # @type block: [Definition::Ancestor::t, Definition]
            case ancestor
            when Definition::Ancestor::Instance
              [ancestor, build_one_instance(ancestor.name)]
            when Definition::Ancestor::Singleton
              [ancestor, build_one_singleton(ancestor.name)]
            end
          end

          case entry
          when Environment::ModuleEntry
            entry.self_types.each do |module_self|
              ancestor = Definition::Ancestor::Instance.new(name: module_self.name, args: module_self.args)
              definition_pairs.push(
                [
                  ancestor,
                  if module_self.name.interface?
                    build_interface(module_self.name)
                  else
                    build_instance(module_self.name)
                  end
                ]
              )
            end
          end

          merge_definitions(type_name, definition_pairs, entry: entry, self_type: self_type, ancestors: ancestors)
        end
      end
    end

    def build_singleton(type_name)
      try_cache type_name, cache: singleton_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        case entry
        when Environment::ClassEntry, Environment::ModuleEntry
          ancestors = ancestor_builder.singleton_ancestors(type_name)
          self_type = Types::ClassSingleton.new(name: type_name, location: nil)
          instance_type = Types::ClassInstance.new(
            name: type_name,
            args: Types::Variable.build(entry.type_params.each.map(&:name)),
            location: nil
          )

          definition_pairs = ancestors.ancestors.map do |ancestor|
            # @type block: [Definition::Ancestor::t, Definition]
            case ancestor
            when Definition::Ancestor::Instance
              [ancestor, build_one_instance(ancestor.name)]
            when Definition::Ancestor::Singleton
              definition = build_one_singleton(ancestor.name)
              definition = definition.sub(Substitution.build([], [], instance_type: instance_type))
              definition = definition.map_method_type do |method_type|
                s = Substitution.build(
                  method_type.free_variables.to_a,
                  method_type.free_variables.map { Types::Bases::Any.new(location: nil) }
                )
                method_type.sub(s)
              end

              [
                ancestor,
                definition
              ]
            end
          end

          merge_definitions(type_name, definition_pairs, entry: entry, self_type: self_type, ancestors: ancestors)
        end
      end
    end

    def method_definition_members(type_name, entry, kind:)
      # @type var interface_methods: Hash[Symbol, [Definition::Method, AST::Members::t]]
      interface_methods = {}
      # @type var methods: Hash[Symbol, Array[[AST::Members::MethodDefinition, Definition::accessibility]]]
      methods = {}

      entry.decls.each do |d|
        each_member_with_accessibility(d.decl.members) do |member, accessibility|
          case member
          when AST::Members::MethodDefinition
            case kind
            when :singleton
              next unless member.singleton?
            when :instance
              next unless member.instance?
            end

            methods[member.name] ||= []
            methods[member.name] << [
              member.update(types: member.types),
              accessibility
            ]
          when AST::Members::Include, AST::Members::Extend
            if member.name.interface?
              if (kind == :instance && member.is_a?(AST::Members::Include)) || (kind == :singleton && member.is_a?(AST::Members::Extend))
                NoMixinFoundError.check!(member.name, env: env, member: member)

                interface_name = member.name
                interface_args = member.args

                interface_definition = build_interface(interface_name)

                InvalidTypeApplicationError.check!(
                  type_name: interface_name,
                  args: interface_args,
                  params: interface_definition.type_params_decl.each.map(&:name),
                  location: member.location
                )

                sub = Substitution.build(interface_definition.type_params, interface_args)

                interface_definition.methods.each do |name, method|
                  interface_methods[name] = [method.sub(sub), member]
                end
              end
            end
          end
        end
      end

      # @type var result: Hash[Symbol, member_detail]
      result = {}

      interface_methods.each do |name, pair|
        method_definition, _ = pair
        # @type var detail: member_detail
        detail = [:public, method_definition, nil, []]
        result[name] = detail
      end

      methods.each do |method_name, array|
        if result[method_name]
          unless array.all? {|pair| pair[0].overload? }
            raise MethodDefinitionConflictWithInterfaceMixinError.new(
              type_name: type_name,
              method_name: method_name,
              kind: :instance,
              mixin_member: interface_methods[method_name][1],
              entries: array.map(&:first)
            )
          end

          unless array.all? {|pair| pair[1] == :public }
            raise InconsistentMethodVisibilityError.new(
              type_name: type_name,
              method_name: method_name,
              kind: :instance,
              member_pairs: array
            )
          end

          result[method_name][3].push(*array.map(&:first))
        else
          case
          when array.size == 1 && !array[0][0].overload?
            member, visibility = array[0]
            result[method_name] = [visibility, nil, member, []]

          else
            visibilities = array.group_by {|pair| pair[1] }

            if visibilities.size > 1
              raise InconsistentMethodVisibilityError.new(
                type_name: type_name,
                method_name: method_name,
                kind: :instance,
                member_pairs: array
              )
            end

            overloads, primary = array.map(&:first).partition(&:overload?)
            result[method_name] = [array[0][1], nil, primary[0], overloads]
          end
        end
      end

      result
    end

    def build_one_instance(type_name)
      try_cache(type_name, cache: one_instance_cache) do
        entry = env.class_decls[type_name]

        param_names = entry.type_params.each.map(&:name)
        self_type = Types::ClassInstance.new(name: type_name,
                                             args: Types::Variable.build(param_names),
                                             location: nil)
        ancestors = Definition::InstanceAncestors.new(
          type_name: type_name,
          params: param_names,
          ancestors: [Definition::Ancestor::Instance.new(name: type_name, args: self_type.args)]
        )

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          method_definition_members(type_name, entry, kind: :instance).each do |method_name, array|
            visibility, method_def, primary_member, overload_members = array

            members = if primary_member
              [primary_member, *overload_members]
            else
              overload_members
            end

            m = if method_def
                  Definition::Method.new(
                    super_method: nil,
                    accessibility: visibility,
                    defs: method_def.defs.map {|defn| defn.update(implemented_in: type_name) },
                    alias_of: nil
                  )
                else
                  Definition::Method.new(
                    super_method: nil,
                    accessibility: visibility,
                    defs: [],
                    alias_of: nil
                  )
                end

            definition.methods[method_name] = members.inject(m) do |original, member|
              defs = member.types.map do |method_type|
                Definition::Method::TypeDef.new(
                  type: method_type,
                  member: member,
                  implemented_in: type_name,
                  defined_in: type_name
                )
              end

              Definition::Method.new(
                super_method: nil,
                defs: defs + original.defs,
                accessibility: original.accessibility,
                alias_of: nil
              )
            end
          end

          entry.decls.each do |d|
            each_member_with_accessibility(d.decl.members) do |member, accessibility|
              case member
              when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
                if member.kind == :instance
                  build_attribute(
                    type_name: type_name,
                    definition: definition,
                    member: member,
                    accessibility: accessibility
                  )
                end

              when AST::Members::InstanceVariable
                definition.instance_variables[member.name] = Definition::Variable.new(
                  parent_variable: nil,
                  type: member.type,
                  declared_in: type_name
                )

              when AST::Members::ClassVariable
                definition.class_variables[member.name] = Definition::Variable.new(
                  parent_variable: nil,
                  type: member.type,
                  declared_in: type_name
                )

              end
            end
          end

          entry.decls.each do |d|
            d.decl.members.each do |member|
              case member
              when AST::Members::Alias
                if member.instance?
                  UnknownMethodAliasError.check!(
                    methods: definition.methods,
                    original_name: member.old_name,
                    aliased_name: member.new_name,
                    location: member.location
                  )

                  DuplicatedMethodDefinitionError.check!(
                    decl: d.decl,
                    methods: definition.methods,
                    name: member.new_name,
                    location: member.location
                  )

                  original_method = definition.methods[member.old_name]

                  definition.methods[member.new_name] = Definition::Method.new(
                    super_method: original_method.super_method,
                    defs: original_method.defs,
                    accessibility: original_method.accessibility,
                    alias_of: original_method,
                    annotations: original_method.annotations
                  )
                end
              end
            end
          end

          entry.decls.each do |d|
            validate_parameter_variance(
              decl: d.decl,
              methods: definition.methods
            )
          end
        end
      end
    end

    def validate_params_with(type_params, result:)
      type_params.each do |param|
        unless param.skip_validation
          unless result.compatible?(param.name, with_annotation: param.variance)
            yield param
          end
        end
      end
    end

    def validate_parameter_variance(decl:, methods:)
      type_params = decl.type_params

      calculator = VarianceCalculator.new(builder: self)
      param_names = type_params.each.map(&:name)

      errors = []

      case decl
      when AST::Declarations::Class
        if super_class = decl.super_class
          result = calculator.in_inherit(name: super_class.name, args: super_class.args, variables: param_names)

          validate_params_with type_params, result: result do |param|
            errors.push InvalidVarianceAnnotationError::InheritanceError.new(
              param: param
            )
          end
        end
      end

      # @type var result: VarianceCalculator::Result

      decl.members.each do |member|
        case member
        when AST::Members::Include
          if member.name.class?
            result = calculator.in_inherit(name: member.name, args: member.args, variables: param_names)

            validate_params_with type_params, result: result do |param|
              errors.push InvalidVarianceAnnotationError::MixinError.new(
                include_member: member,
                param: param
              )
            end
          end
        end
      end

      methods.each do |name, method|
        method.method_types.each do |method_type|
          unless name == :initialize
            result = calculator.in_method_type(method_type: method_type, variables: param_names)

            validate_params_with type_params, result: result do |param|
              errors.push InvalidVarianceAnnotationError::MethodTypeError.new(
                method_name: name,
                method_type: method_type,
                param: param
              )
            end
          end
        end
      end

      unless errors.empty?
        raise InvalidVarianceAnnotationError.new(decl: decl, errors: errors)
      end
    end

    def build_one_singleton(type_name)
      try_cache(type_name, cache: one_singleton_cache) do
        entry = env.class_decls[type_name]

        self_type = Types::ClassSingleton.new(name: type_name, location: nil)
        ancestors = Definition::SingletonAncestors.new(
          type_name: type_name,
          ancestors: [Definition::Ancestor::Singleton.new(name: type_name)]
        )

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          method_definition_members(type_name, entry, kind: :singleton).each do |method_name, array|
            visibility, method_def, primary_member, overload_members = array

            members = if primary_member
              [primary_member, *overload_members]
            else
              overload_members
            end

            m = Definition::Method.new(
              super_method: nil,
              defs: method_def&.yield_self do |method_def|
                method_def.defs.map {|defn| defn.update(implemented_in: type_name) }
              end || [],
              accessibility: visibility,
              alias_of: nil
            )
            definition.methods[method_name] = members.inject(m) do |original, new|
              defs = new.types.map do |type|
                Definition::Method::TypeDef.new(
                  type: type,
                  member: new,
                  defined_in: type_name,
                  implemented_in: type_name
                )
              end
              Definition::Method.new(
                super_method: nil,
                defs: defs + original.defs,
                accessibility: original.accessibility,
                alias_of: nil
              )
            end
          end

          entry.decls.each do |d|
            d.decl.members.each do |member|
              case member
              when AST::Members::Alias
                if member.singleton?
                  UnknownMethodAliasError.check!(
                    methods: definition.methods,
                    original_name: member.old_name,
                    aliased_name: member.new_name,
                    location: member.location
                  )

                  DuplicatedMethodDefinitionError.check!(
                    decl: d.decl,
                    methods: definition.methods,
                    name: member.new_name,
                    location: member.location
                  )

                  original_method = definition.methods[member.old_name]
                  definition.methods[member.new_name] = Definition::Method.new(
                    super_method: original_method.super_method,
                    defs: original_method.defs,
                    accessibility: original_method.accessibility,
                    alias_of: original_method,
                    annotations: original_method.annotations
                  )
                end
              end
            end
          end

          unless definition.methods.key?(:new)
            instance = build_instance(type_name)
            initialize = instance.methods[:initialize]

            if initialize
              class_params = entry.type_params.each.map(&:name)

              initialize_defs = initialize.defs
              definition.methods[:new] = Definition::Method.new(
                super_method: nil,
                defs: initialize_defs.map do |initialize_def|
                  method_type = initialize_def.type

                  class_type_param_vars = Set.new(class_params)
                  method_type_param_vars = Set.new(method_type.type_params)

                  if class_type_param_vars.intersect?(method_type_param_vars)
                    renamed_method_params = method_type.type_params.map do |name|
                      if class_type_param_vars.include?(name)
                        Types::Variable.fresh(name).name
                      else
                        name
                      end
                    end
                    method_params = class_params + renamed_method_params

                    sub = Substitution.build(method_type.type_params, Types::Variable.build(renamed_method_params))
                  else
                    method_params = class_params + method_type.type_params
                    sub = Substitution.build([], [])
                  end

                  method_type = method_type.map_type {|ty| ty.sub(sub) }
                  method_type = method_type.update(
                    type_params: method_params,
                    type: method_type.type.with_return_type(Types::Bases::Instance.new(location: nil))
                  )

                  Definition::Method::TypeDef.new(
                    type: method_type,
                    member: initialize_def.member,
                    defined_in: initialize_def.defined_in,
                    implemented_in: initialize_def.implemented_in
                  )
                end,
                accessibility: :public,
                annotations: [AST::Annotation.new(location: nil, string: "rbs:test:target")],
                alias_of: nil
              )
            end
          end

          entry.decls.each do |d|
            each_member_with_accessibility(d.decl.members) do |member, accessibility|
              case member
              when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
                if member.kind == :singleton
                  build_attribute(type_name: type_name,
                                  definition: definition,
                                  member: member,
                                  accessibility: accessibility)
                end

              when AST::Members::ClassInstanceVariable
                definition.instance_variables[member.name] = Definition::Variable.new(
                  parent_variable: nil,
                  type: member.type,
                  declared_in: type_name
                )

              when AST::Members::ClassVariable
                definition.class_variables[member.name] = Definition::Variable.new(
                  parent_variable: nil,
                  type: member.type,
                  declared_in: type_name
                )
              end
            end
          end
        end
      end
    end

    def build_attribute(type_name:, definition:, member:, accessibility:)
      name = member.name
      type = member.type

      ivar_name = case member.ivar_name
                  when false
                    nil
                  else
                    member.ivar_name || :"@#{member.name}"
                  end

      if member.is_a?(AST::Members::AttrReader) || member.is_a?(AST::Members::AttrAccessor)
        definition.methods[name] = Definition::Method.new(
          super_method: nil,
          defs: [
            Definition::Method::TypeDef.new(
              type: MethodType.new(
                type_params: [],
                type: Types::Function.empty(type),
                block: nil,
                location: nil
              ),
              member: member,
              defined_in: type_name,
              implemented_in: type_name
            )
          ],
          accessibility: accessibility,
          alias_of: nil
        )
      end

      if member.is_a?(AST::Members::AttrWriter) || member.is_a?(AST::Members::AttrAccessor)
        definition.methods[:"#{name}="] = Definition::Method.new(
          super_method: nil,
          defs: [
            Definition::Method::TypeDef.new(
              type: MethodType.new(
                type_params: [],
                type: Types::Function.empty(type).update(
                  required_positionals: [Types::Function::Param.new(name: name, type: type)]
                ),
                block: nil,
                location: nil
              ),
              member: member,
              defined_in: type_name,
              implemented_in: type_name
            ),
          ],
          accessibility: accessibility,
          alias_of: nil
        )
      end

      if ivar_name
        definition.instance_variables[ivar_name] = Definition::Variable.new(
          parent_variable: nil,
          type: type,
          declared_in: type_name
        )
      end
    end

    def merge_definitions(type_name, pairs, entry:, self_type:, ancestors:)
      Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
        pairs.reverse_each do |ancestor, current_definition|
          sub = case ancestor
                when Definition::Ancestor::Instance
                  Substitution.build(current_definition.type_params, ancestor.args)
                when Definition::Ancestor::Singleton
                  Substitution.build([], [])
                end

          # @type var kind: method_kind
          kind = case ancestor
                 when Definition::Ancestor::Instance
                   :instance
                 when Definition::Ancestor::Singleton
                   :singleton
                 end

          current_definition.methods.each do |name, method|
            merge_method type_name, definition.methods, name, method, sub, kind: kind
          end

          current_definition.instance_variables.each do |name, variable|
            merge_variable definition.instance_variables, name, variable
          end

          current_definition.class_variables.each do |name, variable|
            merge_variable definition.class_variables, name, variable
          end
        end
      end
    end

    def merge_variable(variables, name, variable)
      super_variable = variables[name]

      variables[name] = Definition::Variable.new(
        parent_variable: super_variable,
        type: variable.type,
        declared_in: variable.declared_in
      )
    end

    def merge_method(type_name, methods, name, method, sub, kind:)
      super_method = methods[name]

      defs = if method.defs.all? {|d| d.overload? }
               raise InvalidOverloadMethodError.new(type_name: type_name, method_name: name, kind: kind, members: method.members) unless super_method
               method.defs + super_method.defs
             else
               method.defs
             end

      methods[name] = Definition::Method.new(
        super_method: super_method,
        accessibility: method.accessibility,
        defs: sub.mapping.empty? ? defs : defs.map {|defn| defn.update(type: defn.type.sub(sub)) },
        alias_of: nil
      )
    end

    def try_cache(type_name, cache:)
      cached = _ = cache[type_name]

      case cached
      when Definition
        cached
      when false
        raise
      when nil
        cache[type_name] = false
        begin
          cache[type_name] = yield
        rescue => ex
          cache.delete(type_name)
          raise ex
        end
      else
        raise
      end
    end

    def build_interface(type_name)
      try_cache(type_name, cache: interface_cache) do
        entry = env.interface_decls[type_name] or raise "Unknown name for build_interface: #{type_name}"
        declaration = entry.decl
        ensure_namespace!(type_name.namespace, location: declaration.location)

        self_type = Types::Interface.new(
          name: type_name,
          args: Types::Variable.build(declaration.type_params.each.map(&:name)),
          location: nil
        )

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: nil).tap do |definition|
          include_members = []
          def_members = []
          alias_members = []

          declaration.members.each do |member|
            case member
            when AST::Members::Include
              include_members << member
            when AST::Members::MethodDefinition
              def_members << member
            when AST::Members::Alias
              alias_members << member
            end
          end

          include_members.each do |member|
            NoMixinFoundError.check!(member.name, env: env, member: member)

            mixin = build_interface(member.name)

            args = member.args
            # @type var interface_entry: Environment::SingleEntry[TypeName, AST::Declarations::Interface]
            interface_entry = _ = mixin.entry
            type_params = interface_entry.decl.type_params

            InvalidTypeApplicationError.check!(
              type_name: type_name,
              args: args,
              params: type_params.each.map(&:name),
              location: member.location
            )

            sub = Substitution.build(type_params.each.map(&:name), args)
            mixin.methods.each do |name, method|
              definition.methods[name] = method.sub(sub)
            end
          end

          def_members.each do |member|
            DuplicatedMethodDefinitionError.check!(
              decl: declaration,
              methods: definition.methods,
              name: member.name,
              location: member.location
            )

            method = Definition::Method.new(
              super_method: nil,
              defs: member.types.map do |method_type|
                Definition::Method::TypeDef.new(
                  type: method_type,
                  member: member,
                  defined_in: type_name,
                  implemented_in: nil
                )
              end,
              accessibility: :public,
              alias_of: nil
            )
            definition.methods[member.name] = method
          end

          alias_members.each do |member|
            UnknownMethodAliasError.check!(
              methods: definition.methods,
              original_name: member.old_name,
              aliased_name: member.new_name,
              location: member.location
            )

            DuplicatedMethodDefinitionError.check!(
              decl: declaration,
              methods: definition.methods,
              name: member.new_name,
              location: member.location
            )

            # FIXME: may cause a problem if #old_name has super type
            definition.methods[member.new_name] = definition.methods[member.old_name]
          end
        end
      end
    end

    def expand_alias(type_name)
      entry = env.alias_decls[type_name] or raise "Unknown name for expand_alias: #{type_name}"
      ensure_namespace!(type_name.namespace, location: entry.decl.location)
      entry.decl.type
    end
  end
end
