# frozen_string_literal: true

module RBS
  class DefinitionBuilder
    attr_reader :env
    attr_reader :ancestor_builder
    attr_reader :method_builder

    attr_reader :instance_cache
    attr_reader :singleton_cache
    attr_reader :singleton0_cache
    attr_reader :interface_cache

    def initialize(env:, ancestor_builder: nil, method_builder: nil)
      @env = env
      @ancestor_builder = ancestor_builder || AncestorBuilder.new(env: env)
      @method_builder = method_builder || MethodBuilder.new(env: env)

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

    def define_interface(definition, type_name, subst)
      included_interfaces = ancestor_builder.interface_ancestors(type_name).ancestors #: Array[Definition::Ancestor::Instance]
      included_interfaces = included_interfaces.reject {|ancestor| ancestor.source == nil }

      interface_methods = interface_methods(included_interfaces)
      methods = method_builder.build_interface(type_name)

      import_methods(definition, type_name, methods, interface_methods, subst)
    end

    def build_interface(type_name)
      try_cache(type_name, cache: interface_cache) do
        entry = env.interface_decls[type_name] or raise "Unknown name for build_interface: #{type_name}"
        declaration = entry.decl
        ensure_namespace!(type_name.namespace, location: declaration.location)

        type_params = declaration.type_params.each.map(&:name)
        type_args = Types::Variable.build(type_params)
        self_type = Types::Interface.new(name: type_name, args: type_args, location: nil)

        subst = Substitution.build(type_params, type_args)

        ancestors = ancestor_builder.interface_ancestors(type_name)
        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          methods = method_builder.build_interface(type_name)
          one_ancestors = ancestor_builder.one_interface_ancestors(type_name)
          validate_type_params(definition, methods: methods, ancestors: one_ancestors)

          define_interface(definition, type_name, subst)
        end
      end
    end

    def tapp_subst(name, args)
      params =
        case
        when name.interface?
          entry = env.interface_decls[name] or raise "Unknown interface name: #{name}"
          entry.decl.type_params
        when name.alias?
          entry = env.type_alias_decls[name] or raise "Unknown alias name: #{name}"
          entry.decl.type_params
        when name.class?
          entry = env.class_decls[name] or raise "Unknown module name: #{name}"
          entry.type_params
        else
          raise
        end

      Substitution.build(params.map(&:name), args)
    end

    def define_instance(definition, type_name, subst)
      one_ancestors = ancestor_builder.one_instance_ancestors(type_name)
      methods = method_builder.build_instance(type_name)

      one_ancestors.each_included_module do |mod|
        mod.args.each do |arg|
          validate_type_presence(arg)
        end

        define_instance(definition, mod.name, subst + tapp_subst(mod.name, mod.args))
      end

      all_interfaces = one_ancestors.each_included_interface.flat_map do |interface|
        other_interfaces = ancestor_builder.interface_ancestors(interface.name).ancestors #: Array[Definition::Ancestor::Instance]
        other_interfaces = other_interfaces.select {|ancestor| ancestor.source }
        [interface, *other_interfaces]
      end
      interface_methods = interface_methods(all_interfaces)
      import_methods(definition, type_name, methods, interface_methods, subst)

      one_ancestors.each_prepended_module do |mod|
        mod.args.each do |arg|
          validate_type_presence(arg)
        end

        define_instance(definition, mod.name, subst + tapp_subst(mod.name, mod.args))
      end

      entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
      args = entry.type_params.map {|param| Types::Variable.new(name: param.name, location: param.location) }

      entry.decls.each do |d|
        subst_ = subst + Substitution.build(d.decl.type_params.each.map(&:name), args)

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
                insert_variable(
                  type_name,
                  definition.instance_variables,
                  name: ivar_name,
                  type: member.type.sub(subst_)
                )
              end
            end

          when AST::Members::InstanceVariable
            insert_variable(
              type_name,
              definition.instance_variables,
              name: member.name,
              type: member.type.sub(subst_)
            )

          when AST::Members::ClassVariable
            insert_variable(type_name, definition.class_variables, name: member.name, type: member.type)
          end
        end
      end
    end

    def build_instance(type_name)
      type_name = env.normalize_module_name(type_name)

      try_cache(type_name, cache: instance_cache) do
        entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        ancestors = ancestor_builder.instance_ancestors(type_name)
        args = entry.type_params.map {|param| Types::Variable.new(name: param.name, location: param.location) }
        self_type = Types::ClassInstance.new(name: type_name, args: args, location: nil)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          one_ancestors = ancestor_builder.one_instance_ancestors(type_name)
          methods = method_builder.build_instance(type_name)

          validate_type_params definition, methods: methods, ancestors: one_ancestors

          if entry.is_a?(Environment::ClassEntry)
            if super_class = one_ancestors.super_class
              super_class.is_a?(Definition::Ancestor::Instance) or raise

              build_instance(super_class.name).tap do |defn|
                unless super_class.args.empty?
                  super_class.args.each do |arg|
                    validate_type_presence(arg)
                  end

                  subst = tapp_subst(super_class.name, super_class.args)
                  defn = defn.sub(subst)
                end

                definition.methods.merge!(defn.methods)
                definition.instance_variables.merge!(defn.instance_variables)
                definition.class_variables.merge!(defn.class_variables)
              end
            end
          end

          if entry.is_a?(Environment::ModuleEntry)
            if self_types = one_ancestors.self_types
              self_types.each do |ans|
                ans.args.each do |arg|
                  validate_type_presence(arg)
                end

                subst = tapp_subst(ans.name, ans.args)
                if ans.name.interface?
                  define_interface(definition, ans.name, subst)
                else
                  define_instance(definition, ans.name, subst)
                end
              end
            end
          end

          define_instance(definition, type_name, Substitution.new)
        end
      end
    end

    # Builds a definition for singleton without .new method.
    #
    def build_singleton0(type_name)
      try_cache type_name, cache: singleton0_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton0: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        ancestors = ancestor_builder.singleton_ancestors(type_name)
        self_type = Types::ClassSingleton.new(name: type_name, location: nil)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          one_ancestors = ancestor_builder.one_singleton_ancestors(type_name)
          methods = method_builder.build_singleton(type_name)

          if super_class = one_ancestors.super_class
            case super_class
            when Definition::Ancestor::Instance
              defn = build_instance(super_class.name)
            when Definition::Ancestor::Singleton
              defn = build_singleton0(super_class.name)
            end

            definition.methods.merge!(defn.methods)
            definition.instance_variables.merge!(defn.instance_variables)
            definition.class_variables.merge!(defn.class_variables)
          end

          one_ancestors.each_extended_module do |mod|
            mod.args.each do |arg|
              validate_type_presence(arg)
            end

            subst = tapp_subst(mod.name, mod.args)
            define_instance(definition, mod.name, subst)
          end

          all_interfaces = one_ancestors.each_extended_interface.flat_map do |interface|
            other_interfaces = ancestor_builder.interface_ancestors(interface.name).ancestors #: Array[Definition::Ancestor::Instance]
            other_interfaces = other_interfaces.select {|ancestor| ancestor.source }
            [interface, *other_interfaces]
          end
          interface_methods = interface_methods(all_interfaces)
          import_methods(definition, type_name, methods, interface_methods, Substitution.new)

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

    def build_singleton(type_name)
      type_name = env.normalize_module_name(type_name)

      try_cache type_name, cache: singleton_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.decls[0].decl.location)

        ancestors = ancestor_builder.singleton_ancestors(type_name)
        self_type = Types::ClassSingleton.new(name: type_name, location: nil)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors).tap do |definition|
          definition0 = build_singleton0(type_name)
          definition.methods.merge!(definition0.methods)
          definition.instance_variables.merge!(definition0.instance_variables)
          definition.class_variables.merge!(definition0.class_variables)

          if entry.is_a?(Environment::ClassEntry)
            new_method = definition.methods[:new]

            if new_method.defs.all? {|d| d.defined_in == BuiltinNames::Class.name }
              # The method is _untyped new_.

              alias_methods = definition.methods.each.with_object([]) do |entry, array|
                # @type var method: Definition::Method?
                name, method = entry
                while method
                  if method.alias_of == new_method
                    array << name
                    break
                  end
                  method = method.alias_of
                end
              end

              instance = build_instance(type_name)
              initialize = instance.methods[:initialize]

              if initialize
                class_params = entry.type_params

                # Inject a virtual _typed new_.
                initialize_defs = initialize.defs
                typed_new = Definition::Method.new(
                  super_method: new_method,
                  defs: initialize_defs.map do |initialize_def|
                    method_type = initialize_def.type

                    class_type_param_vars = Set.new(class_params.map(&:name))
                    method_type_param_vars = Set.new(method_type.type_params.map(&:name))

                    if class_type_param_vars.intersect?(method_type_param_vars)
                      new_method_param_names = method_type.type_params.map do |method_param|
                        if class_type_param_vars.include?(method_param.name)
                          Types::Variable.fresh(method_param.name).name
                        else
                          method_param.name
                        end
                      end

                      sub = Substitution.build(
                        method_type.type_params.map(&:name),
                        Types::Variable.build(new_method_param_names)
                      )

                      method_params = class_params + AST::TypeParam.rename(method_type.type_params, new_names: new_method_param_names)
                      method_type = method_type
                        .update(type_params: [])
                        .sub(sub)
                        .update(type_params: method_params)
                    else
                      method_type = method_type
                        .update(type_params: class_params + method_type.type_params)
                    end

                    method_type = method_type.update(
                      type: method_type.type.with_return_type(
                        Types::ClassInstance.new(
                          name: type_name,
                          args: entry.type_params.map {|param| Types::Variable.new(name: param.name, location: param.location) },
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
                  alias_of: nil
                )

                definition.methods[:new] = typed_new

                alias_methods.each do |alias_name|
                  definition.methods[alias_name] = definition.methods[alias_name].update(
                    alias_of: typed_new,
                    defs: typed_new.defs
                  )
                end
              end
            end
          end
        end
      end
    end

    def interface_methods(interface_ancestors)
      interface_methods = {} #: interface_methods

      interface_ancestors.each do |mod|
        source =
          case mod.source
          when AST::Members::Include, AST::Members::Extend
            mod.source
          else
            raise "Interface mixin must be include/extend: #{mod.source.inspect}"
          end

        methods = method_builder.build_interface(mod.name)

        interface_methods[mod] = [methods, source]
      end

      interface_methods
    end

    def validate_params_with(type_params, result:)
      type_params.each do |param|
        unless param.unchecked?
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
                         original.overloads.map(&:method_type)
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
            merged_params = type_params
              .reject {|param| method_type.type_param_names.include?(param.name) }
              .concat(method_type.type_params)

            result = calculator.in_method_type(method_type: method_type, variables: param_names)
            validate_params_with(merged_params, result: result) do |param|
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

    def import_methods(definition, module_name, module_methods, interfaces_methods, subst)
      new_methods = {} #: Hash[Symbol, Definition::Method]
      interface_method_duplicates = Set[] #: Set[Symbol]

      interfaces_methods.each do |interface, (methods, member)|
        unless interface.args.empty?
          methods.type.is_a?(Types::Interface) or raise
          params = methods.type.args.map do |arg|
            arg.is_a?(Types::Variable) or raise
            arg.name
          end

          interface.args.each do |arg|
            validate_type_presence(arg)
          end

          subst_ = subst + Substitution.build(params, interface.args)
        else
          subst_ = subst
        end

        methods.each do |method|
          if interface_method_duplicates.include?(method.name)
            member.is_a?(AST::Members::Include) || member.is_a?(AST::Members::Extend) or raise

            raise DuplicatedInterfaceMethodDefinitionError.new(
              type: definition.self_type,
              method_name: method.name,
              member: member
            )
          end

          interface_method_duplicates << method.name
          define_method(
            new_methods,
            definition,
            method,
            subst_,
            defined_in: interface.name,
            implemented_in: module_name
          )
        end
      end

      module_methods.each do |method|
        define_method(
          new_methods,
          definition,
          method,
          subst,
          defined_in: module_name,
          implemented_in: module_name.interface? ? nil : module_name
        )
      end

      definition.methods.merge!(new_methods)
    end

    def define_method(methods, definition, method, subst, defined_in:, implemented_in: defined_in)
      existing_method = methods[method.name] || definition.methods[method.name]

      case original = method.original
      when AST::Members::Alias
        original_method = methods[original.old_name] || definition.methods[original.old_name]

        unless original_method
          raise UnknownMethodAliasError.new(
            type_name: definition.type_name,
            original_name: original.old_name,
            aliased_name: original.new_name,
            location: original.location
          )
        end

        method_definition = Definition::Method.new(
          super_method: existing_method,
          defs: original_method.defs.map do |defn|
            defn.update(defined_in: defined_in, implemented_in: implemented_in)
          end,
          accessibility: original_method.accessibility,
          alias_of: original_method
        )
      when AST::Members::MethodDefinition
        if duplicated_method = methods[method.name]
          raise DuplicatedMethodDefinitionError.new(
            type: definition.self_type,
            method_name: method.name,
            members: [original, *duplicated_method.members]
          )
        end

        defs = original.overloads.map do |overload|
          Definition::Method::TypeDef.new(
            type: subst.empty? ? overload.method_type : overload.method_type.sub(subst),
            member: original,
            defined_in: defined_in,
            implemented_in: implemented_in
          )
        end

        # @type var accessibility: RBS::Definition::accessibility
        accessibility =
          if original.instance? && [:initialize, :initialize_copy, :initialize_clone, :initialize_dup, :respond_to_missing?].include?(method.name)
            :private
          else
            method.accessibility
          end
        # Skip setting up `super_method` if `implemented_in` is `nil`, that means the type doesn't have implementation.
        # This typically happens if the type is an interface.
        if implemented_in
          super_method = existing_method
        end

        method_definition = Definition::Method.new(
          super_method: super_method,
          defs: defs,
          accessibility: accessibility,
          alias_of: nil
        )
      when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
        if duplicated_method = methods[method.name]
          raise DuplicatedMethodDefinitionError.new(
            type: definition.self_type,
            method_name: method.name,
            members: [*duplicated_method.members, original]
          )
        end

        attr_type = original.type.sub(subst)
        method_type =
          if method.name.to_s.end_with?("=")
            # setter
            MethodType.new(
              type_params: [],
              type: Types::Function.empty(attr_type).update(
                required_positionals: [
                  Types::Function::Param.new(type: attr_type, name: original.name)
                ]
              ),
              block: nil,
              location: original.location
            )
          else
            # getter
            MethodType.new(
              type_params: [],
              type: Types::Function.empty(attr_type),
              block: nil,
              location: original.location
            )
          end

        if implemented_in
          super_method = existing_method
        end

        method_definition = Definition::Method.new(
          super_method: super_method,
          defs: [
            Definition::Method::TypeDef.new(
              type: method_type,
              member: original,
              defined_in: defined_in,
              implemented_in: implemented_in
            )
          ],
          accessibility: method.accessibility,
          alias_of: nil
        )
      when nil
        # Overloading method definition only

        case
        when methods.key?(method.name)
          # The method is defined in an interface
          super_method = methods[method.name].super_method
        when definition.methods.key?(method.name)
          # The method is defined in the super class
          super_method = existing_method
        else
          # Cannot find any non-overloading method
          raise InvalidOverloadMethodError.new(
            type_name: definition.type_name,
            method_name: method.name,
            kind: :instance,
            members: method.overloads
          )
        end

        method_definition = Definition::Method.new(
          super_method: super_method,
          defs: existing_method.defs.map do |defn|
            defn.update(implemented_in: implemented_in)
          end,
          accessibility: existing_method.accessibility,
          alias_of: existing_method.alias_of
        )
      end

      method.overloads.each do |overloading_def|
        overloading_def.overloads.reverse_each do |overload|
          type_def = Definition::Method::TypeDef.new(
            type: subst.empty? ? overload.method_type : overload.method_type.sub(subst),
            member: overloading_def,
            defined_in: defined_in,
            implemented_in: implemented_in
          )

          method_definition.defs.unshift(type_def)
        end
      end

      methods[method.name] = method_definition
    end

    def try_cache(type_name, cache:)
      cache[type_name] ||= yield
    end

    def expand_alias(type_name)
      expand_alias2(type_name, [])
    end

    def expand_alias1(type_name)
      type_name = env.normalize_type_name(type_name)
      entry = env.type_alias_decls[type_name] or raise "Unknown alias name: #{type_name}"
      as = entry.decl.type_params.each.map { Types::Bases::Any.new(location: nil) }
      expand_alias2(type_name, as)
    end

    def expand_alias2(type_name, args)
      type_name = env.normalize_type_name(type_name)
      entry = env.type_alias_decls[type_name] or raise "Unknown alias name: #{type_name}"

      ensure_namespace!(type_name.namespace, location: entry.decl.location)
      params = entry.decl.type_params.each.map(&:name)

      unless params.size == args.size
        as = "[#{args.join(", ")}]" unless args.empty?
        ps = "[#{params.join(", ")}]" unless params.empty?

        raise "Invalid type application: type = #{type_name}#{as}, decl = #{type_name}#{ps}"
      end

      type = entry.decl.type

      unless params.empty?
        subst = Substitution.build(params, args)
        type = type.sub(subst)
      end

      type
    end

    def update(env:, except:, ancestor_builder:)
      method_builder = self.method_builder.update(env: env, except: except)

      DefinitionBuilder.new(env: env, ancestor_builder: ancestor_builder, method_builder: method_builder).tap do |builder|
        builder.instance_cache.merge!(instance_cache)
        builder.singleton_cache.merge!(singleton_cache)
        builder.singleton0_cache.merge!(singleton0_cache)
        builder.interface_cache.merge!(interface_cache)

        except.each do |name|
          builder.instance_cache.delete(name)
          builder.singleton_cache.delete(name)
          builder.singleton0_cache.delete(name)
          builder.interface_cache.delete(name)
        end
      end
    end

    def validate_type_presence(type)
      case type
      when Types::ClassInstance, Types::ClassSingleton, Types::Interface, Types::Alias
        validate_type_name(type.name, type.location)
      end

      type.each_type do |type|
        validate_type_presence(type)
      end
    end

    def validate_type_name(name, location)
      name = name.absolute! unless name.absolute?
      return if env.type_name?(env.normalize_type_name(name))

      raise NoTypeFoundError.new(type_name: name, location: location)
    end
  end
end
