module RBS
  module AST
    module Ruby
      module Members
        class Base
          attr_reader :buffer

          def initialize(buffer)
            @buffer = buffer
          end

          include Helpers::ConstantHelper
        end

        class Overload
          attr_reader :method_type
          attr_reader :annotations

          def initialize(method_type, annotations)
            @method_type = method_type
            @annotations = annotations
          end
        end

        class DefAnnotations
          class DocStyleTypeAnnotations
            attr_reader :return_type_annotation
            attr_reader :param_type_annotations
            attr_reader :splat_type_annotation
            attr_reader :kwsplat_type_annotation
            attr_reader :block_type_annotation

            def initialize(return_type_annotation:, param_type_annotations:, splat_type_annotation:, kwsplat_type_annotation:, block_type_annotation:)
              @return_type_annotation = return_type_annotation
              @param_type_annotations = param_type_annotations
              @splat_type_annotation = splat_type_annotation
              @kwsplat_type_annotation = kwsplat_type_annotation
              @block_type_annotation = block_type_annotation
            end

            def self.empty
              new(
                return_type_annotation: nil,
                param_type_annotations: {},
                splat_type_annotation: nil,
                kwsplat_type_annotation: nil,
                block_type_annotation: nil
              )
            end

            def map_type_name(&block)
              DocStyleTypeAnnotations.new(
                return_type_annotation: return_type_annotation&.map_type_name(&block),
                param_type_annotations: param_type_annotations.transform_values { _1.map_type_name(&block) },
                splat_type_annotation: splat_type_annotation&.map_type_name(&block),
                kwsplat_type_annotation: kwsplat_type_annotation&.map_type_name(&block),
                block_type_annotation: block_type_annotation&.map_type_name(&block)
              ) #: self
            end

            def update!(return_type_annotation: self.return_type_annotation, splat_type_annotation: self.splat_type_annotation, kwsplat_type_annotation: self.kwsplat_type_annotation, block_type_annotation: self.block_type_annotation)
              @return_type_annotation = return_type_annotation
              @splat_type_annotation = splat_type_annotation
              @kwsplat_type_annotation = kwsplat_type_annotation
              @block_type_annotation = block_type_annotation
            end

            def construct_method_type(parameters)
              any_type = Types::Bases::Any.new(location: nil)

              required_positionals = [] #: Array[Types::Function::Param]
              optional_positionals = [] #: Array[Types::Function::Param]
              rest_positionals = nil #: Types::Function::Param?
              required_keywords = {} #: Hash[Symbol, Types::Function::Param]
              optional_keywords = {} #: Hash[Symbol, Types::Function::Param]
              rest_keywords = nil #: Types::Function::Param?

              if parameters
                parameters.requireds.each do |param|
                  case param
                  when Prism::RequiredParameterNode
                    type = param_type_annotations[param.name]&.type || any_type
                    required_positionals << Types::Function::Param.new(type: type, name: param.name, location: nil)
                  else
                    required_positionals << Types::Function::Param.new(type: any_type, name: nil, location: nil)
                  end
                end
                parameters.optionals.each do |param|
                  type = param_type_annotations[param.name]&.type || any_type
                  optional_positionals << Types::Function::Param.new(type: type, name: param.name, location: nil)
                end
                if (rest = parameters.rest).is_a?(Prism::RestParameterNode)
                  rest_positionals = Types::Function::Param.new(
                    type: splat_type_annotation&.type || any_type,
                    name: rest.name,
                    location: nil
                  )
                end
                parameters.keywords.each do |node|
                  if node.is_a?(Prism::RequiredKeywordParameterNode)
                    type = param_type_annotations[node.name]&.type || any_type
                    required_keywords[node.name] = Types::Function::Param.new(type: type, name: nil, location: nil)
                  end

                  if node.is_a?(Prism::OptionalKeywordParameterNode)
                    type = param_type_annotations[node.name]&.type || any_type
                    optional_keywords[node.name] = Types::Function::Param.new(type: type, name: nil, location: nil)
                  end
                end
                if (rest = parameters.keyword_rest).is_a?(Prism::KeywordRestParameterNode)
                  rest_keywords = Types::Function::Param.new(
                    type: kwsplat_type_annotation&.type || any_type,
                    name: rest.name,
                    location: nil
                  )
                end
                if parameters.block
                  block = Types::Block.new(
                    type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                    required: false,
                    self_type: nil
                  )
                end
              end

              if blk = block_type_annotation
                block = blk.block
              end

              return_type =
                case return_type_annotation
                when Annotation::ReturnTypeAnnotation
                  return_type_annotation.return_type
                when Annotation::NodeTypeAssertion
                  return_type_annotation.type
                else
                  any_type
                end

              MethodType.new(
                type_params: [],
                type: Types::Function.new(
                  required_positionals: required_positionals,
                  optional_positionals: optional_positionals,
                  rest_positionals: rest_positionals,
                  trailing_positionals: [],
                  required_keywords: required_keywords,
                  optional_keywords: optional_keywords,
                  rest_keywords: rest_keywords,
                  return_type: return_type
                ),
                block: block,
                location: nil
              )
            end
          end

          attr_reader :type_annotations, :annotations, :override

          def initialize(type_annotations:, annotations:, override:)
            @type_annotations = type_annotations
            @annotations = annotations
            @override = override
          end

          def map_type_name(&block)
            type =
              case type_annotations
              when DocStyleTypeAnnotations
                type_annotations.map_type_name(&block)
              when Array
                type_annotations.map do |annotation|
                  annotation.map_type_name(&block)
                end
              when Annotation::MethodTypesAnnotation
                type_annotations.map_type_name(&block)
              end
            DefAnnotations.new(
              type_annotations: type,
              annotations: annotations,
              override: override
            ) #: self
          end

          def self.build(leading_block, trailing_block, variables)
            unused_annotations = [] #: Array[Annotation::leading_annotation | CommentBlock::AnnotationSyntaxError]
            unused_trailing_annotation = nil #: Annotation::trailing_annotation | CommentBlock::AnnotationSyntaxError | nil

            override = nil #: Annotation::OverrideAnnotation?
            annotations = [] #: Array[Annotation::RBSAnnotationAnnotation]
            type_annotations = nil #: type_annotations

            if trailing_block
              case annotation = trailing_block.trailing_annotation(variables)
              when Annotation::NodeTypeAssertion
                type_annotations = DocStyleTypeAnnotations.empty.tap do
                  _1.update!(return_type_annotation: annotation)
                end
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
                when Annotation::RBSAnnotationAnnotation
                  annotations << paragraph
                  next
                when Annotation::OverrideAnnotation
                  override = paragraph
                  next
                when Annotation::MethodTypesAnnotation, Annotation::ColonMethodTypeAnnotation
                  type_annotations = [] unless type_annotations
                  if type_annotations.is_a?(Array)
                    type_annotations << paragraph
                    next
                  end
                when Annotation::ParamTypeAnnotation
                  type_annotations = DocStyleTypeAnnotations.empty unless type_annotations
                  if type_annotations.is_a?(DocStyleTypeAnnotations)
                    unless type_annotations.param_type_annotations.key?(paragraph.param_name)
                      type_annotations.param_type_annotations[paragraph.param_name] = paragraph
                      next
                    end
                  end
                when Annotation::SplatParamTypeAnnotation
                  type_annotations = DocStyleTypeAnnotations.empty unless type_annotations
                  if type_annotations.is_a?(DocStyleTypeAnnotations)
                    unless type_annotations.splat_type_annotation
                      type_annotations.update!(splat_type_annotation: paragraph)
                      next
                    end
                  end
                when Annotation::DoubleSplatParamTypeAnnotation
                  type_annotations = DocStyleTypeAnnotations.empty unless type_annotations
                  if type_annotations.is_a?(DocStyleTypeAnnotations)
                    type_annotations.update!(kwsplat_type_annotation: paragraph)
                    next
                  end
                when Annotation::BlockParamTypeAnnotation
                  type_annotations = DocStyleTypeAnnotations.empty unless type_annotations
                  if type_annotations.is_a?(DocStyleTypeAnnotations)
                    type_annotations.update!(block_type_annotation: paragraph)
                    next
                  end
                when Annotation::ReturnTypeAnnotation
                  type_annotations = DocStyleTypeAnnotations.empty unless type_annotations
                  if type_annotations.is_a?(DocStyleTypeAnnotations)
                    unless type_annotations.return_type_annotation
                      type_annotations.update!(return_type_annotation: paragraph)
                      next
                    end
                  end
                end

                unused_annotations << paragraph
              end
            end

            [
              DefAnnotations.new(
                type_annotations: type_annotations,
                annotations: annotations,
                override: override
              ),
              unused_annotations,
              unused_trailing_annotation
            ]
          end
        end

        class DefMember < Base
          attr_reader :node, :inline_annotations, :name

          def initialize(node, name:, inline_annotations:)
            @node = node
            @inline_annotations = inline_annotations
            @name = name
          end

          def overloads
            case inline_annotations.type_annotations
            when DefAnnotations::DocStyleTypeAnnotations, nil
              annots = inline_annotations.type_annotations || DefAnnotations::DocStyleTypeAnnotations.empty
              method_type = annots.construct_method_type(node.parameters)
              [
                Overload.new(method_type, [])
              ]
            when Array
              inline_annotations.type_annotations.flat_map do |annotation|
                case annotation
                when Annotation::ColonMethodTypeAnnotation
                  [Overload.new(annotation.method_type.update(location: nil), annotation.annotations)]
                when Annotation::MethodTypesAnnotation
                  annotation.overloads.map do
                    Overload.new(_1.method_type.update(location: nil), _1.annotations)
                  end
                end
              end
            end
          end

          def override?
            inline_annotations.override ? true : false
          end

          def annotations
            inline_annotations.annotations.flat_map do |annotation|
              annotation.annotations
            end
          end

          def map_type_name(&block)
            DefMember.new(
              node,
              name: name,
              inline_annotations: inline_annotations.map_type_name(&block)
            ) #: self
          end

          def location
            buffer.rbs_location(node.location)
          end

          def name_location
            buffer.rbs_location(node.name_loc)
          end
        end

        class DefSingletonMember < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def overloads
            [
              Overload.new(
                MethodType.new(
                  type_params: [],
                  type: Types::UntypedFunction.new(return_type: Types::Bases::Any.new(location: nil)),
                  block: nil,
                  location: nil
                ),
                []
              )
            ]
          end

          def name
            node.name
          end

          def self?
            node.receiver.is_a?(Prism::SelfNode)
          end

          def annotations
            []
          end

          def location
            buffer.rbs_location(node.location)
          end
        end

        class MixinMember < Base
          attr_reader :node

          attr_reader :location
          attr_reader :module_name
          attr_reader :module_name_location
          attr_reader :open_paren_location
          attr_reader :close_paren_location
          attr_reader :type_args

          def initialize(buffer, node, location:, module_name:, type_args:, module_name_location:, open_paren_location:, close_paren_location:)
            super(buffer)
            @node = node
            @location = location
            @module_name = module_name
            @type_args = type_args
            @module_name_location = module_name_location
            @open_paren_location = open_paren_location
            @close_paren_location = close_paren_location
          end

          def map_type_name(&block)
            self.class.new(
              buffer,
              node,
              location: location,
              module_name: yield(module_name),
              type_args: type_args.map {|type| type.map_type_name { yield(_1) } },
              module_name_location: module_name_location,
              open_paren_location: open_paren_location,
              close_paren_location: close_paren_location,
            ) #: self
          end
        end

        class IncludeMember < MixinMember
        end

        class ExtendMember < MixinMember
        end

        class PrependMember < MixinMember
        end

        class VisibilityMember < Base
          attr_reader :node

          def initialize(buffer, node)
            super(buffer)
            @node = node
          end

          def location
            buffer.rbs_location(node.location)
          end
        end

        class PublicMember < VisibilityMember
        end

        class PrivateMember < VisibilityMember
        end
      end
    end
  end
end
