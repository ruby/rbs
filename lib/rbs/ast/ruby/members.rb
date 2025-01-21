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

        class DefMember < Base
          attr_reader :node

          def initialize(node)
            @node = node
          end

          def name
            node.name
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

          def annotations
            []
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
        end

        class MixinMember < Base
          attr_reader :node

          attr_reader :location
          attr_reader :module_name
          attr_reader :module_name_location
          attr_reader :open_paren_location
          attr_reader :close_paren_location
          attr_reader :type_args
          attr_reader :args_separator_locations

          def initialize(buffer, node, location:, module_name:, type_args:, module_name_location:, open_paren_location:, close_paren_location:, args_separator_locations:)
            super(buffer)
            @node = node
            @location = location
            @module_name = module_name
            @type_args = type_args
            @module_name_location = module_name_location
            @open_paren_location = open_paren_location
            @close_paren_location = close_paren_location
            @args_separator_locations = args_separator_locations
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
              args_separator_locations: args_separator_locations
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
