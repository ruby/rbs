# frozen_string_literal: true

module RBS
  class CLI
    class Validate
      class Errors
        def initialize(limit:)
          @limit = limit
          @errors = []
        end

        def add(error)
          @errors << error
          finish if @limit == 1
        end

        def finish
          unless @errors.empty?
            @errors.each do |error|
              RBS.logger.error(build_message(error))
            end
            exit 1
          end
        end

        private

        def build_message(error)
          if error.respond_to?(:detailed_message)
            highlight = RBS.logger_output ? RBS.logger_output.tty? : true
            error.detailed_message(highlight: highlight)
          else
            "#{error.message} (#{error.class})"
          end
        end
      end

      def initialize(args:, options:)
        loader = options.loader()
        @env = Environment.from_loader(loader).resolve_type_names
        @builder = DefinitionBuilder.new(env: @env)
        @validator = Validator.new(env: @env)
        limit = nil #: Integer?
        OptionParser.new do |opts|
          opts.banner = <<EOU
Usage: rbs validate

Validate RBS files. It ensures the type names in RBS files are present and the type applications have correct arity.

Examples:

  $ rbs validate
EOU

          opts.on("--silent", "This option has been deprecated and does nothing.") do
            RBS.print_warning { "`--silent` option is deprecated because it's silent by default. You can use --log-level option of rbs command to display more information." }
          end
          opts.on("--[no-]exit-error-on-syntax-error", "exit(1) if syntax error is detected") {|bool|
            RBS.print_warning { "`--[no-]exit-error-on-syntax-error` option is deprecated because it's built in during parsing." }
          }
          opts.on("--fail-fast", "Exit immediately as soon as a validation error is found.") do |arg|
            limit = 1
          end
        end.parse!(args)

        @errors = Errors.new(limit: limit)
      end

      def run
        validate_class_module_definition
        validate_class_module_alias_definition
        validate_interface
        validate_constant
        validate_global
        validate_type_alias

        @errors.finish
      end

      private

      def validate_class_module_definition
        @env.class_decls.each do |name, entry|
          RBS.logger.info "Validating class/module definition: `#{name}`..."
          @builder.build_instance(name).each_type do |type|
            @validator.validate_type type, context: nil
          rescue BaseError => error
            @errors.add(error)
          end
          @builder.build_singleton(name).each_type do |type|
            @validator.validate_type type, context: nil
          rescue BaseError => error
            @errors.add(error)
          end

          case entry
          when Environment::ClassEntry
            entry.each_decl do |decl|
              if super_class = decl.super_class
                super_class.args.each do |arg|
                  @validator.validate_type(arg, context: nil)
                end
              end
            end
          when Environment::ModuleEntry
            entry.each_decl do |decl|
              decl.self_types.each do |self_type|
                self_type.args.each do |arg|
                  @validator.validate_type(arg, context: nil)
                end

                self_params =
                  if self_type.name.class?
                    @env.normalized_module_entry(self_type.name)&.type_params
                  else
                    @env.interface_decls[self_type.name]&.decl&.type_params
                  end

                if self_params
                  InvalidTypeApplicationError.check!(type_name: self_type.name, params: self_params, args: self_type.args, location: self_type.location)
                end
              end
            end
          end

          d = entry.primary_decl

          @validator.validate_type_params(
            d.type_params,
            type_name: name,
            location: d.location&.aref(:type_params)
          )

          d.type_params.each do |param|
            if ub = param.upper_bound_type
              @validator.validate_type(ub, context: nil)
            end

            if lb = param.lower_bound_type
              void_type_context_validator(lb)
              no_self_type_validator(lb)
              no_classish_type_validator(lb)
              @validator.validate_type(lb, context: nil)
            end

            if dt = param.default_type
              @validator.validate_type(dt, context: nil)
            end
          end

          TypeParamDefaultReferenceError.check!(d.type_params)

          entry.each_decl do |decl|
            case decl
            when AST::Declarations::Base
              decl.each_member do |member|
                case member
                when AST::Members::MethodDefinition
                  @validator.validate_method_definition(member, type_name: name)
                when AST::Members::Mixin
                  params =
                    if member.name.class?
                      module_decl = @env.normalized_module_entry(member.name) or raise
                      module_decl.type_params
                    else
                      interface_decl = @env.interface_decls.fetch(member.name)
                      interface_decl.decl.type_params
                    end
                  InvalidTypeApplicationError.check!(type_name: member.name, params: params, args: member.args, location: member.location)
                when AST::Members::Var
                  @validator.validate_variable(member)
                end
              end
            else
              raise "Unknown declaration: #{decl.class}"
            end
          end
        rescue BaseError => error
          @errors.add(error)
        end
      end

      def validate_class_module_alias_definition
        @env.class_alias_decls.each do |name, entry|
          RBS.logger.info "Validating class/module alias definition: `#{name}`..."
          @validator.validate_class_alias(entry: entry)
        rescue BaseError => error
          @errors.add error
        end
      end

      def validate_interface
        @env.interface_decls.each do |name, decl|
          RBS.logger.info "Validating interface: `#{name}`..."
          @builder.build_interface(name).each_type do |type|
            @validator.validate_type type, context: nil
          end

          @validator.validate_type_params(
            decl.decl.type_params,
            type_name: name,
            location: decl.decl.location&.aref(:type_params)
          )

          decl.decl.type_params.each do |param|
            if ub = param.upper_bound_type
              @validator.validate_type(ub, context: nil)
            end

            if lb = param.lower_bound_type
              void_type_context_validator(lb)
              no_self_type_validator(lb)
              no_classish_type_validator(lb)
              @validator.validate_type(lb, context: nil)
            end

            if dt = param.default_type
              @validator.validate_type(dt, context: nil)
            end
          end

          TypeParamDefaultReferenceError.check!(decl.decl.type_params)

          decl.decl.members.each do |member|
            case member
            when AST::Members::MethodDefinition
              @validator.validate_method_definition(member, type_name: name)
            end
          end
        rescue BaseError => error
          @errors.add(error)
        end
      end

      def validate_constant
        @env.constant_decls.each do |name, const|
          RBS.logger.info "Validating constant: `#{name}`..."
          @validator.validate_type const.decl.type, context: const.context
          @builder.ensure_namespace!(name.namespace, location: const.decl.location)
        rescue BaseError => error
          @errors.add(error)
        end
      end

      def validate_global
        @env.global_decls.each do |name, global|
          RBS.logger.info "Validating global: `#{name}`..."
          @validator.validate_type global.decl.type, context: nil
        rescue BaseError => error
          @errors.add(error)
        end
      end

      def validate_type_alias
        @env.type_alias_decls.each do |name, decl|
          RBS.logger.info "Validating alias: `#{name}`..."
          @builder.expand_alias1(name).tap do |type|
            @validator.validate_type type, context: nil
          end

          @validator.validate_type_alias(entry: decl)

          @validator.validate_type_params(
            decl.decl.type_params,
            type_name: name,
            location: decl.decl.location&.aref(:type_params)
          )

          decl.decl.type_params.each do |param|
            if ub = param.upper_bound_type
              @validator.validate_type(ub, context: nil)
            end

            if lb = param.lower_bound_type
              void_type_context_validator(lb)
              no_self_type_validator(lb)
              no_classish_type_validator(lb)
              @validator.validate_type(lb, context: nil)
            end

            if dt = param.default_type
              @validator.validate_type(dt, context: nil)
            end
          end

          TypeParamDefaultReferenceError.check!(decl.decl.type_params)
        rescue BaseError => error
          @errors.add(error)
        end
      end
    end
  end
end
