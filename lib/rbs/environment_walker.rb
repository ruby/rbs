module RBS
  class EnvironmentWalker
    attr_reader :env

    def initialize(env:)
      @env = env
      @only_ancestors = nil
    end

    def builder
      @builder ||= DefinitionBuilder.new(env: env)
    end

    def only_ancestors!(only = true)
      @only_ancestors = only
      self
    end

    def only_ancestors?
      @only_ancestors
    end

    include TSort

    def tsort_each_node(&block)
      env.class_decls.each_key(&block)
      env.interface_decls.each_key(&block)
      env.alias_decls.each_key(&block)
    end

    def tsort_each_child(name, &block)
      unless name.namespace.empty?
        yield name.namespace.to_type_name
      end

      case
      when name.class?, name.interface?
        definitions = []

        case
        when name.class?
          definitions << builder.build_instance(name)
          definitions << builder.build_singleton(name)
        when name.interface?
          definitions << builder.build_interface(name)
        end

        definitions.each do |definition|
          if ancestors = definition.ancestors
            ancestors.ancestors.each do |ancestor|
              yield ancestor.name

              case ancestor
              when Definition::Ancestor::Instance
                ancestor.args.each do |type|
                  each_type_name type, &block
                end
              end
            end
          end

          unless only_ancestors?
            definition.each_type do |type|
              each_type_name type, &block
            end
          end
        end
      when name.alias?
        each_type_name builder.expand_alias(name), &block
      end
    end

    def each_type_name(type, &block)
      case type
      when RBS::Types::Bases::Any
      when RBS::Types::Bases::Class
      when RBS::Types::Bases::Instance
      when RBS::Types::Bases::Self
      when RBS::Types::Bases::Top
      when RBS::Types::Bases::Bottom
      when RBS::Types::Bases::Bool
      when RBS::Types::Bases::Void
      when RBS::Types::Bases::Nil
      when RBS::Types::Variable
      when RBS::Types::ClassSingleton
        yield type.name
      when RBS::Types::ClassInstance, RBS::Types::Interface
        yield type.name
        type.args.each do |ty|
          each_type_name(ty, &block)
        end
      when RBS::Types::Alias
        yield type.name
      when RBS::Types::Union, RBS::Types::Intersection, RBS::Types::Tuple
        type.types.each do |ty|
          each_type_name ty, &block
        end
      when RBS::Types::Optional
        each_type_name type.type, &block
      when RBS::Types::Literal
        # nop
      when RBS::Types::Record
        type.fields.each_value do |ty|
          each_type_name ty, &block
        end
      when RBS::Types::Proc
        type.each_type do |ty|
          each_type_name ty, &block
        end
      else
        raise "Unexpected type given: #{type}"
      end
    end
  end
end
