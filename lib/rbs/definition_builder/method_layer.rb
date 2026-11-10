# frozen_string_literal: true

module RBS
  class DefinitionBuilder
    # The methods one module gives to a definition -- the methods of a class, a module, the singleton class of
    # them, or an interface, with the methods of the interfaces mixed in it
    #
    # A template is independent from the definition that has the methods. It is shared by the definitions of the
    # module itself and of the classes and modules that inherit the module.
    #
    class LayerTemplate
      class Entry
        attr_reader :name

        # The definition of the method in the module
        attr_reader :definition

        # The names of the modules recorded in the type defs of the method
        attr_reader :defined_in
        attr_reader :implemented_in

        # The index of the interface in the template if the method is one of an interface mixed in the module
        attr_reader :interface_index

        # The index of the entry in the order the methods are defined
        attr_reader :position

        def initialize(name:, definition:, defined_in:, implemented_in:, interface_index:, position:)
          @name = name
          @definition = definition
          @defined_in = defined_in
          @implemented_in = implemented_in
          @interface_index = interface_index
          @position = position
        end
      end

      attr_reader :type_name

      # The methods in the order they are defined
      #
      # A name has two entries if the module overloads a method of an interface, or defines an alias with the name.
      #
      attr_reader :entries

      # The substitutions of the type applications of the interfaces, `nil` if an interface has no type argument
      attr_reader :interface_substs

      # The definitions of the self types of a module, that have the original method of aliases
      attr_reader :self_types

      # The entries that are defined only if the definition has other methods, or cannot be defined
      attr_reader :checks

      # The duplicated definition of a method among the interfaces
      attr_reader :duplicated_interface_method

      # The modules mixed in the module, with the substitutions of their type applications
      #
      # The methods of `included_modules` and `extended_modules` are defined before the methods of the template,
      # and the ones of `prepended_modules` are defined after them.
      #
      attr_reader :included_modules
      attr_reader :prepended_modules
      attr_reader :extended_modules

      # The members that define the instance variables and class variables of the module
      #
      # A member is paired with the substitution that aligns the type parameters of the declaration it belongs to.
      #
      attr_reader :variables

      def initialize(type_name:, methods:, interfaces:, self_types: nil, included_modules: [], prepended_modules: [], extended_modules: [], variables: [])
        @type_name = type_name
        @entries = {}
        @interface_substs = []
        @self_types = self_types
        @checks = []
        @duplicated_interface_method = nil
        @size = 0
        @included_modules = included_modules
        @prepended_modules = prepended_modules
        @extended_modules = extended_modules
        @variables = variables

        interfaces.each_with_index do |(ancestor, interface_methods, member, subst), index|
          @interface_substs << subst

          interface_methods.each do |method|
            if @entries.key?(method.name)
              @duplicated_interface_method = [method.name, member]
              return
            end

            insert(
              Entry.new(
                name: method.name,
                definition: method,
                defined_in: ancestor.name,
                implemented_in: type_name,
                interface_index: index,
                position: @size
              )
            )
          end
        end

        implemented_in = type_name.interface? ? nil : type_name

        methods.each do |method|
          insert(
            Entry.new(
              name: method.name,
              definition: method,
              defined_in: type_name,
              implemented_in: implemented_in,
              interface_index: nil,
              position: @size
            )
          )
        end
      end

      private

      def insert(entry)
        name = entry.name

        case earlier = @entries[name]
        when nil
          @entries[name] = entry
        when Entry
          @entries[name] = [earlier, entry]
        when Array
          earlier << entry
        end

        @size += 1

        case original = entry.definition.original
        when AST::Members::Alias
          # The original method is given by the other modules, unless it is defined before the alias
          @checks << entry unless defined_before?(original.old_name, entry.position)
        when nil
          # Adding overloads needs the method to overload
          @checks << entry unless earlier
        else
          # Defining a method of an interface again is an error
          @checks << entry if earlier
        end
      end

      def defined_before?(name, position)
        case entry = @entries[name]
        when Entry
          entry.position < position
        when Array
          entry.any? {|e| e.position < position }
        else
          false
        end
      end
    end

    # A layer is the methods of a template, with the type arguments given to the module
    #
    # It builds the methods of a definition. A method depends on the methods of the definition that are defined
    # before the layer -- the method it overrides or the original method of an alias -- and the layer returns the
    # same method for the same ones. Definitions share the method objects in this way.
    #
    class Layer
      attr_reader :template
      attr_reader :subst

      def initialize(template, subst)
        @template = template
        @subst = subst
        @cache = []
        @interface_substs = nil
        @self_type_methods = nil
      end

      # Returns the method of the layer, `nil` if the layer doesn't have the method
      #
      # `stack` is the stack of the definition that has the layer at the `index`.
      #
      def resolve(name, stack, index)
        case entry = @template.entries[name]
        when LayerTemplate::Entry
          build(entry, nil, stack, index)
        when Array
          method = nil #: Definition::Method?
          entry.each do |e|
            method = build(e, method, stack, index)
          end
          method
        end
      end

      # Returns the method defined by the entries before the `position`
      #
      def resolve_before(name, position, stack, index)
        case entry = @template.entries[name]
        when LayerTemplate::Entry
          build(entry, nil, stack, index) if entry.position < position
        when Array
          method = nil #: Definition::Method?
          entry.each do |e|
            method = build(e, method, stack, index) if e.position < position
          end
          method
        end
      end

      private

      # Builds the method of the entry
      #
      # `layer_method` is the method defined with the name by an earlier entry of the layer.
      #
      def build(entry, layer_method, stack, index)
        existing_method = layer_method || stack.resolve(entry.name, index)

        if (original = entry.definition.original).is_a?(AST::Members::Alias)
          old_name = original.old_name
          original_method =
            resolve_before(old_name, entry.position, stack, index) ||
              stack.resolve(old_name, index) ||
              (entry.interface_index ? nil : self_type_method(old_name))

          unless original_method
            raise UnknownMethodAliasError.new(
              type_name: stack.type_name,
              original_name: old_name,
              aliased_name: original.new_name,
              location: original.location
            )
          end
        end

        # The built methods are recorded as the triples of the methods it depends on and the result
        if cache = @cache[entry.position]
          i = 0
          size = cache.size
          while i < size
            if cache[i].equal?(existing_method) && cache[i + 1].equal?(original_method)
              return cache[i + 2] || raise
            end
            i += 3
          end
        else
          cache = @cache[entry.position] = []
        end

        method = construct(entry, existing_method, layer_method, original_method, stack)
        cache.push(existing_method, original_method, method)
        method
      end

      def construct(entry, existing_method, layer_method, original_method, stack)
        method = entry.definition
        name = entry.name
        defined_in = entry.defined_in
        implemented_in = entry.implemented_in
        subst = entry_subst(entry)

        case original = method.original
        when AST::Members::Alias
          original_method or raise

          accessibility = special_accessibility(original.instance?, original.new_name) || original_method.accessibility

          method_definition = Definition::Method.new(
            super_method: existing_method,
            defs: original_method.defs.map do |defn|
              defn.update(defined_in: defined_in, implemented_in: implemented_in)
            end,
            accessibility: accessibility,
            alias_of: original_method,
            alias_member: original
          )

          method_definition.annotations.replace(original.annotations)
        when AST::Members::MethodDefinition
          if layer_method
            raise DuplicatedMethodDefinitionError.new(
              type: stack.self_type,
              method_name: name,
              members: [original, *layer_method.members]
            )
          end

          defs = original.overloads.map do |overload|
            Definition::Method::TypeDef.new(
              type: subst.empty? ? overload.method_type : overload.method_type.sub(subst),
              member: original,
              defined_in: defined_in,
              implemented_in: implemented_in
            ).tap do |type_def|
              # Keep the original annotations given to overloads.
              type_def.overload_annotations.replace(overload.annotations)
            end
          end

          # Respect the visibility of the original method definition.
          accessibility = original.visibility || special_accessibility(original.instance?, name) || method.accessibility

          # Skip setting up `super_method` if `implemented_in` is `nil`, that means the type doesn't have implementation.
          # This typically happens if the type is an interface.
          if implemented_in
            super_method = existing_method
          end

          method_definition = Definition::Method.new(
            super_method: super_method,
            defs: defs,
            accessibility: accessibility,
            alias_of: nil,
            alias_member: nil
          )

          method_definition.annotations.replace(original.annotations)
        when AST::Members::AttrReader, AST::Members::AttrWriter, AST::Members::AttrAccessor
          if layer_method
            raise DuplicatedMethodDefinitionError.new(
              type: stack.self_type,
              method_name: name,
              members: [*layer_method.members, original]
            )
          end

          attr_type = original.type.sub(subst)
          method_type =
            if name.end_with?("=")
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

          # Respect the visibility of the original method definition.
          accessibility = original.visibility || special_accessibility(original.kind == :instance, name) || method.accessibility

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
            accessibility: accessibility,
            alias_of: nil,
            alias_member: nil
          )

          method_definition.annotations.replace(original.annotations)
        when AST::Ruby::Members::AttrReaderMember, AST::Ruby::Members::AttrWriterMember, AST::Ruby::Members::AttrAccessorMember
          if layer_method
            raise DuplicatedMethodDefinitionError.new(
              type: stack.self_type,
              method_name: name,
              members: [*layer_method.members, original]
            )
          end

          attr_type = original.type || Types::Bases::Any.new(location: nil)
          method_type =
            if name.end_with?("=")
              # setter
              MethodType.new(
                type_params: [],
                type: Types::Function.empty(attr_type).update(
                  required_positionals: [
                    Types::Function::Param.new(type: attr_type, name: name.to_s.chomp("=").to_sym)
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
            alias_of: nil,
            alias_member: nil
          )
        when AST::Ruby::Members::DefMember
          if layer_method
            raise DuplicatedMethodDefinitionError.new(
              type: stack.self_type,
              method_name: name,
              members: [original, *layer_method.members]
            )
          end

          if original.method_type.empty? && existing_method
            # Unannotated method with a parent definition → inherit from the parent, like @rbs ...
            method_definition = Definition::Method.new(
              super_method: existing_method,
              defs: existing_method.defs.map { |defn| defn.update(implemented_in: implemented_in) },
              accessibility: :public,
              alias_of: existing_method.alias_of,
              alias_member: nil
            )

            method_definition.annotations.replace(existing_method.annotations)
          else
            defs = original.overloads.map do |overload|
              Definition::Method::TypeDef.new(
                type: subst.empty? ? overload.method_type : overload.method_type.sub(subst),
                member: original,
                defined_in: defined_in,
                implemented_in: implemented_in
              ).tap do |type_def|
                # Keep the original annotations given to overloads.
                type_def.overload_annotations.replace(overload.annotations)
              end
            end

            method_definition = Definition::Method.new(
              super_method: existing_method,
              defs: defs,
              accessibility: :public,
              alias_of: nil,
              alias_member: nil
            )
          end
        when nil
          # Overloading method definition only

          unless existing_method
            # Cannot find any non-overloading method
            raise InvalidOverloadMethodError.new(
              type_name: stack.type_name,
              method_name: name,
              kind: :instance,
              members: method.overloads
            )
          end

          if layer_method
            # The method is defined in an interface
            super_method = layer_method.super_method
          else
            # The method is defined in the super class
            super_method = existing_method
          end

          method_definition = Definition::Method.new(
            super_method: super_method,
            defs: existing_method.defs.map do |defn|
              defn.update(implemented_in: implemented_in)
            end,
            accessibility: existing_method.accessibility,
            alias_of: existing_method.alias_of,
            alias_member: nil
          )

          method_definition.annotations.replace(existing_method.annotations)
        end

        method.overloads.each do |overloading_def|
          overloading_def.overloads.reverse_each do |overload|
            type_def = Definition::Method::TypeDef.new(
              type: subst.empty? ? overload.method_type : overload.method_type.sub(subst),
              member: overloading_def,
              defined_in: defined_in,
              implemented_in: implemented_in
            )

            type_def.overload_annotations.replace(overload.annotations)

            method_definition.defs.unshift(type_def)
          end

          method_definition.annotations.concat(overloading_def.annotations)
        end

        method_definition.defs.each do |type_def|
          type_def.member_annotations.replace(method_definition.annotations)
        end

        method_definition
      end

      def entry_subst(entry)
        if index = entry.interface_index
          substs = @interface_substs ||= [] #: Array[Substitution?]
          substs[index] ||=
            if s = @template.interface_substs[index]
              @subst + s
            else
              @subst
            end
        else
          @subst
        end
      end

      # Returns the method of the self types of a module
      #
      # The later self type has the precedence.
      #
      def self_type_method(name)
        self_types = @template.self_types or return
        return if self_types.empty?

        methods = @self_type_methods ||= {} #: Hash[Symbol, Definition::Method?]

        methods.fetch(name) do
          method = nil #: Definition::Method?

          self_types.reverse_each do |table, subst|
            if method = table[name]
              method = method.sub(@subst + subst)
              break
            end
          end

          methods[name] = method
        end
      end

      def special_accessibility(is_instance, method_name)
        if is_instance
          case method_name
          when :initialize, :initialize_copy, :initialize_clone, :initialize_dup, :respond_to_missing?
            :private
          end
        end
      end
    end

    # The layers of a definition, that give the methods of the definition
    #
    # A stack has the layers of the type and the modules mixed in it. The methods of the other ancestors are given
    # by the `parent`, that is the table of the methods of another definition -- the one of the super class.
    #
    # The layers and the parent are given while the definition is built, before a method is resolved.
    #
    class LayerStack
      attr_reader :type_name
      attr_reader :self_type
      attr_reader :layers
      attr_reader :parent
      attr_reader :parent_subst

      def initialize(type_name:, self_type:)
        @type_name = type_name
        @self_type = self_type
        @layers = []
        @parent = nil
        @parent_subst = nil
        @index = nil
        @parent_methods = nil
      end

      def set_parent(table, subst = nil)
        @parent = table
        @parent_subst = subst unless subst&.empty?
      end

      def method_names
        names = @parent&.keys&.dup || []
        parent = @parent

        index.each_key do |name|
          names << name unless parent&.key?(name)
        end

        names
      end

      def method?(name)
        index.key?(name) || @parent&.key?(name) || false
      end

      def resolve_method(name)
        resolve(name, @layers.size)
      end

      def resolve_methods(methods)
        if parent = @parent
          parent_methods = parent.resolved_methods

          if @parent_subst
            parent_methods.each do |name, method|
              methods[name] = substitute(method)
            end
          else
            methods.merge!(parent_methods)
          end
        end

        # The methods of the layers override the ones of the parent
        size = @layers.size
        index.each_key do |name|
          methods[name] = resolve(name, size) || raise
        end
      end

      # Returns the method defined before the layer of the `limit`
      #
      def resolve(name, limit)
        case i = index[name]
        when Integer
          return @layers.fetch(i).resolve(name, self, i) if i < limit
        when Array
          # The indexes are in the ascending order
          j = i.size - 1
          while j >= 0
            k = i.fetch(j)
            return @layers.fetch(k).resolve(name, self, k) if k < limit
            j -= 1
          end
        end

        parent_method(name)
      end

      # Raises an error if a method of the layers cannot be defined
      #
      def validate!
        @layers.each_with_index do |layer, index|
          template = layer.template

          if dup = template.duplicated_interface_method
            method_name, member = dup
            raise DuplicatedInterfaceMethodDefinitionError.new(type: self_type, method_name: method_name, member: member)
          end

          template.checks.each do |entry|
            layer.resolve_before(entry.name, entry.position + 1, self, index)
          end
        end
      end

      private

      # The indexes of the layers that define a method
      #
      def index
        @index ||= begin
          index = {} #: Hash[Symbol, Integer | Array[Integer]]

          @layers.each_with_index do |layer, i|
            layer.template.entries.each_key do |name|
              case indexes = index[name]
              when nil
                index[name] = i
              when Integer
                index[name] = [indexes, i]
              when Array
                indexes << i
              end
            end
          end

          index
        end
      end

      def parent_method(name)
        parent = @parent or return
        method = parent[name] or return

        if @parent_subst
          substitute(method)
        else
          method
        end
      end

      # Substitutes the method types of a method of the parent
      #
      # Returns the same method if the method types have no type variables, to share the method with the parent.
      #
      def substitute(method)
        subst = @parent_subst or raise

        unless methods = @parent_methods
          methods = @parent_methods = {}
          methods.compare_by_identity
        end

        methods[method] ||= begin
          super_method = method.super_method
          new_super_method = super_method && substitute(super_method)

          changed = !new_super_method.equal?(super_method)

          defs = method.defs.map do |defn|
            type = defn.type
            if LayerStack.closed_method_type?(type)
              defn
            else
              changed = true
              defn.update(type: type.sub(subst))
            end
          end

          if changed
            method.update(super_method: new_super_method, defs: defs)
          else
            method
          end
        end
      end

      def self.closed_method_type?(method_type)
        return false unless method_type.type_params.empty?

        method_type.each_type do |type|
          return false unless closed_type?(type)
        end

        true
      end

      def self.closed_type?(type)
        return false if type.is_a?(Types::Variable)

        type.each_type do |t|
          return false unless closed_type?(t)
        end

        true
      end
    end

    # The methods of the singleton class of a class, where `.new` has the type of `#initialize`
    #
    # It replaces the `.new` method defined in `::Class` and the aliases of it with the methods that have the
    # method types of `#initialize` of the class.
    #
    class SingletonMethods
      def initialize(type_name:, type_params:, methods:, instance_methods:)
        @type_name = type_name
        @type_params = type_params
        @methods = methods
        @instance_methods = instance_methods
        @new_methods = nil
        @new_methods_resolved = false
        @aliases = nil
      end

      def method_names
        @methods.keys
      end

      def method?(name)
        @methods.key?(name)
      end

      def resolve_method(name)
        method = @methods[name] or return
        new_method, typed_new = new_methods

        if new_method && typed_new
          replace(name, method, new_method, typed_new)
        else
          method
        end
      end

      def resolve_methods(methods)
        @methods.resolve_methods_into(methods)
        new_method, typed_new = new_methods

        if new_method && typed_new
          methods.each do |name, method|
            if name == :new || method.alias_of
              methods[name] = replace(name, method, new_method, typed_new)
            end
          end
        end
      end

      private

      # Returns the method that replaces `method` -- `.new` or an alias of it -- or `method` itself
      #
      def replace(name, method, new_method, typed_new)
        return typed_new if name == :new

        # @type var m: Definition::Method?
        m = method
        while m
          alias_of = m.alias_of or break

          if alias_of.equal?(new_method) || alias_of == new_method
            aliases = @aliases ||= {} #: Hash[Symbol, Definition::Method]
            return aliases[name] ||= method.update(alias_of: typed_new, defs: typed_new.defs)
          end

          m = alias_of
        end

        method
      end

      # Returns the pair of `.new` defined in `::Class` and the one with the types of `#initialize`
      #
      # Returns `nil` if `.new` is not replaced.
      #
      def new_methods
        unless @new_methods_resolved
          @new_methods = build_new_methods
          @new_methods_resolved = true
        end

        @new_methods
      end

      def build_new_methods
        new_method = @methods[:new] or return
        new_method.defs.all? {|d| d.defined_in == BuiltinNames::Class.name } or return
        initialize = @instance_methods[:initialize] or return

        [new_method, build_typed_new(new_method, initialize)]
      end

      def build_typed_new(new_method, initialize)
        type_name = @type_name
        class_params = @type_params

        Definition::Method.new(
          super_method: new_method,
          defs: initialize.defs.map do |initialize_def|
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

            method_type = method_type.map_type do |type|
              case type
              when Types::Bases::Self
                Types::ClassInstance.new(
                  name: type_name,
                  args: class_params.map {|param| Types::Variable.new(name: param.name, location: param.location) },
                  location: nil
                )
              else
                type
              end
            end

            method_type = method_type.update(
              type: method_type.type.with_return_type(
                Types::ClassInstance.new(
                  name: type_name,
                  args: class_params.map {|param| Types::Variable.new(name: param.name, location: param.location) },
                  location: nil
                )
              )
            )

            Definition::Method::TypeDef.new(
              type: method_type,
              member: initialize_def.member,
              defined_in: initialize_def.defined_in,
              implemented_in: initialize_def.implemented_in
            ).tap do |type_def|
              type_def.overload_annotations.replace(initialize_def.overload_annotations)
            end
          end,
          accessibility: :public,
          alias_of: nil,
          alias_member: nil
        )
      end
    end
  end
end
