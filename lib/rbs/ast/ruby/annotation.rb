module RBS
  module AST
    module Ruby
      module Annotation
        class Base
          attr_reader :location, :prefix_location

          def initialize(location, prefix_location)
            @location = location
            @prefix_location = prefix_location
          end
        end

        class NodeTypeAssertion < Base
          attr_reader :type

          def initialize(location:, prefix_location:, type:)
            super(location, prefix_location)
            @type = type
          end
        end

        class NodeApplication < Base
          attr_reader :types, :suffix_location

          def initialize(location:, prefix_location:, types:, suffix_location:)
            super(location, prefix_location)
            @types = types
            @suffix_location = suffix_location
          end
        end

        class SkipAnnotation < Base
          attr_reader :comment, :skip_location

          def initialize(location:, comment:, prefix_location:, skip_location:)
            super(location, prefix_location)
            @comment = comment
            @skip_location = skip_location
          end
        end

        class ColonMethodTypeAnnotation < Base
          attr_reader :annotations, :method_type

          def initialize(location:, prefix_location:, annotations:, method_type:)
            super(location, prefix_location)
            @annotations = annotations
            @method_type = method_type
          end
        end

        class MethodTypesAnnotation < Base
          class Overload
            attr_reader :annotations, :method_type

            def initialize(annotations:, method_type:)
              @annotations = annotations
              @method_type = method_type
            end
          end

          attr_reader :overloads, :vertical_bar_locations

          def initialize(location:, prefix_location:, overloads:, vertical_bar_locations:)
            super(location, prefix_location)
            @overloads = overloads
            @vertical_bar_locations = vertical_bar_locations
          end
        end

        class ReturnTypeAnnotation < Base
          attr_reader :return_type, :colon_location, :return_location, :comment

          def initialize(location:, prefix_location:, colon_location:, return_type:, return_location:, comment:)
            super(location, prefix_location)
            @colon_location = colon_location
            @return_type = return_type
            @return_location = return_location
            @comment = comment
          end
        end

        class ParamTypeAnnotation < Base
          attr_reader :param_name_location, :colon_location, :type, :comment

          def initialize(location:, prefix_location:, param_name_location:, colon_location:, type:, comment:)
            super(location, prefix_location)
            @param_name_location = param_name_location
            @colon_location = colon_location
            @type = type
            @comment = comment
          end
        end

        class SplatParamTypeAnnotation < Base
          attr_reader :operator_location, :param_name_location, :colon_location, :type, :comment

          def initialize(location:, prefix_location:, operator_location:, param_name_location:, colon_location:, type:, comment:)
            super(location, prefix_location)
            @operator_location = operator_location
            @param_name_location = param_name_location
            @colon_location = colon_location
            @type = type
            @comment = comment
          end
        end

        class DoubleSplatParamTypeAnnotation < Base
          attr_reader :operator_location, :param_name_location, :colon_location, :type, :comment

          def initialize(location:, prefix_location:, operator_location:, param_name_location:, colon_location:, type:, comment:)
            super(location, prefix_location)
            @operator_location = operator_location
            @param_name_location = param_name_location
            @colon_location = colon_location
            @type = type
            @comment = comment
          end
        end

        class BlockParamTypeAnnotation < Base
          attr_reader :operator_location, :param_name_location, :colon_location, :question_mark_location, :block, :comment

          def initialize(location:, prefix_location:, operator_location:, param_name_location:, colon_location:, question_mark_location:, block:, comment:)
            super(location, prefix_location)
            @operator_location = operator_location
            @param_name_location = param_name_location
            @colon_location = colon_location
            @question_mark_location = question_mark_location
            @block = block
            @comment = comment
          end
        end

        class OverrideAnnotation < Base
          attr_reader :override_location

          def initialize(location:, prefix_location:, override_location:)
            super(location, prefix_location)
            @override_location = override_location
          end
        end

        class GenericAnnotation < Base
          attr_reader :generic_location, :unchecked_location, :variance_location, :name_location, :upper_bound_operator_location
          attr_reader :upper_bound, :default_type_operator_location, :default_type, :comment

          def initialize(location:, prefix_location:, generic_location:, unchecked_location:, variance_location:, name_location:, upper_bound_operator_location:, upper_bound:, default_type_operator_location:, default_type:, comment:)
            super(location, prefix_location)
            @generic_location = generic_location
            @unchecked_location = unchecked_location
            @variance_location = variance_location
            @name_location = name_location
            @upper_bound_operator_location = upper_bound_operator_location
            @upper_bound = upper_bound
            @default_type_operator_location = default_type_operator_location
            @default_type = default_type
            @comment = comment
          end

          def unchecked?
            unchecked_location ? true : false
          end

          def variance
            if variance_location
              case variance_location.source
              when "in"
                :contravariant
              when "out"
                :covariant
              else
                raise
              end
            else
              :invariant
            end
          end

          def upper_bound_location
            if (op = upper_bound_operator_location) && (bound = upper_bound&.location)
              Location.new(op.buffer, op.start_pos, bound.end_pos)
            end
          end

          def default_type_location
            if (op = default_type_operator_location) && (default = default_type&.location)
              Location.new(op.buffer, op.start_pos, default.end_pos)
            end
          end
        end

        class RBSAnnotationAnnotation < Base
          attr_reader :annotations

          def initialize(location:, prefix_location:, annotations:)
            super(location, prefix_location)
            @annotations = annotations
          end
        end
      end
    end
  end
end
