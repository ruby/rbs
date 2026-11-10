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

    attr_reader :instance_templates
    attr_reader :singleton_templates
    attr_reader :interface_templates

    attr_reader :plain_layers
    attr_reader :generic_layers

    attr_reader :self_type_prefix_cache

    # The methods and variables given to the modules by their self types
    #
    class SelfTypePrefix
      attr_reader :methods
      attr_reader :instance_variables
      attr_reader :class_variables

      def initialize(methods:)
        @methods = methods
        @instance_variables = {}
        @class_variables = {}
      end
    end

    def initialize(env:, ancestor_builder: nil, method_builder: nil)
      @env = env
      @ancestor_builder = ancestor_builder || AncestorBuilder.new(env: env)
      @method_builder = method_builder || MethodBuilder.new(env: env)

      @instance_cache = {}
      @singleton_cache = {}
      @singleton0_cache = {}
      @interface_cache = {}

      @instance_templates = {}
      @singleton_templates = {}
      @interface_templates = {}
      @plain_layers = {}
      @plain_layers.compare_by_identity
      @generic_layers = {}
      @generic_layers.compare_by_identity
      @self_type_prefix_cache = {}

      @namespaces = {}
    end

    def ensure_namespace!(namespace, location:)
      # The namespaces that passed the validation are recorded, because the types in a namespace share the validation
      return if @namespaces.key?(namespace)

      namespace.ascend do |ns|
        unless ns.empty?
          NoTypeFoundError.check!(ns.to_type_name, env: env, location: location)
        end
      end

      @namespaces[namespace] = true
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
        stack = LayerStack.new(type_name: type_name, self_type: self_type)
        table = Definition::MethodTable.new(stack)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors, methods: table).tap do |definition|
          methods = method_builder.build_interface(type_name)
          one_ancestors = ancestor_builder.one_interface_ancestors(type_name)
          validate_type_params(definition, methods: methods, ancestors: one_ancestors)

          stack.layers << layer(interface_template(type_name), subst)
          stack.validate!
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

      AST::TypeParam.application(params, args) || Substitution.new()
    end

    def build_instance(type_name)
      type_name = env.normalize_module_name(type_name)

      try_cache(type_name, cache: instance_cache) do
        entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.primary_decl.location)

        ancestors = ancestor_builder.instance_ancestors(type_name)
        args = entry.type_params.map {|param| Types::Variable.new(name: param.name, location: param.location) }
        self_type = Types::ClassInstance.new(name: type_name, args: args, location: nil)

        stack = LayerStack.new(type_name: type_name, self_type: self_type)
        table = Definition::MethodTable.new(stack)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors, methods: table).tap do |definition|
          one_ancestors = ancestor_builder.one_instance_ancestors(type_name)
          methods = method_builder.build_instance(type_name)

          validate_type_params definition, methods: methods, ancestors: one_ancestors

          if entry.is_a?(Environment::ClassEntry)
            if super_class = one_ancestors.super_class
              super_class.is_a?(Definition::Ancestor::Instance) or raise

              defn = build_instance(super_class.name)

              if super_class.args.empty?
                stack.set_parent(defn.methods)
                definition.instance_variables.merge!(defn.instance_variables)
                definition.class_variables.merge!(defn.class_variables)
              else
                super_class.args.each do |arg|
                  validate_type_presence(arg)
                end

                super_subst = tapp_subst(super_class.name, super_class.args)

                stack.set_parent(defn.methods, super_subst)
                definition.instance_variables.merge!(defn.instance_variables.transform_values {|v| v.sub(super_subst) })
                definition.class_variables.merge!(defn.class_variables.transform_values {|v| v.sub(super_subst) })
              end
            end
          end

          if entry.is_a?(Environment::ModuleEntry)
            if self_types = one_ancestors.self_types
              if default_self_types?(self_types)
                # The methods of `Object` are shared by the modules without self type constraints
                prefix = object_self_type_prefix(definition)

                stack.set_parent(prefix.methods)
                definition.instance_variables.merge!(prefix.instance_variables)
                definition.class_variables.merge!(prefix.class_variables)
              else
                self_types.each do |ans|
                  ans.args.each do |arg|
                    validate_type_presence(arg)
                  end

                  subst = tapp_subst(ans.name, ans.args)
                  if ans.name.interface?
                    stack.layers << layer(interface_template(ans.name), subst)
                  else
                    instance_layers(definition, stack.layers, ans.name, subst, define_class_vars: true)
                  end
                end
              end
            end
          end

          instance_layers(definition, stack.layers, type_name, Substitution.new, define_class_vars: true)
          stack.validate!
        end
      end
    end

    # Builds a definition for singleton without .new method.
    #
    def build_singleton0(type_name)
      try_cache type_name, cache: singleton0_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton0: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.primary_decl.location)

        ancestors = ancestor_builder.singleton_ancestors(type_name)
        self_type = Types::ClassSingleton.new(name: type_name, location: nil)

        stack = LayerStack.new(type_name: type_name, self_type: self_type)
        table = Definition::MethodTable.new(stack)

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors, methods: table).tap do |definition|
          one_ancestors = ancestor_builder.one_singleton_ancestors(type_name)

          if super_class = one_ancestors.super_class
            case super_class
            when Definition::Ancestor::Instance
              defn = build_instance(super_class.name)
            when Definition::Ancestor::Singleton
              defn = build_singleton0(super_class.name)
            end

            stack.set_parent(defn.methods)
            definition.instance_variables.merge!(defn.instance_variables)
          end

          template = singleton_template(type_name)

          template.extended_modules.each do |name, subst|
            instance_layers(definition, stack.layers, name, subst, define_class_vars: false)
          end

          stack.layers << layer(template, Substitution.new)
          stack.validate!

          entry.each_decl do |decl|
            decl.members.each do |member|
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
                    insert_variable(type_name, definition.instance_variables, name: ivar_name, type: member.type, source: member)
                  end
                end

              when AST::Members::ClassInstanceVariable
                insert_variable(type_name, definition.instance_variables, name: member.name, type: member.type, source: member)
              end
            end
          end

          instance_definition = build_instance(type_name)
          definition.class_variables.replace(instance_definition.class_variables)
        end
      end
    end

    def build_singleton(type_name)
      type_name = env.normalize_module_name(type_name)

      try_cache type_name, cache: singleton_cache do
        entry = env.class_decls[type_name] or raise "Unknown name for build_singleton: #{type_name}"
        ensure_namespace!(type_name.namespace, location: entry.primary_decl.location)

        ancestors = ancestor_builder.singleton_ancestors(type_name)
        self_type = Types::ClassSingleton.new(name: type_name, location: nil)

        definition0 = build_singleton0(type_name)

        table =
          if entry.is_a?(Environment::ClassEntry)
            # `.new` has the type of `#initialize`
            Definition::MethodTable.new(
              SingletonMethods.new(
                type_name: type_name,
                type_params: entry.type_params,
                methods: definition0.methods,
                instance_methods: build_instance(type_name).methods
              )
            )
          else
            definition0.methods
          end

        Definition.new(type_name: type_name, entry: entry, self_type: self_type, ancestors: ancestors, methods: table).tap do |definition|
          definition.instance_variables.merge!(definition0.instance_variables)
          definition.class_variables.merge!(definition0.class_variables)
        end
      end
    end

    # Returns the template of the instance methods of a class or a module
    #
    def instance_template(type_name)
      instance_templates[type_name] ||= begin
        entry = env.class_decls[type_name] or raise "Unknown name for build_instance: #{type_name}"
        one_ancestors = ancestor_builder.one_instance_ancestors(type_name)
        methods = method_builder.build_instance(type_name)

        self_types = one_ancestors.each_self_type.map do |self_type|
          self_type.args.each do |arg|
            validate_type_presence(arg)
          end

          self_type_defn = self_type.name.interface? ? build_interface(self_type.name) : build_instance(self_type.name)

          [self_type_defn.methods, tapp_subst(self_type.name, self_type.args)] #: [Definition::MethodTable, Substitution]
        end

        included_modules = mixin_substs(one_ancestors.each_included_module)
        interfaces = interface_mixins(one_ancestors.each_included_interface)
        prepended_modules = mixin_substs(one_ancestors.each_prepended_module)

        variables = [] #: Array[[Substitution?, LayerTemplate::variable_member]]
        entry.each_decl do |decl|
          align_params = nil #: Substitution?
          aligned = false

          decl.members.each do |member|
            case member
            when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
              next unless member.kind == :instance
              next if member.ivar_name == false
            when AST::Ruby::Members::AttrReaderMember, AST::Ruby::Members::AttrWriterMember, AST::Ruby::Members::AttrAccessorMember,
              AST::Ruby::Members::InstanceVariableMember, AST::Members::InstanceVariable, AST::Members::ClassVariable
              # ok
            else
              next
            end

            unless aligned
              align_params = entry.align_params(decl)
              aligned = true
            end

            variables << [align_params, member]
          end
        end

        LayerTemplate.new(
          type_name: type_name,
          methods: methods,
          interfaces: interfaces,
          self_types: self_types,
          included_modules: included_modules,
          prepended_modules: prepended_modules,
          variables: variables
        )
      end
    end

    # Returns the template of the singleton methods of a class or a module
    #
    def singleton_template(type_name)
      singleton_templates[type_name] ||= begin
        one_ancestors = ancestor_builder.one_singleton_ancestors(type_name)
        methods = method_builder.build_singleton(type_name)

        extended_modules = mixin_substs(one_ancestors.each_extended_module)
        interfaces = interface_mixins(one_ancestors.each_extended_interface)

        LayerTemplate.new(type_name: type_name, methods: methods, interfaces: interfaces, extended_modules: extended_modules)
      end
    end

    # Returns the layer of the template with the substitution
    #
    # The layers of a template with the same substitution are the same object, to share the methods between definitions.
    #
    def layer(template, subst)
      if subst.empty?
        plain_layers[template] ||= Layer.new(template, subst)
      else
        layers = generic_layers[template] ||= {}
        layers[subst.mapping] ||= Layer.new(template, subst)
      end
    end

    # Returns the template of the methods of an interface
    #
    def interface_template(type_name)
      interface_templates[type_name] ||= begin
        included_interfaces = ancestor_builder.interface_ancestors(type_name).ancestors #: Array[Definition::Ancestor::Instance]
        included_interfaces = included_interfaces.reject {|ancestor| ancestor.source == nil }

        LayerTemplate.new(
          type_name: type_name,
          methods: method_builder.build_interface(type_name),
          interfaces: interface_methods(included_interfaces)
        )
      end
    end

    # Adds the layers of a class or a module to `layers`, and the variables to `definition`
    #
    # It processes includes and prepends recursively.
    # If `define_class_vars:` is falsy, it skips inserting class variables.
    #
    def instance_layers(definition, layers, type_name, subst, define_class_vars:)
      template = instance_template(type_name)

      template.included_modules.each do |name, s|
        instance_layers(definition, layers, name, subst + s, define_class_vars: define_class_vars)
      end

      layers << layer(template, subst)

      template.prepended_modules.each do |name, s|
        instance_layers(definition, layers, name, subst + s, define_class_vars: define_class_vars)
      end

      template.variables.each do |align_params, member|
        if align_params
          subst_ = subst + align_params
        else
          subst_ = subst
        end

        case member
        when AST::Members::AttrReader, AST::Members::AttrAccessor, AST::Members::AttrWriter
          ivar_name = member.ivar_name || :"@#{member.name}"

          insert_variable(
            type_name,
            definition.instance_variables,
            name: ivar_name,
            type: member.type.sub(subst_),
            source: member
          )

        when AST::Ruby::Members::AttrReaderMember, AST::Ruby::Members::AttrWriterMember, AST::Ruby::Members::AttrAccessorMember
          member.names.each do |name|
            ivar_name = :"@#{name}"
            attr_type = member.type || Types::Bases::Any.new(location: nil)

            insert_variable(
              type_name,
              definition.instance_variables,
              name: ivar_name,
              type: attr_type,
              source: member
            )
          end

        when AST::Ruby::Members::InstanceVariableMember
          insert_variable(
            type_name,
            definition.instance_variables,
            name: member.name,
            type: member.type,
            source: member
          )

        when AST::Members::InstanceVariable
          insert_variable(
            type_name,
            definition.instance_variables,
            name: member.name,
            type: member.type.sub(subst_),
            source: member
          )

        when AST::Members::ClassVariable
          if define_class_vars
            insert_variable(type_name, definition.class_variables, name: member.name, type: member.type, source: member)
          end
        end
      end
    end

    # Returns the pairs of the names of the modules and the substitutions of the type applications
    #
    def mixin_substs(mixins)
      mixins.map do |mod|
        mod.args.each do |arg|
          validate_type_presence(arg)
        end

        [mod.name, tapp_subst(mod.name, mod.args)] #: [TypeName, Substitution]
      end
    end

    # Returns the interfaces mixed in a module, with the interfaces they include
    #
    def interface_mixins(interfaces)
      all_interfaces = interfaces.flat_map do |interface|
        other_interfaces = ancestor_builder.interface_ancestors(interface.name).ancestors #: Array[Definition::Ancestor::Instance]
        other_interfaces = other_interfaces.select {|ancestor| ancestor.source }
        [interface, *other_interfaces]
      end

      interface_methods(all_interfaces)
    end

    def default_self_types?(self_types)
      if self_types.size == 1
        self_type = self_types[0]
        self_type.source.nil? && self_type.args.empty? && self_type.name == BuiltinNames::Object.name
      else
        false
      end
    end

    # Returns the methods and variables of `Object`, that are given to the modules without self type constraints
    #
    # They don't include the ones of the super class of `Object`.
    #
    def object_self_type_prefix(definition)
      type_name = BuiltinNames::Object.name

      self_type_prefix_cache[type_name] ||= begin
        stack = LayerStack.new(type_name: definition.type_name, self_type: definition.self_type)
        prefix = SelfTypePrefix.new(methods: Definition::MethodTable.new(stack))

        instance_layers(prefix, stack.layers, type_name, tapp_subst(type_name, []), define_class_vars: true)
        stack.validate!

        prefix
      end
    end

    def interface_methods(interface_ancestors)
      # The same interface is mixed in once, even if it is given through two or more interfaces
      interface_methods = {} #: Hash[Definition::Ancestor::Instance, LayerTemplate::interface_mixin]

      interface_ancestors.each do |mod|
        source =
          case mod.source
          when AST::Members::Include, AST::Members::Extend
            mod.source
          else
            raise "Interface mixin must be include/extend: #{mod.source.inspect}"
          end

        methods = method_builder.build_interface(mod.name)

        unless mod.args.empty?
          mod.args.each do |arg|
            validate_type_presence(arg)
          end

          type_params = env.interface_decls.fetch(mod.name).decl.type_params
          subst = AST::TypeParam.application(type_params, mod.args)
        end

        interface_methods[mod] = [mod, methods, source, subst]
      end

      interface_methods.values
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
        when AST::Ruby::Declarations::ClassDecl
          nil
        else
          raise "Unexpected `:super` source location with #{decl.class}"
        end
      else
        source.location
      end
    end

    def validate_type_params(definition, ancestors:, methods:)
      type_params = definition.type_params_decl

      # Without type params nothing can violate the variance: the ancestor validation
      # iterates the (empty) params, and the type params of the methods themselves are
      # invariant, which `Result#compatible?` always accepts
      return if type_params.empty?

      calculator = VarianceCalculator.new(builder: self)
      param_names = type_params.each.map(&:name)

      ancestors.each_ancestor do |ancestor|
        case ancestor
        when Definition::Ancestor::Instance
          result = calculator.in_inherit(name: ancestor.name, args: ancestor.args, variables: param_names)
          validate_params_with(type_params, result: result) do |param|
            decl = case entry = definition.entry
                   when Environment::ModuleEntry, Environment::ClassEntry
                     entry.primary_decl
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

    def insert_variable(type_name, variables, name:, type:, source:)
      variables[name] = Definition::Variable.new(
        parent_variable: variables[name],
        type: type,
        declared_in: type_name,
        source: source
      )

      validate_variable(variables[name])
    end

    def validate_variable(var)
      return unless var.parent_variable

      # Ignore attrs
      variables = [] #: Array[Definition::Variable]
      tmp_var = var
      while tmp_var
        case tmp_var.source
        when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
          # nop
        when AST::Ruby::Members::AttrReaderMember, AST::Ruby::Members::AttrWriterMember, AST::Ruby::Members::AttrAccessorMember
          # nop
        else
          variables << tmp_var
        end

        tmp_var = tmp_var.parent_variable
      end

      # Duplicates should be eliminated, so there can't be more than 3.
      return unless variables.length == 2

      l, r = variables #: [Definition::Variable, Definition::Variable]

      case l.source
      when AST::Members::InstanceVariable
        if r.source.instance_of?(AST::Members::InstanceVariable) && l.declared_in == r.declared_in
          raise InstanceVariableDuplicationError.new(type_name: l.declared_in, variable_name: l.source.name, location: l.source.location)
        end
      when AST::Members::ClassInstanceVariable
        if r.source.instance_of?(AST::Members::ClassInstanceVariable) && l.declared_in == r.declared_in
          raise ClassInstanceVariableDuplicationError.new(type_name: l.declared_in, variable_name: l.source.name, location: l.source.location)
        end
      when AST::Ruby::Members::InstanceVariableMember
        if l.declared_in == r.declared_in
          raise InstanceVariableDuplicationError.new(type_name: l.declared_in, variable_name: l.source.name, location: l.source.location)
        end
      end
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

        builder.instance_templates.merge!(instance_templates)
        builder.singleton_templates.merge!(singleton_templates)
        builder.interface_templates.merge!(interface_templates)

        builder.self_type_prefix_cache.merge!(self_type_prefix_cache)

        except.each do |name|
          builder.instance_cache.delete(name)
          builder.singleton_cache.delete(name)
          builder.singleton0_cache.delete(name)
          builder.interface_cache.delete(name)

          builder.instance_templates.delete(name)
          builder.singleton_templates.delete(name)
          builder.interface_templates.delete(name)

          builder.self_type_prefix_cache.delete(name)
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
      absolute = name.absolute? ? name : name.absolute!
      return if env.type_name?(env.normalize_type_name(absolute))

      # Report the name as it is written in the signature
      raise NoTypeFoundError.new(type_name: name, location: location)
    end
  end
end
