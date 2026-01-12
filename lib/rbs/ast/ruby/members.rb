# frozen_string_literal: true

module RBS
  module AST
    module Ruby
      module Members
        class Base
          attr_reader :buffer

          def initialize(buffer)
            @buffer = buffer
          end

          include Helpers::LocationHelper
        end

        class MethodTypeAnnotation
          class DocStyle
            attr_accessor :return_type_annotation

            def initialize
              @return_type_annotation = nil
            end

            def map_type_name(&block)
              DocStyle.new.tap do |new|
                new.return_type_annotation = return_type_annotation&.map_type_name(&block)
              end #: self
            end

            def type_fingerprint
              return_type_annotation&.type_fingerprint
            end

            def method_type
              return_type =
                case return_type_annotation
                when Annotations::NodeTypeAssertion
                  return_type_annotation.type
                when Annotations::ReturnTypeAnnotation
                  return_type_annotation.return_type
                else
                  Types::Bases::Any.new(location: nil)
                end

              type = Types::Function.new(
                required_positionals: [],
                optional_positionals: [],
                rest_positionals: nil,
                trailing_positionals: [],
                required_keywords: {},
                optional_keywords: {},
                rest_keywords: nil,
                return_type: return_type
              )

              MethodType.new(
                type_params: [],
                type: type,
                block: nil,
                location: nil
              )
            end
          end

          attr_reader :type_annotations

          def initialize(type_annotations:)
            @type_annotations = type_annotations
          end

          def map_type_name(&block)
            case type_annotations
            when Array
              updated_annots = type_annotations.map do |annotation|
                annotation.map_type_name(&block)
              end
            when DocStyle
              updated_annots = type_annotations.map_type_name(&block)
            end

            MethodTypeAnnotation.new(type_annotations: updated_annots) #: self
          end

          def self.build(leading_block, trailing_block, variables)
            unused_annotations = [] #: Array[Annotations::leading_annotation | CommentBlock::AnnotationSyntaxError]
            unused_trailing_annotation = nil #: Annotations::trailing_annotation | CommentBlock::AnnotationSyntaxError | nil

            type_annotations = nil #: type_annotations

            if trailing_block
              case annotation = trailing_block.trailing_annotation(variables)
              when Annotations::NodeTypeAssertion
                type_annotations = DocStyle.new()
                type_annotations.return_type_annotation = annotation
              else
                unused_trailing_annotation = annotation
              end
            end

            if leading_block
              leading_block.each_paragraph(variables) do |paragraph|
                next if paragraph.is_a?(Location)

                if paragraph.is_a?(CommentBlock::AnnotationSyntaxError)
                  unused_annotations << paragraph
                  next
                end

                case paragraph
                when Annotations::MethodTypesAnnotation, Annotations::ColonMethodTypeAnnotation
                  type_annotations = [] unless type_annotations
                  if type_annotations.is_a?(Array)
                    type_annotations << paragraph
                    next
                  end
                when Annotations::ReturnTypeAnnotation
                  unless type_annotations
                    type_annotations = DocStyle.new()
                  end

                  if type_annotations.is_a?(DocStyle)
                    unless type_annotations.return_type_annotation
                      type_annotations.return_type_annotation = paragraph
                      next
                    end
                  end
                end

                unused_annotations << paragraph
              end
            end

            [
              MethodTypeAnnotation.new(
                type_annotations: type_annotations
              ),
              unused_annotations,
              unused_trailing_annotation
            ]
          end

          def empty?
            type_annotations.nil?
          end

          def overloads
            case type_annotations
            when DocStyle
              method_type = type_annotations.method_type

              [
                AST::Members::MethodDefinition::Overload.new(annotations: [], method_type: method_type)
              ]
            when Array
              type_annotations.flat_map do |annotation|
                case annotation
                when Annotations::ColonMethodTypeAnnotation
                  [
                    AST::Members::MethodDefinition::Overload.new(
                      annotations: annotation.annotations,
                      method_type: annotation.method_type
                    )
                  ]
                when Annotations::MethodTypesAnnotation
                  annotation.overloads
                end
              end
            when nil
              method_type = MethodType.new(
                type_params: [],
                type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                block: nil,
                location: nil
              )

              [
                AST::Members::MethodDefinition::Overload.new(method_type: method_type, annotations: [])
              ]
            end
          end

          def type_fingerprint
            case type_annotations
            when DocStyle
              type_annotations.type_fingerprint
            when Array
              type_annotations.map(&:type_fingerprint)
            when nil
              nil
            end
          end
        end

        class DefMember < Base
          Overload = AST::Members::MethodDefinition::Overload

          attr_reader :name
          attr_reader :node
          attr_reader :method_type
          attr_reader :leading_comment

          def initialize(buffer, name, node, method_type, leading_comment)
            super(buffer)
            @name = name
            @node = node
            @method_type = method_type
            @leading_comment = leading_comment
          end

          def location
            rbs_location(node.location)
          end

          def overloads
            method_type.overloads
          end

          def overloading?
            false
          end

          def annotations
            []
          end

          def name_location
            rbs_location(node.name_loc)
          end

          def type_fingerprint
            [
              "members/def",
              name.to_s,
              method_type.type_fingerprint,
              leading_comment&.as_comment&.string
            ]
          end
        end

        class MixinMember < Base
          attr_reader :node
          attr_reader :module_name
          attr_reader :annotation

          def initialize(buffer, node, module_name, annotation)
            super(buffer)
            @node = node
            @module_name = module_name
            @annotation = annotation
          end

          def location
            rbs_location(node.location)
          end

          def name_location
            args = node.arguments or raise
            first_arg = args.arguments.first or raise

            rbs_location(first_arg.location)
          end

          def type_args
            annotation&.type_args || []
          end

          def type_fingerprint
            [
              "members/mixin",
              self.class.name,
              module_name.to_s,
              annotation&.type_fingerprint
            ]
          end
        end

        class IncludeMember < MixinMember
        end

        class ExtendMember < MixinMember
        end

        class PrependMember < MixinMember
        end

        class AttributeMember < Base
          attr_reader :node
          attr_reader :name_nodes
          attr_reader :type_annotation
          attr_reader :leading_comment

          def initialize(buffer, node, name_nodes, leading_comment, type_annotation)
            super(buffer)
            @node = node
            @name_nodes = name_nodes
            @leading_comment = leading_comment
            @type_annotation = type_annotation
          end

          def names
            name_nodes.map do |node|
              node.unescaped.to_sym
            end
          end

          def location
            rbs_location(node.location)
          end

          def name_locations
            name_nodes.map do |name_node|
              rbs_location(name_node.location)
            end
          end

          def type
            type_annotation&.type
          end

          def type_fingerprint
            [
              "members/attribute",
              self.class.name,
              names.map(&:to_s),
              type_annotation&.type_fingerprint,
              leading_comment&.as_comment&.string
            ]
          end
        end

        class AttrReaderMember < AttributeMember
        end

        class AttrWriterMember < AttributeMember
        end

        class AttrAccessorMember < AttributeMember
        end

        class InstanceVariableMember < Base
          attr_reader :annotation

          def initialize(buffer, annotation)
            super(buffer)
            @annotation = annotation
          end

          def name
            annotation.ivar_name
          end

          def type
            annotation.type
          end

          def location
            annotation.location
          end

          def type_fingerprint
            [
              "members/instance_variable",
              annotation.type_fingerprint
            ]
          end
        end
      end
    end
  end
end
