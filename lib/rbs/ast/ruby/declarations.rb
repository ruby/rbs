module RBS
  module AST
    module Ruby
      module Declarations
        class Base
          attr_reader :buffer

          def constant_as_type_name(node)
            case node
            when Prism::ConstantPathNode, Prism::ConstantReadNode
              TypeName.parse(node.full_name)
            end
          end

          def rbs_location(location)
            Location.new(buffer, location.start_character_offset, location.end_character_offset)
          end

          def initialize(buffer)
            @buffer = buffer
          end
        end

        class GenericsTypeParams
          attr_reader :annotations

          def initialize(annotations)
            @annotations = annotations
          end

          def param_names
            type_params.map(&:name)
          end

          def type_params
            @type_params ||= annotations.map do |type_param|
              TypeParam.new(
                name: type_param.name,
                variance: type_param.variance,
                upper_bound: type_param.upper_bound,
                default_type: type_param.default_type,
                location: nil
              )
            end
          end

          def map_type_name(&block)
            self.class.new(
              annotations.map { |annotation| annotation.map_type_name { yield(_1) } }
            ) #: self
          end

          def self.build(annotations)
            generic_annotations, other_annotations = annotations.partition do |annotation|
              annotation.is_a?(Annotation::GenericAnnotation)
            end #: [Array[Annotation::GenericAnnotation], Array[Annotation::leading_annotation]]

            [new(generic_annotations), other_annotations]
          end
        end

        class ClassDecl < Base
          class SuperNode
            attr_reader :class_name
            attr_reader :type_args
            attr_reader :location
            attr_reader :class_name_location
            attr_reader :open_paren_location
            attr_reader :close_paren_location

            def initialize(class_name:, type_args:, location:, class_name_location:, open_paren_location:, close_paren_location:)
              @class_name = class_name
              @type_args = type_args
              @location = location
              @class_name_location = class_name_location
              @open_paren_location = open_paren_location
              @close_paren_location = close_paren_location
            end

            def map_type_name(&block)
              self.class.new(
                class_name: yield(class_name),
                type_args: type_args.map {|type| type.map_type_name { yield(_1) } },
                location: location,
                class_name_location: class_name_location,
                open_paren_location: open_paren_location,
                close_paren_location: close_paren_location
              ) #: self
            end

            alias name class_name

            alias args type_args
          end

          class SuperAnnotation
            attr_reader :class_name
            attr_reader :type_args
            attr_reader :annotation

            def initialize(class_name, type_args, annotation)
              @class_name = class_name
              @type_args = type_args
              @annotation = annotation
            end

            def map_type_name(&block)
              self.class.new(
                yield(class_name),
                type_args.map {|type| type.map_type_name { yield(_1) } },
                annotation
              ) #: self
            end

            alias name class_name

            alias args type_args

            def self.build(annotations)
              super_annotation = nil #: Annotation::InheritsAnnotation?
              other_annotations = [] #: Array[Annotation::leading_annotation]

              annotations.each do |annotation|
                if !super_annotation && annotation.is_a?(Annotation::InheritsAnnotation)
                  super_annotation = annotation
                else
                  other_annotations << annotation
                end
              end

              [
                if super_annotation
                  SuperAnnotation.new(
                    super_annotation.type_name,
                    super_annotation.type_args,
                    super_annotation
                  ) #: instance
                end,
                other_annotations
              ]
            end
          end

          attr_reader :node
          attr_reader :location
          attr_reader :class_name
          attr_reader :class_name_location
          attr_reader :generics
          attr_reader :members
          attr_reader :super_node
          attr_reader :super_annotation

          def initialize(buffer, node, location:, class_name:, class_name_location:, generics:, super_node:, super_annotation:)
            super(buffer)
            @node = node
            @location = location
            @class_name = class_name
            @class_name_location = class_name_location
            @generics = generics
            @super_node = super_node
            @super_annotation = super_annotation
            @members = []
          end

          alias name class_name

          def super_class
            super_annotation || super_node
          end

          def each_member(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Members::Base)
              end
            else
              enum_for :each_member
            end
          end

          def type_params
            generics&.type_params || []
          end

          def each_decl(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Base)
              end
            else
              enum_for :each_decl
            end
          end
        end

        class SingletonClassDecl < Base
          attr_reader :node
          attr_reader :members

          def initialize(buffer, node)
            super(buffer)
            @node = node
            @members = []
          end

          def location
            rbs_location(node.location)
          end
        end

        class ModuleDecl < Base
          class SelfConstraint
            attr_reader :name
            attr_reader :args
            attr_reader :annotation

            def initialize(name, args, annotation)
              @name = name
              @args = args
              @annotation = annotation
            end

            def map_type_name
              SelfConstraint.new(
                yield(name),
                args.map { |type| type.map_type_name { yield(_1) } },
                annotation
              ) #: self
            end

            def self.build(annotations)
              self_annotations = [] #: Array[Annotation::ModuleSelfAnnotation]
              other_annotations = [] #: Array[Annotation::leading_annotation]

              annotations.each do |annotation|
                if annotation.is_a?(Annotation::ModuleSelfAnnotation)
                  self_annotations << annotation
                else
                  other_annotations << annotation
                end
              end

              [
                self_annotations.map { new(_1.type_name, _1.type_args, _1) },
                other_annotations
              ]
            end

            def location
              annotation.location + annotation.close_paren_location
            end
          end

          attr_reader :node
          attr_reader :location
          attr_reader :module_name
          attr_reader :module_name_location
          attr_reader :generics
          attr_reader :members
          attr_reader :self_constraints

          def initialize(buffer, node, location:, module_name:, module_name_location:, generics:, self_constraints:)
            super(buffer)
            @node = node
            @location = location
            @module_name = module_name
            @module_name_location = module_name_location
            @generics = generics
            @self_constraints = self_constraints
            @members = []
          end

          alias name module_name

          def type_params
            generics.type_params
          end

          def self_types
            self_constraints
          end

          def each_member(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Members::Base)
              end
            else
              enum_for :each_member
            end
          end

          def each_decl(&block)
            if block
              members.each do |member|
                yield member if member.is_a?(Base)
              end
            else
              enum_for :each_decl
            end
          end
        end

        class ConstantDecl < Base
          attr_reader :node

          def initialize(buffer, node)
            super(buffer)
            @node = node
          end

          def type
            Types::Bases::Any.new(location: nil)
          end
        end
      end
    end
  end
end
