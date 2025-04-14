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
        end

        class DefMember < Base
          Overload = AST::Members::MethodDefinition::Overload

          attr_reader :name
          attr_reader :node

          def initialize(buffer, name, node)
            super(buffer)
            @name = name
            @node = node
          end

          def location
            rbs_location(node.location)
          end

          def overloads
            method_type = MethodType.new(
              type_params: [],
              type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
              block: nil,
              location: nil
            )

            [
              Overload.new(method_type: method_type, annotations: [])
            ]
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
