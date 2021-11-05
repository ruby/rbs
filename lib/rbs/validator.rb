module RBS
  class Validator
    attr_reader :env
    attr_reader :resolver
    attr_reader :definition_builder

    def initialize(env:, resolver:)
      @env = env
      @resolver = resolver
      @definition_builder = DefinitionBuilder.new(env: env)
    end

    def absolute_type(type, context:)
      type.map_type_name do |type_name, _, type|
        resolver.resolve(type_name, context: context) || yield(type)
      end
    end

    # Validates presence of the relative type, and application arity match.
    def validate_type(type, context:)
      case type
      when Types::ClassInstance, Types::Interface, Types::Alias
        # @type var type: Types::ClassInstance | Types::Interface | Types::Alias
        if type.name.namespace.relative?
          type = _ = absolute_type(type, context: context) do |_|
            NoTypeFoundError.check!(type.name.absolute!, env: env, location: type.location)
          end
        end

        type_params = case type
                      when Types::ClassInstance
                        env.class_decls[type.name]&.type_params
                      when Types::Interface
                        env.interface_decls[type.name]&.decl&.type_params
                      when Types::Alias
                        env.alias_decls[type.name]&.decl&.type_params
                      end

        unless type_params
          raise NoTypeFoundError.new(type_name: type.name, location: type.location)
        end

        InvalidTypeApplicationError.check!(
          type_name: type.name,
          args: type.args,
          params: type_params.each.map(&:name),
          location: type.location
        )

      when Types::ClassSingleton
        # @type var type: Types::ClassSingleton
        type = _ = absolute_type(type, context: context) { type.name.absolute! }
        NoTypeFoundError.check!(type.name, env: env, location: type.location)
      end

      type.each_type do |type|
        validate_type(type, context: context)
      end
    end

    def validate_type_alias(entry:)
      type_name = entry.decl.name

      if type_alias_dependency.circular_definition?(type_name)
        location = entry.decl.location or raise
        raise RecursiveTypeAliasError.new(alias_names: [type_name], location: location)
      end

      if diagnostic = type_alias_regularity.nonregular?(type_name)
        location = entry.decl.location or raise
        raise NonregularTypeAliasError.new(diagnostic: diagnostic, location: location)
      end

      unless entry.decl.type_params.empty?
        calculator = VarianceCalculator.new(builder: definition_builder)
        result = calculator.in_type_alias(name: type_name)
        if set = result.incompatible?(entry.decl.type_params)
          set.each do |param_name|
            param = entry.decl.type_params[param_name] or raise
            raise InvalidVarianceAnnotationError.new(
              type_name: type_name,
              param: param,
              location: entry.decl.type.location
            )
          end
        end
      end
    end

    def type_alias_dependency
      @type_alias_dependency ||= TypeAliasDependency.new(env: env)
    end

    def type_alias_regularity
      @type_alias_regularity ||= TypeAliasRegularity.validate(env: env)
    end
  end
end
