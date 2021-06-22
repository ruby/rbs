module RBS
  module Prototype
    class Runtime
      attr_reader :patterns
      attr_reader :env
      attr_reader :merge
      attr_reader :owners_included

      def initialize(patterns:, env:, merge:, owners_included: [])
        @patterns = patterns
        @decls = nil
        @env = env
        @merge = merge
        @owners_included = owners_included.map do |name|
          Object.const_get(name)
        end
      end

      def target?(const)
        name = const_name(const)

        patterns.any? do |pattern|
          if pattern.end_with?("*")
            (name || "").start_with?(pattern.chop)
          else
            name == pattern
          end
        end
      end

      def builder
        @builder ||= DefinitionBuilder.new(env: env)
      end

      def parse(file)
        require file
      end

      def decls
        unless @decls
          @decls = []
          ObjectSpace.each_object(Module).select {|mod| target?(mod) }.sort_by{|mod| const_name(mod) }.each do |mod|
            case mod
            when Class
              generate_class mod
            when Module
              generate_module mod
            end
          end
        end
        @decls
      end

      def to_type_name(name)
        *prefix, last = name.split(/::/)

        if prefix.empty?
          TypeName.new(name: last.to_sym, namespace: Namespace.empty)
        else
          TypeName.new(name: last.to_sym, namespace: Namespace.parse(prefix.join("::")))
        end
      end

      def each_included_module(type_name, mod)
        supers = Set[]

        mod.included_modules.each do |mix|
          supers.merge(mix.included_modules)
        end

        if mod.is_a?(Class)
          mod.superclass.included_modules.each do |mix|
            supers << mix
            supers.merge(mix.included_modules)
          end
        end

        mod.included_modules.each do |mix|
          unless supers.include?(mix)
            unless const_name(mix)
              RBS.logger.warn("Skipping anonymous module #{mix} included in #{mod}")
            else
              module_name = module_full_name = to_type_name(const_name(mix))
              if module_full_name.namespace == type_name.namespace
                module_name = TypeName.new(name: module_full_name.name, namespace: Namespace.empty)
              end

              yield module_name, module_full_name, mix
            end
          end
        end
      end

      def method_type(method)
        untyped = Types::Bases::Any.new(location: nil)

        required_positionals = []
        optional_positionals = []
        rest = nil
        trailing_positionals = []
        required_keywords = {}
        optional_keywords = {}
        rest_keywords = nil

        requireds = required_positionals

        block = nil

        method.parameters.each do |kind, name|
          case kind
          when :req
            requireds << Types::Function::Param.new(name: name, type: untyped)
          when :opt
            requireds = trailing_positionals
            optional_positionals << Types::Function::Param.new(name: name, type: untyped)
          when :rest
            requireds = trailing_positionals
            name = nil if name == :* # For `def f(...) end` syntax
            rest = Types::Function::Param.new(name: name, type: untyped)
          when :keyreq
            required_keywords[name] = Types::Function::Param.new(name: nil, type: untyped)
          when :key
            optional_keywords[name] = Types::Function::Param.new(name: nil, type: untyped)
          when :keyrest
            rest_keywords = Types::Function::Param.new(name: nil, type: untyped)
          when :block
            block = Types::Block.new(
              type: Types::Function.empty(untyped).update(rest_positionals: Types::Function::Param.new(name: nil, type: untyped)),
              required: true
            )
          end
        end

        return_type = if method.name == :initialize
                        Types::Bases::Void.new(location: nil)
                      else
                        untyped
                      end
        method_type = Types::Function.new(
          required_positionals: required_positionals,
          optional_positionals: optional_positionals,
          rest_positionals: rest,
          trailing_positionals: trailing_positionals,
          required_keywords: required_keywords,
          optional_keywords: optional_keywords,
          rest_keywords: rest_keywords,
          return_type: return_type,
        )

        MethodType.new(
          location: nil,
          type_params: [],
          type: method_type,
          block: block
        )
      end

      def merge_rbs(module_name, members, instance: nil, singleton: nil)
        if merge
          if env.class_decls[module_name.absolute!]
            case
            when instance
              method = builder.build_instance(module_name.absolute!).methods[instance]
              method_name = instance
              kind = :instance
            when singleton
              method = builder.build_singleton(module_name.absolute!).methods[singleton]
              method_name = singleton
              kind = :singleton
            end

            if method
              members << AST::Members::MethodDefinition.new(
                name: method_name,
                types: method.method_types.map {|type|
                  type.update.tap do |ty|
                    def ty.to_s
                      location.source
                    end
                  end
                },
                kind: kind,
                location: nil,
                comment: method.comments[0],
                annotations: method.annotations,
                overload: false
              )
              return
            end
          end

          yield
        else
          yield
        end
      end

      def target_method?(mod, instance: nil, singleton: nil)
        case
        when instance
          method = mod.instance_method(instance)
          method.owner == mod || owners_included.any? {|m| method.owner == m }
        when singleton
          method = mod.singleton_class.instance_method(singleton)
          method.owner == mod.singleton_class || owners_included.any? {|m| method.owner == m.singleton_class }
        end
      end

      def generate_methods(mod, module_name, members)
        mod.singleton_methods.select {|name| target_method?(mod, singleton: name) }.sort.each do |name|
          method = mod.singleton_class.instance_method(name)

          if method.name == method.original_name
            merge_rbs(module_name, members, singleton: name) do
              RBS.logger.info "missing #{module_name}.#{name} #{method.source_location}"

              members << AST::Members::MethodDefinition.new(
                name: method.name,
                types: [method_type(method)],
                kind: :singleton,
                location: nil,
                comment: nil,
                annotations: [],
                overload: false
              )
            end
          else
            members << AST::Members::Alias.new(
              new_name: method.name,
              old_name: method.original_name,
              kind: :singleton,
              location: nil,
              comment: nil,
              annotations: [],
              )
          end
        end

        public_instance_methods = mod.public_instance_methods.select {|name| target_method?(mod, instance: name) }
        unless public_instance_methods.empty?
          members << AST::Members::Public.new(location: nil)

          public_instance_methods.sort.each do |name|
            method = mod.instance_method(name)

            if method.name == method.original_name
              merge_rbs(module_name, members, instance: name) do
                RBS.logger.info "missing #{module_name}##{name} #{method.source_location}"

                members << AST::Members::MethodDefinition.new(
                  name: method.name,
                  types: [method_type(method)],
                  kind: :instance,
                  location: nil,
                  comment: nil,
                  annotations: [],
                  overload: false
                )
              end
            else
              members << AST::Members::Alias.new(
                new_name: method.name,
                old_name: method.original_name,
                kind: :instance,
                location: nil,
                comment: nil,
                annotations: [],
                )
            end
          end
        end

        private_instance_methods = mod.private_instance_methods.select {|name| target_method?(mod, instance: name) }
        unless private_instance_methods.empty?
          members << AST::Members::Private.new(location: nil)

          private_instance_methods.sort.each do |name|
            method = mod.instance_method(name)

            if method.name == method.original_name
              merge_rbs(module_name, members, instance: name) do
                RBS.logger.info "missing #{module_name}##{name} #{method.source_location}"

                members << AST::Members::MethodDefinition.new(
                  name: method.name,
                  types: [method_type(method)],
                  kind: :instance,
                  location: nil,
                  comment: nil,
                  annotations: [],
                  overload: false
                )
              end
            else
              members << AST::Members::Alias.new(
                new_name: method.name,
                old_name: method.original_name,
                kind: :instance,
                location: nil,
                comment: nil,
                annotations: [],
                )
            end
          end
        end
      end

      def generate_constants(mod)
        mod.constants(false).sort.each do |name|
          value = mod.const_get(name)

          next if value.is_a?(Class) || value.is_a?(Module)
          unless value.class.name
            RBS.logger.warn("Skipping constant #{name} #{value} of #{mod} as an instance of anonymous class")
            next
          end

          type = case value
                 when true, false
                   Types::Bases::Bool.new(location: nil)
                 when nil
                   Types::Optional.new(
                     type: Types::Bases::Any.new(location: nil),
                     location: nil
                   )
                 else
                   value_type_name = to_type_name(const_name(value.class))
                   args = type_args(value_type_name)
                   Types::ClassInstance.new(name: value_type_name, args: args, location: nil)
                 end

          @decls << AST::Declarations::Constant.new(
            name: "#{const_name(mod)}::#{name}",
            type: type,
            location: nil,
            comment: nil
          )
        end
      end

      def generate_class(mod)
        type_name = to_type_name(const_name(mod))
        super_class = if mod.superclass == ::Object
                        nil
                      elsif const_name(mod.superclass).nil?
                        RBS.logger.warn("Skipping anonymous superclass #{mod.superclass} of #{mod}")
                        nil
                      else
                        super_name = to_type_name(const_name(mod.superclass))
                        super_args = type_args(super_name)
                        AST::Declarations::Class::Super.new(name: super_name, args: super_args, location: nil)
                      end

        decl = AST::Declarations::Class.new(
          name: type_name,
          type_params: AST::Declarations::ModuleTypeParams.empty,
          super_class: super_class,
          members: [],
          annotations: [],
          location: nil,
          comment: nil
        )

        each_included_module(type_name, mod) do |module_name, module_full_name, _|
          args = type_args(module_full_name)
          decl.members << AST::Members::Include.new(
            name: module_name,
            args: args,
            location: nil,
            comment: nil,
            annotations: []
          )
        end

        each_included_module(type_name, mod.singleton_class) do |module_name, module_full_name ,_|
          args = type_args(module_full_name)
          decl.members << AST::Members::Extend.new(
            name: module_name,
            args: args,
            location: nil,
            comment: nil,
            annotations: []
          )
        end

        generate_methods(mod, type_name, decl.members)

        @decls << decl

        generate_constants mod
      end

      def generate_module(mod)
        name = const_name(mod)

        unless name
          RBS.logger.warn("Skipping anonymous module #{mod}")
          return
        end

        type_name = to_type_name(name)

        decl = AST::Declarations::Module.new(
          name: type_name,
          type_params: AST::Declarations::ModuleTypeParams.empty,
          self_types: [],
          members: [],
          annotations: [],
          location: nil,
          comment: nil
        )

        each_included_module(type_name, mod) do |module_name, module_full_name, _|
          args = type_args(module_full_name)
          decl.members << AST::Members::Include.new(
            name: module_name,
            args: args,
            location: nil,
            comment: nil,
            annotations: []
          )
        end

        each_included_module(type_name, mod.singleton_class) do |module_name, module_full_name, _|
          args = type_args(module_full_name)
          decl.members << AST::Members::Extend.new(
            name: module_name,
            args: args,
            location: nil,
            comment: nil,
            annotations: []
          )
        end

        generate_methods(mod, type_name, decl.members)

        @decls << decl

        generate_constants mod
      end

      def const_name(const)
        @module_name_method ||= Module.instance_method(:name)
        @module_name_method.bind(const).call
      end

      def type_args(type_name)
        if class_decl = env.class_decls[type_name.absolute!]
          class_decl.type_params.size.times.map { :untyped }
        else
          []
        end
      end
    end
  end
end
