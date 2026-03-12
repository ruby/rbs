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
            attr_reader :required_positionals
            attr_reader :optional_positionals
            attr_accessor :rest_positionals
            attr_reader :trailing_positionals
            attr_reader :required_keywords
            attr_reader :optional_keywords
            attr_accessor :rest_keywords

            def initialize
              @return_type_annotation = nil
              @required_positionals = [] #: Array[Annotations::ParamTypeAnnotation?]
              @optional_positionals = [] #: Array[Annotations::ParamTypeAnnotation?]
              @rest_positionals = nil #: Annotations::ParamTypeAnnotation?
              @trailing_positionals = [] #: Array[Annotations::ParamTypeAnnotation?]
              @required_keywords = {} #: Hash[Symbol, Annotations::ParamTypeAnnotation]
              @optional_keywords = {} #: Hash[Symbol, Annotations::ParamTypeAnnotation]
              @rest_keywords = nil #: Annotations::ParamTypeAnnotation?
            end

            def self.build(param_type_annotations, return_type_annotation, node)
              doc = DocStyle.new
              doc.return_type_annotation = return_type_annotation

              unused = param_type_annotations.dup

              if node.parameters
                params = node.parameters #: Prism::ParametersNode

                params.requireds.each do |param|
                  if param.is_a?(Prism::RequiredParameterNode)
                    annotation = unused.find { _1.name_location.source.to_sym == param.name }
                    if annotation
                      unused.delete(annotation)
                      doc.required_positionals << annotation
                    else
                      doc.required_positionals << param.name
                    end
                  end
                end

                params.optionals.each do |param|
                  if param.is_a?(Prism::OptionalParameterNode)
                    annotation = unused.find { _1.name_location.source.to_sym == param.name }
                    if annotation
                      unused.delete(annotation)
                      doc.optional_positionals << annotation
                    else
                      doc.optional_positionals << param.name
                    end
                  end
                end

                if (rest = params.rest) && rest.is_a?(Prism::RestParameterNode) && rest.name
                  annotation = unused.find { _1.name_location.source.to_sym == rest.name }
                  if annotation
                    unused.delete(annotation)
                    doc.rest_positionals = annotation
                  else
                    doc.rest_positionals = rest.name
                  end
                end

                params.posts.each do |param|
                  if param.is_a?(Prism::RequiredParameterNode)
                    annotation = unused.find { _1.name_location.source.to_sym == param.name }
                    if annotation
                      unused.delete(annotation)
                      doc.trailing_positionals << annotation
                    else
                      doc.trailing_positionals << param.name
                    end
                  end
                end

                params.keywords.each do |param|
                  case param
                  when Prism::RequiredKeywordParameterNode
                    annotation = unused.find { _1.name_location.source.to_sym == param.name }
                    if annotation
                      unused.delete(annotation)
                      doc.required_keywords[param.name] = annotation
                    else
                      doc.required_keywords[param.name] = param.name
                    end
                  when Prism::OptionalKeywordParameterNode
                    annotation = unused.find { _1.name_location.source.to_sym == param.name }
                    if annotation
                      unused.delete(annotation)
                      doc.optional_keywords[param.name] = annotation
                    else
                      doc.optional_keywords[param.name] = param.name
                    end
                  end
                end

                if (kw_rest = params.keyword_rest) && kw_rest.is_a?(Prism::KeywordRestParameterNode) && kw_rest.name
                  annotation = unused.find { _1.name_location.source.to_sym == kw_rest.name }
                  if annotation
                    unused.delete(annotation)
                    doc.rest_keywords = annotation
                  else
                    doc.rest_keywords = kw_rest.name
                  end
                end
              end

              [doc, unused]
            end

            def all_param_annotations
              annotations = [] #: Array[param_type_annotation | Symbol | nil]
              #
              required_positionals.each { |a| annotations << a }
              optional_positionals.each { |a| annotations << a }
              annotations << rest_positionals
              trailing_positionals.each { |a| annotations << a }
              required_keywords.each_value { |a| annotations << a }
              optional_keywords.each_value { |a| annotations << a }
              annotations << rest_keywords

              annotations
            end

            def map_type_name(&block)
              DocStyle.new.tap do |new|
                new.return_type_annotation = return_type_annotation&.map_type_name(&block)
                new.required_positionals.replace(
                  required_positionals.map do |a|
                    case a
                    when Annotations::ParamTypeAnnotation
                      a.map_type_name(&block)
                    else
                      a
                    end
                  end
                )
                new.optional_positionals.replace(
                  optional_positionals.map do |a|
                    case a
                    when Annotations::ParamTypeAnnotation
                      a.map_type_name(&block)
                    else
                      a
                    end
                  end
                )
                new.rest_positionals =
                  case rest_positionals
                  when Annotations::ParamTypeAnnotation
                    rest_positionals.map_type_name(&block)
                  else
                    rest_positionals
                  end
                new.trailing_positionals.replace(
                  trailing_positionals.map do |a|
                    case a
                    when Annotations::ParamTypeAnnotation
                      a.map_type_name(&block)
                    else
                      a
                    end
                  end
                )
                new.required_keywords.replace(
                  required_keywords.transform_values do |a|
                    case a
                    when Annotations::ParamTypeAnnotation
                      a.map_type_name(&block)
                    else
                      a
                    end
                  end
                )
                new.optional_keywords.replace(
                  optional_keywords.transform_values do |a|
                    case a
                    when Annotations::ParamTypeAnnotation
                      a.map_type_name(&block)
                    else
                      a
                    end
                  end
                )
                new.rest_keywords =
                  case rest_keywords
                  when Annotations::ParamTypeAnnotation
                    rest_keywords.map_type_name(&block)
                  else
                    rest_keywords
                  end
              end #: self
            end

            def type_fingerprint
              [
                return_type_annotation&.type_fingerprint,
                all_param_annotations.map do |param|
                  case param
                  when Annotations::ParamTypeAnnotation
                    param.type_fingerprint
                  else
                    param
                  end
                end
              ]
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

              any = -> { Types::Bases::Any.new(location: nil) }

              req_pos = required_positionals.map do |a|
                case a
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: a.param_type, name: a.name_location.source.to_sym)
                else
                  Types::Function::Param.new(type: any.call, name: a)
                end
              end
              opt_pos = optional_positionals.map do |a|
                case a
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: a.param_type, name: a.name_location.source.to_sym)
                else
                  Types::Function::Param.new(type: any.call, name: a)
                end
              end
              rest_pos =
                case rest_positionals
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: rest_positionals.param_type, name: rest_positionals.name_location.source.to_sym)
                when Symbol
                  Types::Function::Param.new(type: any.call, name: rest_positionals)
                else
                  nil
                end
              trail_pos = trailing_positionals.map do |a|
                case a
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: a.param_type, name: a.name_location.source.to_sym)
                else
                  Types::Function::Param.new(type: any.call, name: a)
                end
              end

              req_kw = required_keywords.transform_values do |a|
                case a
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: a.param_type, name: nil)
                else
                  Types::Function::Param.new(type: any.call, name: nil)
                end
              end
              opt_kw = optional_keywords.transform_values do |a|
                case a
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: a.param_type, name: nil)
                else
                  Types::Function::Param.new(type: any.call, name: nil)
                end
              end

              rest_kw =
                case rest_keywords
                when Annotations::ParamTypeAnnotation
                  Types::Function::Param.new(type: rest_keywords.param_type, name: nil)
                when Symbol
                  Types::Function::Param.new(type: any.call, name: nil)
                else
                  nil
                end

              type = Types::Function.new(
                required_positionals: req_pos,
                optional_positionals: opt_pos,
                rest_positionals: rest_pos,
                trailing_positionals: trail_pos,
                required_keywords: req_kw,
                optional_keywords: opt_kw,
                rest_keywords: rest_kw,
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

          def self.build(leading_block, trailing_block, variables, node)
            unused_annotations = [] #: Array[Annotations::leading_annotation | CommentBlock::AnnotationSyntaxError]
            unused_trailing_annotation = nil #: Annotations::trailing_annotation | CommentBlock::AnnotationSyntaxError | nil

            type_annotations = nil #: type_annotations
            return_annotation = nil #: Annotations::ReturnTypeAnnotation | Annotations::NodeTypeAssertion | nil
            param_annotations = [] #: Array[Annotations::ParamTypeAnnotation]

            if trailing_block
              case annotation = trailing_block.trailing_annotation(variables)
              when Annotations::NodeTypeAssertion
                return_annotation = annotation
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
                    unless return_annotation
                      return_annotation = paragraph
                      next
                    end
                  end
                when Annotations::ParamTypeAnnotation
                  unless type_annotations
                    param_annotations << paragraph
                    next
                  end
                end

                unused_annotations << paragraph
              end
            end

            if !type_annotations && (return_annotation || !param_annotations.empty?)
              doc_style, unused_params = DocStyle.build(param_annotations, return_annotation, node)
              type_annotations = doc_style
              unused_annotations.concat(unused_params)
            end

            [
              MethodTypeAnnotation.new(type_annotations: type_annotations),
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

          def overloading?
            case type_annotations
            when Array
              type_annotations.any? do |annotation|
                annotation.is_a?(Annotations::MethodTypesAnnotation) && annotation.dot3_location
              end
            else
              false
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
            method_type.overloading?
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
