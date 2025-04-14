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
            when Annotations::NodeTypeAssertion
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
                type_annotations = annotation
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
            when Annotations::NodeTypeAssertion
              method_type = MethodType.new(
                type_params: [],
                type: Types::Function.empty(type_annotations.type),
                block: nil,
                location: nil
              )

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
        end

        class DefMember < Base
          Overload = AST::Members::MethodDefinition::Overload

          attr_reader :name
          attr_reader :node
          attr_reader :method_type

          def initialize(buffer, name, node, method_type)
            super(buffer)
            @name = name
            @node = node
            @method_type = method_type
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
        end
      end
    end
  end
end
