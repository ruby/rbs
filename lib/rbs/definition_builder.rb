module RBS
  class DefinitionBuilder
    attr_reader :env
    attr_reader :type_name_resolver
    attr_reader :ancestor_builder
    attr_reader :method_builder

    attr_reader :instance_cache
    attr_reader :singleton_cache
    attr_reader :singleton0_cache
    attr_reader :interface_cache

    def initialize(env:)
      @env = env
      @type_name_resolver = TypeNameResolver.from_env(env)
      @ancestor_builder = AncestorBuilder.new(env: env)
      @method_builder = MethodBuilder.new(env: env)

      @instance_cache = {}
      @singleton_cache = {}
      @singleton0_cache = {}
      @interface_cache = {}
    end

    def ensure_namespace!(namespace, location:)
      namespace.ascend do |ns|
        unless ns.empty?
          NoTypeFoundError.check!(ns.to_type_name, env: env, location: location)
        end
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

        ancestors = ancestor_builder.interface_ancestors(type_name)
        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          included_interfaces = ancestor_builder.one_interface_ancestors(type_name).included_interfaces or raise
          included_interfaces.each do |mod|
            defn = build_interface(mod.name)
            subst = Substitution.build(defn.type_params, mod.args)

            defn.methods.each do |name, method|
              definition.methods[name] = method.sub(subst)
            end
          end

          methods = method_builder.build_interface(type_name)
          one_ancestors = ancestor_builder.one_interface_ancestors(type_name)

          validate_type_params(definition, methods: methods, ancestors: one_ancestors)

          methods.each do |defn|
            method = case original = defn.original
                     when AST::Members::MethodDefinition
                       defs = original.types.map do |method_type|
                         Definition::Method::TypeDef.new(
                           type: method_type,
                           member: original,
                           defined_in: type_name,
                           implemented_in: nil
                         )
                       end

                       Definition::Method.new(
                         super_method: nil,
                         defs: defs,
                         accessibility: :public,
                         alias_of: nil
                       )
                     when AST::Members::Alias
                       unless definition.methods.key?(original.old_name)
                         raise UnknownMethodAliasError.new(
                           original_name: original.old_name,
                           aliased_name: original.new_name,
                           location: original.location
                         )
                       end

                       original_method = definition.methods[original.old_name]
                       Definition::Method.new(
                         super_method: nil,
                         defs: original_method.defs.map do |defn|
                           defn.update(implemented_in: nil, defined_in: type_name)
                         end,
                         accessibility: :public,
                         alias_of: original_method
                       )
                     when nil
                       unless definition.methods.key?(defn.name)
                         raise InvalidOverloadMethodError.new(
                           type_name: type_name,
                           method_name: defn.name,
                           kind: :instance,
                           members: defn.overloads
                         )
                       end

                       definition.methods[defn.name]

                     when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
                       raise

                     end

            defn.overloads.each do |overload|
              overload_defs = overload.types.map do |method_type|
                Definition::Method::TypeDef.new(
                  type: method_type,
                  member: overload,
                  defined_in: type_name,
                  implemented_in: nil
                )
              end

              method.defs.unshift(*overload_defs)
            end

            definition.methods[defn.name] = method
          end
        end
      end
    end

    def build_instance(type_name, no_self_types: false)
      try_cache(type_name, cache: instance_cache, key: [type_name, no_self_types]) do
        entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        case entry
        when Environment::ClassEntry, Environment::ModuleEntry
          ancestors = ancestor_builder.instance_ancestors(type_name)
          args = Types::Variable.build(entry.type_params.each.map(&:name))
          self_type = Types::ClassInstance.new(name: type_name, args: args, location: nil)

          Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
            one_ancestors = ancestor_builder.one_instance_ancestors(type_name)
            methods = method_builder.build_instance(type_name)

            validate_type_params definition, methods: methods, ancestors: one_ancestors

            if super_class = one_ancestors.super_class
              case super_class
              when Definition::Ancestor::Instance
                build_instance(super_class.name).yield_self do |defn|
                  merge_definition(src: defn,
                                  dest: definition,
                                  subst: Substitution.build(defn.type_params, super_class.args),
                                  keep_super: true)
                end
              else
                raise
              end
            end

            if self_types = one_ancestors.self_types
              unless no_self_types
                self_types.each do |ans|
                  defn = if ans.name.interface?
                           build_interface(ans.name)
                         else
                           build_instance(ans.name)
                         end

                  # Successor interface method overwrites.
                  merge_definition(src: defn,
                                   dest: definition,
                                   subst: Substitution.build(defn.type_params, ans.args),
                                   keep_super: true)
                end
              end
            end

            one_ancestors.each_included_module do |mod|
              defn = build_instance(mod.name, no_self_types: true)
              merge_definition(src: defn,
                               dest: definition,
                               subst: Substitution.build(defn.type_params, mod.args))
            end

            interface_methods = {}

            one_ancestors.each_included_interface do |mod|
              defn = build_interface(mod.name)
              subst = Substitution.build(defn.type_params, mod.args)

              defn.methods.each do |name, method|
                if interface_methods.key?(name)
                  include_member = mod.source

                  raise unless include_member.is_a?(AST::Members::Include)

                  raise DuplicatedInterfaceMethodDefinitionError.new(
                    type: self_type,
                    method_name: name,
                    member: include_member
                  )
                end

                merge_method(type_name, interface_methods, name, method, subst, implemented_in: type_name)
              end
            end

            define_methods(definition,
                           interface_methods: interface_methods,
                           methods: methods,
                           super_interface_method: entry.is_a?(Environment::ModuleEntry))

            entry.decls.each do |d|
              subst = Substitution.build(d.decl.type_params.each.map(&:name), args)

              d.decl.members.each do |member|
                case member
                when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
                  if member.kind == :instance
                    ivar_name = case member.ivar_name
                                when false
                                  nil
                                else
                                  member.ivar_name || :"@#{member.name}"
                                end

                    if ivar_name
                      insert_variable(type_name,
                                      definition.instance_variables,
                                      name: ivar_name,
                                      type: member.type.sub(subst))
                    end
                  end

                when AST::Members::InstanceVariable
                  insert_variable(type_name,
                                  definition.instance_variables,
                                  name: member.name,
                                  type: member.type.sub(subst))

                when AST::Members::ClassVariable
                  insert_variable(type_name, definition.class_variables, name: member.name, type: member.type)
                end
              end
            end

            one_ancestors.each_prepended_module do |mod|
              defn = build_instance(mod.name)
              merge_definition(src: defn,
                               dest: definition,
                               subst: Substitution.build(defn.type_params, mod.args))
            end
          end
        end
      end
    end

    # Builds a definition for singleton without .new method.
    #
    def build_singleton0(type_name)
      try_cache type_name, cache: singleton0_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton0: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        case entry
        when Environment::ClassEntry, Environment::ModuleEntry
          ancestors = ancestor_builder.singleton_ancestors(type_name)
          self_type = Types::ClassSingleton.new(name: type_name, location: nil)

          Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
            one_ancestors = ancestor_builder.one_singleton_ancestors(type_name)

            if super_class = one_ancestors.super_class
              case super_class
              when Definition::Ancestor::Instance
                defn = build_instance(super_class.name)
                merge_definition(src: defn,
                                 dest: definition,
                                 subst: Substitution.build(defn.type_params, super_class.args),
                                 keep_super: true)
              when Definition::Ancestor::Singleton
                defn = build_singleton0(super_class.name)
                merge_definition(src: defn, dest: definition, subst: Substitution.new, keep_super: true)
              end
            end

            one_ancestors.each_extended_module do |mod|
              mod_defn = build_instance(mod.name, no_self_types: true)
              merge_definition(src: mod_defn,
                               dest: definition,
                               subst: Substitution.build(mod_defn.type_params, mod.args))
            end

            interface_methods = {}
            one_ancestors.each_extended_interface do |mod|
              mod_defn = build_interface(mod.name)
              subst = Substitution.build(mod_defn.type_params, mod.args)

              mod_defn.methods.each do |name, method|
                if interface_methods.key?(name)
                  src_member = mod.source

                  raise unless src_member.is_a?(AST::Members::Extend)

                  raise DuplicatedInterfaceMethodDefinitionError.new(
                    type: self_type,
                    method_name: name,
                    member: src_member
                  )
                end

                merge_method(type_name, interface_methods, name, method, subst, implemented_in: type_name)
              end
            end

            methods = method_builder.build_singleton(type_name)
            define_methods(definition, interface_methods: interface_methods, methods: methods, super_interface_method: false)

            entry.decls.each do |d|
              d.decl.members.each do |member|
                case member
                when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
                  if member.kind == :singleton
                    ivar_name = case member.ivar_name
                                when false
                                  nil
                                else
                                  member.ivar_name || :"@#{member.name}"
                                end

                    if ivar_name
                      insert_variable(type_name, definition.instance_variables, name: ivar_name, type: member.type)
                    end
                  end

                when AST::Members::ClassInstanceVariable
                  insert_variable(type_name, definition.instance_variables, name: member.name, type: member.type)

                when AST::Members::ClassVariable
                  insert_variable(type_name, definition.class_variables, name: member.name, type: member.type)
                end
              end
            end
          end
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
            args: entry.type_params.each.map { Types::Bases::Any.new(location: nil) },
            location: nil
          )

          Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
            def0 = build_singleton0(type_name)
            subst = Substitution.build([], [], instance_type: instance_type)

            merge_definition(src: def0, dest: definition, subst: subst, keep_super: true)

            if entry.is_a?(Environment::ClassEntry)
              new_method = definition.methods[:new]
              if new_method.defs.all? {|d| d.defined_in == BuiltinNames::Class.name }
                # The method is _untyped new_.

                instance = build_instance(type_name)
                initialize = instance.methods[:initialize]

                if initialize
                  class_params = entry.type_params.each.map(&:name)

                  # Inject a virtual _typed new_.
                  initialize_defs = initialize.defs
                  definition.methods[:new] = Definition::Method.new(
                    super_method: new_method,
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
                        type: method_type.type.with_return_type(
                          Types::ClassInstance.new(
                            name: type_name,
                            args: Types::Variable.build(entry.type_params.each.map(&:name)),
                            location: nil
                          )
                        )
                      )

                      Definition::Method::TypeDef.new(
                        type: method_type,
                        member: initialize_def.member,
                        defined_in: initialize_def.defined_in,
                        implemented_in: initialize_def.implemented_in
                      )
                    end,
                    accessibility: :public,
                    annotations: [],
                    alias_of: nil
                  )
                end
              end
            end
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

    def source_location(source, decl)
      case source
      when nil
        decl.location
      when :super
        case decl
        when AST::Declarations::Class
          decl.super_class&.location
        end
      else
        source.location
      end
    end

    def validate_type_params(definition, ancestors:, methods:)
      type_params = definition.type_params_decl

      calculator = VarianceCalculator.new(builder: self)
      param_names = type_params.each.map(&:name)

      ancestors.each_ancestor do |ancestor|
        case ancestor
        when Definition::Ancestor::Instance
          result = calculator.in_inherit(name: ancestor.name, args: ancestor.args, variables: param_names)
          validate_params_with(type_params, result: result) do |param|
            decl = case entry = definition.entry
                   when Environment::ModuleEntry, Environment::ClassEntry
                     entry.primary.decl
                   when Environment::SingleEntry
                     entry.decl
                   end

            raise InvalidVarianceAnnotationError.new(
              type_name: definition.type_name,
              param: param,
              location: source_location(ancestor.source, decl)
            )
          end
        end
      end

      methods.each do |defn|
        next if defn.name == :initialize

        method_types = case original = defn.original
                       when AST::Members::MethodDefinition
                         original.types
                       when AST::Members::AttrWriter, AST::Members::AttrReader, AST::Members::AttrAccessor
                         if defn.name.to_s.end_with?("=")
                           [
                             MethodType.new(
                               type_params: [],
                               type: Types::Function.empty(original.type).update(
                                 required_positionals: [
                                   Types::Function::Param.new(type: original.type, name: original.name)
                                 ]
                               ),
                               block: nil,
                               location: original.location
                             )
                           ]
                         else
                           [
                             MethodType.new(
                               type_params: [],
                               type: Types::Function.empty(original.type),
                               block: nil,
                               location: original.location
                             )
                           ]
                         end
                       when AST::Members::Alias
                         nil
                       when nil
                         nil
                       end

        if method_types
          method_types.each do |method_type|
            result = calculator.in_method_type(method_type: method_type, variables: param_names)
            validate_params_with(type_params, result: result) do |param|
              raise InvalidVarianceAnnotationError.new(
                type_name: definition.type_name,
                param: param,
                location: method_type.location
              )
            end
          end
        end
      end
    end

    def insert_variable(type_name, variables, name:, type:)
      variables[name] = Definition::Variable.new(
        parent_variable: variables[name],
        type: type,
        declared_in: type_name
      )
    end

    def define_methods(definition, interface_methods:, methods:, super_interface_method:)
      methods.each do |method_def|
        method_name = method_def.name
        original = method_def.original

        if original.is_a?(AST::Members::Alias)
          existing_method = interface_methods[method_name] || definition.methods[method_name]
          original_method = interface_methods[original.old_name] || definition.methods[original.old_name]

          unless original_method
            raise UnknownMethodAliasError.new(
              original_name: original.old_name,
              aliased_name: original.new_name,
              location: original.location
            )
          end

          method = Definition::Method.new(
            super_method: existing_method,
            defs: original_method.defs.map do |defn|
              defn.update(defined_in: definition.type_name, implemented_in: definition.type_name)
            end,
            accessibility: method_def.accessibility,
            alias_of: original_method
          )
        else
          if interface_methods.key?(method_name)
            interface_method = interface_methods[method_name]

            if original = method_def.original
              raise DuplicatedMethodDefinitionError.new(
                type: definition.self_type,
                method_name: method_name,
                members: [original]
              )
            end

            definition.methods[method_name] = interface_method
          end

          existing_method = definition.methods[method_name]

          case original
          when AST::Members::MethodDefinition
            defs = original.types.map do |method_type|
              Definition::Method::TypeDef.new(
                type: method_type,
                member: original,
                defined_in: definition.type_name,
                implemented_in: definition.type_name
              )
            end

            # @type var accessibility: RBS::Definition::accessibility
            accessibility = if method_name == :initialize
                              :private
                            else
                              method_def.accessibility
                            end

            method = Definition::Method.new(
              super_method: existing_method,
              defs: defs,
              accessibility: accessibility,
              alias_of: nil
            )

          when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
            method_type = if method_name.to_s.end_with?("=")
                            # setter
                            MethodType.new(
                              type_params: [],
                              type: Types::Function.empty(original.type).update(
                                required_positionals: [
                                  Types::Function::Param.new(type: original.type, name: original.name)
                                ]
                              ),
                              block: nil,
                              location: nil
                            )
                          else
                            # getter
                            MethodType.new(
                              type_params: [],
                              type: Types::Function.empty(original.type),
                              block: nil,
                              location: nil
                            )
                          end
            defs = [
              Definition::Method::TypeDef.new(
                type: method_type,
                member: original,
                defined_in: definition.type_name,
                implemented_in: definition.type_name
              )
            ]

            method = Definition::Method.new(
              super_method: existing_method,
              defs: defs,
              accessibility: method_def.accessibility,
              alias_of: nil
            )

          when nil
            unless definition.methods.key?(method_name)
              raise InvalidOverloadMethodError.new(
                type_name: definition.type_name,
                method_name: method_name,
                kind: :instance,
                members: method_def.overloads
              )
            end

            if !super_interface_method && existing_method.defs.any? {|defn| defn.defined_in.interface? }
              super_method = existing_method.super_method
            else
              super_method = existing_method
            end

            method = Definition::Method.new(
              super_method: super_method,
              defs: existing_method.defs.map do |defn|
                defn.update(implemented_in: definition.type_name)
              end,
              accessibility: existing_method.accessibility,
              alias_of: existing_method.alias_of
            )
          end
        end

        method_def.overloads.each do |overload|
          type_defs = overload.types.map do |method_type|
            Definition::Method::TypeDef.new(
              type: method_type,
              member: overload,
              defined_in: definition.type_name,
              implemented_in: definition.type_name
            )
          end

          method.defs.unshift(*type_defs)
        end

        definition.methods[method_name] = method
      end

      interface_methods.each do |name, method|
        unless methods.methods.key?(name)
          merge_method(definition.type_name, definition.methods, name, method, Substitution.new)
        end
      end
    end

    def merge_definition(src:, dest:, subst:, implemented_in: :keep, keep_super: false)
      src.methods.each do |name, method|
        merge_method(dest.type_name, dest.methods, name, method, subst, implemented_in: implemented_in, keep_super: keep_super)
      end

      src.instance_variables.each do |name, variable|
        merge_variable(dest.instance_variables, name, variable, subst, keep_super: keep_super)
      end

      src.class_variables.each do |name, variable|
        merge_variable(dest.class_variables, name, variable, subst, keep_super: keep_super)
      end
    end

    def merge_variable(variables, name, variable, sub, keep_super: false)
      super_variable = variables[name]

      variables[name] = Definition::Variable.new(
        parent_variable: keep_super ? variable.parent_variable : super_variable,
        type: sub.empty? ? variable.type : variable.type.sub(sub),
        declared_in: variable.declared_in
      )
    end

    def merge_method(type_name, methods, name, method, sub, implemented_in: :keep, keep_super: false)
      defs = method.defs.yield_self do |defs|
        if sub.empty? && implemented_in == :keep
          defs
        else
          defs.map do |defn|
            defn.update(
              type: sub.empty? ? defn.type : defn.type.sub(sub),
              implemented_in: case implemented_in
                              when :keep
                                defn.implemented_in
                              when nil
                                nil
                              else
                                implemented_in
                              end
            )
          end
        end
      end

      super_method = methods[name]

      methods[name] = Definition::Method.new(
        super_method: keep_super ? method.super_method : super_method,
        accessibility: method.accessibility,
        defs: defs,
        alias_of: method.alias_of
      )
    end

    def try_cache(type_name, cache:, key: type_name)
      # @type var cc: Hash[untyped, Definition | false | nil]
      cc = _ = cache
      cached = cc[key]

      case cached
      when Definition
        cached
      when false
        raise
      when nil
        cc[key] = false
        begin
          cc[key] = yield
        rescue => ex
          cc.delete(key)
          raise ex
        end
      else
        raise
      end
    end

    def expand_alias(type_name)
      entry = env.alias_decls[type_name] or raise "Unknown name for expand_alias: #{type_name}"
      ensure_namespace!(type_name.namespace, location: entry.decl.location)
      entry.decl.type
    end
  end
end
