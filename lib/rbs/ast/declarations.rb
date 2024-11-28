# frozen_string_literal: true

module RBS
  module AST
    module Declarations
      class Base
      end

      module NestedDeclarationHelper
        def each_member
          if block_given?
            members.each do |member|
              if member.is_a?(Members::Base)
                yield(_ = member)
              end
            end
          else
            enum_for :each_member
          end
        end

        def each_decl
          if block_given?
            members.each do |member|
              if member.is_a?(Base)
                yield(_ = member)
              end
            end
          else
            enum_for :each_decl
          end
        end
      end

      module MixinHelper
        def each_mixin(&block)
          if block
            @mixins ||= begin
                          _ = members.select do |member|
                            case member
                            when Members::Include, Members::Extend, Members::Prepend
                              true
                            else
                              false
                            end
                          end
                        end
            @mixins.each(&block)
          else
            enum_for :each_mixin
          end
        end
      end

      class Class < Base
        class Super
          attr_reader :name
          attr_reader :args
          attr_reader :location

          def initialize(name:, args:, location:)
            @name = name
            @args = args
            @location = location
          end

          def ==(other)
            other.is_a?(Super) && other.name == name && other.args == args
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ args.hash
          end

          def to_json(state = _ = nil)
            {
              name: name,
              args: args,
              location: location
            }.to_json(state)
          end

          def self.new(name: , args:, location:)
            if name.data?
              superclass = super(name: name, args: [], location: location)

              return DataDecl.new(superclass, args: args, location: location)
            end

            if name.struct?
              superclass = super(name: name, args: [], location: location)

              return StructDecl.new(superclass, args: args, location: location)
            end

            super
          end
        end

        include NestedDeclarationHelper
        include MixinHelper

        attr_reader :name
        attr_reader :type_params
        attr_reader :members
        attr_reader :super_class
        attr_reader :annotations
        attr_reader :location
        attr_reader :comment

        def initialize(name:, type_params:, super_class:, members:, annotations:, location:, comment:)
          @name = name
          @type_params = type_params
          @super_class = super_class
          @members = members
          @annotations = annotations
          @location = location
          @comment = comment
        end

        def update(name: self.name, type_params: self.type_params, super_class: self.super_class, members: self.members, annotations: self.annotations, location: self.location, comment: self.comment)
          self.class.new(
            name: name,
            type_params: type_params,
            super_class: super_class,
            members: members,
            annotations: annotations,
            location: location,
            comment: comment
          )
        end

        def ==(other)
          other.is_a?(Class) &&
            other.name == name &&
            other.type_params == type_params &&
            other.super_class == super_class &&
            other.members == members
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ type_params.hash ^ super_class.hash ^ members.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :class,
            name: name,
            type_params: type_params,
            members: members,
            super_class: super_class,
            annotations: annotations,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class Module < Base
        class Self
          attr_reader :name
          attr_reader :args
          attr_reader :location

          def initialize(name:, args:, location:)
            @name = name
            @args = args
            @location = location
          end

          def ==(other)
            other.is_a?(Self) && other.name == name && other.args == args
          end

          alias eql? ==

          def hash
            self.class.hash ^ name.hash ^ args.hash ^ location.hash
          end

          def to_json(state = _ = nil)
            {
              name: name,
              args: args,
              location: location
            }.to_json(state)
          end

          def to_s
            if args.empty?
              name.to_s
            else
              "#{name}[#{args.join(", ")}]"
            end
          end
        end

        include NestedDeclarationHelper
        include MixinHelper

        attr_reader :name
        attr_reader :type_params
        attr_reader :members
        attr_reader :location
        attr_reader :annotations
        attr_reader :self_types
        attr_reader :comment

        def initialize(name:, type_params:, members:, self_types:, annotations:, location:, comment:)
          @name = name
          @type_params = type_params
          @self_types = self_types
          @members = members
          @annotations = annotations
          @location = location
          @comment = comment
        end

        def update(name: self.name, type_params: self.type_params, members: self.members, self_types: self.self_types, annotations: self.annotations, location: self.location, comment: self.comment)
          self.class.new(
            name: name,
            type_params: type_params,
            members: members,
            self_types: self_types,
            annotations: annotations,
            location: location,
            comment: comment
          )
        end


        def ==(other)
          other.is_a?(Module) &&
            other.name == name &&
            other.type_params == type_params &&
            other.self_types == self_types &&
            other.members == members
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ type_params.hash ^ self_types.hash ^ members.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :module,
            name: name,
            type_params: type_params,
            members: members,
            self_types: self_types,
            annotations: annotations,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class Interface < Base
        attr_reader :name
        attr_reader :type_params
        attr_reader :members
        attr_reader :annotations
        attr_reader :location
        attr_reader :comment

        include MixinHelper

        def initialize(name:, type_params:, members:, annotations:, location:, comment:)
          @name = name
          @type_params = type_params
          @members = members
          @annotations = annotations
          @location = location
          @comment = comment
        end

        def update(name: self.name, type_params: self.type_params, members: self.members, annotations: self.annotations, location: self.location, comment: self.comment)
          self.class.new(
            name: name,
            type_params: type_params,
            members: members,
            annotations: annotations,
            location: location,
            comment: comment
          )
        end

        def ==(other)
          other.is_a?(Interface) &&
            other.name == name &&
            other.type_params == type_params &&
            other.members == members
        end

        alias eql? ==

        def hash
          self.class.hash ^ type_params.hash ^ members.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :interface,
            name: name,
            type_params: type_params,
            members: members,
            annotations: annotations,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class TypeAlias < Base
        attr_reader :name
        attr_reader :type_params
        attr_reader :type
        attr_reader :annotations
        attr_reader :location
        attr_reader :comment

        def initialize(name:, type_params:, type:, annotations:, location:, comment:)
          @name = name
          @type_params = type_params
          @type = type
          @annotations = annotations
          @location = location
          @comment = comment
        end

        def ==(other)
          other.is_a?(TypeAlias) &&
            other.name == name &&
            other.type_params == type_params &&
            other.type == type
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ type_params.hash ^ type.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :alias,
            name: name,
            type_params: type_params,
            type: type,
            annotations: annotations,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class Constant < Base
        attr_reader :name
        attr_reader :type
        attr_reader :location
        attr_reader :comment

        def initialize(name:, type:, location:, comment:)
          @name = name
          @type = type
          @location = location
          @comment = comment
        end

        def ==(other)
          other.is_a?(Constant) &&
            other.name == name &&
            other.type == type
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ type.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :constant,
            name: name,
            type: type,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class Global < Base
        attr_reader :name
        attr_reader :type
        attr_reader :location
        attr_reader :comment

        def initialize(name:, type:, location:, comment:)
          @name = name
          @type = type
          @location = location
          @comment = comment
        end

        def ==(other)
          other.is_a?(Global) &&
            other.name == name &&
            other.type == type
        end

        alias eql? ==

        def hash
          self.class.hash ^ name.hash ^ type.hash
        end

        def to_json(state = _ = nil)
          {
            declaration: :global,
            name: name,
            type: type,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class AliasDecl < Base
        attr_reader :new_name, :old_name, :location, :comment

        def initialize(new_name:, old_name:, location:, comment:)
          @new_name = new_name
          @old_name = old_name
          @location = location
          @comment = comment
        end

        def ==(other)
          other.is_a?(self.class) &&
            other.new_name == new_name &&
            other.old_name == old_name
        end

        alias eql? ==

        def hash
          self.class.hash ^ new_name.hash ^ old_name.hash
        end
      end

      class ClassAlias < AliasDecl
        def to_json(state = _ = nil)
          {
            declaration: :class_alias,
            new_name: new_name,
            old_name: old_name,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class ModuleAlias < AliasDecl
        def to_json(state = _ = nil)
          {
            declaration: :module_alias,
            new_name: new_name,
            old_name: old_name,
            location: location,
            comment: comment
          }.to_json(state)
        end
      end

      class DataDecl < Class
        attr_reader :args

        def initialize(superklass, args: , location:)
          if args.is_a?(Hash)
            args = args.map do |k, (type, required)|
              type = (required.nil? || required) ? type : Types::Optional.new(type: type, location: type.location)
              Types::Function::Param.new(name: k, type: type, location: type.location)
            end
          end

          # attribute readers
          members = args.map do |param|
            Members::AttrReader.new(
              name: param.name,
              type: param.type,
              ivar_name: :"@#{param.name}",
              kind: :instance,
              location: location,
              comment: nil,
              annotations: []
            )
          end

          # initialize
          members << Members::MethodDefinition.new(
            name: :initialize,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: args.to_h { |param|
                      [
                        param.name,
                        # set param
                        Types::Function::Param.new(
                          name: nil,
                          type: param.type,
                          location: location
                        )
                      ]
                    },
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Void.new(location: location),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_positionals: args.map { |param|
                      # set param
                      Types::Function::Param.new(
                        name: param.name,
                        type: param.type,
                        location: location
                      )
                    },
                    required_keywords: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Void.new(location: location),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # members
          members << Members::MethodDefinition.new(
            name: :members,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Array,
                      args: [Types::ClassInstance.new(name: BuiltinNames::Symbol, args: [], location: location)],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # deconstruct
          members << Members::MethodDefinition.new(
            name: :deconstruct,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Tuple.new(
                      types: args.map do |param|
                        Types::ClassInstance.new(name: param.type, args: [], location: location)
                      end,
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # deconstruct_keys
          members << Members::MethodDefinition.new(
            name: :deconstruct_keys,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [
                      Types::Function::Param.new(
                        name: nil,
                        type: Types::Bases::Nil.new(location: location),
                        location: location
                      )
                    ],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Record.new(
                      all_fields: args.to_h do |param|
                        [
                          param.name,
                          [
                            Types::ClassInstance.new(name: param.type, args: [], location: location),
                            true
                          ]
                        ]
                      end,
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [
                      Types::Function::Param.new(
                        name: :names,
                        type: Types::ClassInstance.new(
                          name: BuiltinNames::Array,
                          location: location,
                          args: [
                            Types::ClassInstance.new(
                              name: BuiltinNames::Symbol,
                              args: [],
                              location: location
                            )
                          ]
                        ),
                        location: location
                      )
                    ],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Hash,
                      location: location,
                      args: [
                        Types::ClassInstance.new(
                          name: BuiltinNames::Symbol,
                          args: [],
                          location: location
                        ),
                        Types::ClassInstance.new(
                          name: Types::Bases::Any.new(location: location),
                          args: [],
                          location: location
                        )
                      ]
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # with
          members << Members::MethodDefinition.new(
            name: :with,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: args.to_h do |param|
                        [
                          param.name,
                          Types::Function::Param.new(
                            name: nil,
                            type: Types::ClassInstance.new(
                              name: param.type,
                              args: [],
                              location: location
                            ),
                            location: location
                          )
                        ]
                    end,
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # .[]
          members << Members::MethodDefinition.new(
            name: :[],
            kind: :singleton,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: args.map do |param|
                        Types::Function::Param.new(
                          name: param.name,
                          type: Types::ClassInstance.new(
                            name: param.type,
                            args: [],
                            location: location
                          ),
                          location: location
                        )
                      end,
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    optional_keywords: {},
                    required_positionals: [],
                    required_keywords: args.to_h do |param|
                        [
                          param.name,
                          Types::Function::Param.new(
                            name: nil,
                            type: Types::ClassInstance.new(
                              name: param.type,
                              args: [],
                              location: location
                            ),
                            location: location
                          )
                        ]
                    end,
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # .members
          members << Members::MethodDefinition.new(
            name: :members,
            kind: :singleton,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Array,
                      args: [Types::ClassInstance.new(name: BuiltinNames::Symbol, args: [], location: location)],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          @args = args

          super(
            name: superklass.name,
            type_params: nil,
            super_class: superklass,
            annotations: nil,
            comment: nil,
            location: location,
            members: members
          )
        end
      end

      class StructDecl < Class
        attr_reader :args

        def initialize(superklass, args: , location:)
          if args.is_a?(Hash)
            args = args.map do |k, (type, required)|
              type = (required.nil? || required) ? type : Types::Optional.new(type: type, location: type.location)
              Types::Function::Param.new(name: k, type: type, location: type.location)
            end
          end

          # attribute accessors
          members = args.map do |param|
            Members::AttrAccessor.new(
              name: param.name,
              type: Types::Optional.new(type: param.type, location: param.type.location),
              ivar_name: :"@#{param.name}",
              kind: :instance,
              location: location,
              comment: nil,
              annotations: []
            )
          end

          # initialize
          members << Members::MethodDefinition.new(
            name: :initialize,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: args.to_h { |param|
                      [
                        param.name,
                        # set param
                        Types::Function::Param.new(
                          name: nil,
                          type: param.type,
                          location: location
                        )
                      ]
                    },
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Void.new(location: location),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_positionals: [],
                    required_keywords: [],
                    optional_keywords: {},
                    optional_positionals: args.map { |param|
                      # set param
                      Types::Function::Param.new(
                        name: param.name,
                        type: param.type,
                        location: location
                      )
                    },
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Void.new(location: location),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # []
          members << Members::MethodDefinition.new(
            name: :[],
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: args.map do |param|
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_positionals: [
                      Types::Function::Param.new(
                        name: :key,
                        type: Types::Union.new(
                          types: [
                            Types::Literal.new(literal: param.name, location: location),
                            Types::Literal.new(literal: param.name.to_s, location: location),
                          ],
                          location: location
                        ),
                        location: location
                      )
                    ],
                    required_keywords: {},
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Optional.new(
                      type: Types::ClassInstance.new(name: param.type, args: [], location: location),
                      location: location
                    )
                  ),
                  location: location,
                  block: nil
                ),
                annotations: []
              )
            end
          )

          # []=
          members << Members::MethodDefinition.new(
            name: :[]=,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: args.map do |param|
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_positionals: [
                      Types::Function::Param.new(
                        name: :key,
                        type: Types::Union.new(
                          types: [
                            Types::Literal.new(literal: param.name, location: location),
                            Types::Literal.new(literal: param.name.to_s, location: location),
                          ],
                          location: location
                        ),
                        location: location
                      ),
                      Types::Function::Param.new(
                        name: :value,
                        type: param.type,
                        location: location
                      )
                    ],
                    required_keywords: {},
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(name: param.type, args: [], location: location)
                  ),
                  location: location,
                  block: nil
                ),
                annotations: []
              )
            end
          )

          # size
          members << Members::MethodDefinition.new(
            name: :size,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Integer,
                      args: [],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # to_a
          members << Members::MethodDefinition.new(
            name: :to_a,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Tuple.new(
                      types: args.map do |param|
                        Types::Optional.new(
                          type: Types::ClassInstance.new(name: param.type, args: [], location: location),
                          location: location
                        )
                      end,
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # dig
          members << Members::MethodDefinition.new(
            name: :dig,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_positionals: [
                      Types::Function::Param.new(
                        name: :key,
                        type: Types::Union.new(
                          types: args.flat_map do |param|
                            [
                              Types::Literal.new(literal: param.name, location: location),
                              Types::Literal.new(literal: param.name.to_s, location: location)
                            ]
                          end,
                          location: location
                        ),
                        location: location
                      )
                    ],
                    required_keywords: {},
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: Types::Function::Param.new(
                      name: nil,
                      location: location,
                      type:  Types::Bases::Any.new(location: location)
                    ),
                    trailing_positionals: [],
                    return_type: Types::Bases::Any.new(location: location)
                  ),
                  location: location,
                  block: nil
                ),
                annotations: []
              )
            ]
          )

          # members
          members << Members::MethodDefinition.new(
            name: :members,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Array,
                      args: [Types::ClassInstance.new(name: BuiltinNames::Symbol, args: [], location: location)],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # values_at
          members << Members::MethodDefinition.new(
            name: :values_at,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: Types::Function::Param.new(
                      name: :keys,
                      location: location,
                      type: Types::Union.new(
                        location: location,
                        types: [
                          Types::ClassInstance.new(args: [], location: location, name: BuiltinNames::Symbol),
                          Types::ClassInstance.new(args: [], location: location, name: BuiltinNames::String)
                        ]
                      )
                    ),
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Array,
                      args: [Types::Bases::Any.new(location: location)],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # deconstruct
          members << Members::MethodDefinition.new(
            name: :deconstruct,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Tuple.new(
                      types: args.map do |param|
                        Types::Optional.new(
                          type: Types::ClassInstance.new(name: param.type, args: [], location: location),
                          location: location
                        )
                      end,
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # deconstruct_keys
          members << Members::MethodDefinition.new(
            name: :deconstruct_keys,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [
                      Types::Function::Param.new(
                        name: nil,
                        type: Types::Bases::Nil.new(location: location),
                        location: location
                      )
                    ],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Record.new(
                      all_fields: args.to_h do |param|
                        [
                          param.name,
                          [
                            Types::Optional.new(
                              type: Types::ClassInstance.new(name: param.type, args: [], location: location),
                              location: location
                            ),
                            true
                          ]
                        ]
                      end,
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [
                      Types::Function::Param.new(
                        name: :names,
                        type: Types::ClassInstance.new(
                          name: BuiltinNames::Array,
                          location: location,
                          args: [
                            Types::ClassInstance.new(
                              name: BuiltinNames::Symbol,
                              args: [],
                              location: location
                            )
                          ]
                        ),
                        location: location
                      )
                    ],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Hash,
                      location: location,
                      args: [
                        Types::ClassInstance.new(
                          name: BuiltinNames::Symbol,
                          args: [],
                          location: location
                        ),
                        Types::ClassInstance.new(
                          name: Types::Bases::Any.new(location: location),
                          args: [],
                          location: location
                        )
                      ]
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # with
          members << Members::MethodDefinition.new(
            name: :with,
            kind: :instance,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: args.to_h do |param|
                        [
                          param.name,
                          Types::Function::Param.new(
                            name: nil,
                            type: Types::ClassInstance.new(
                              name: param.type,
                              args: [],
                              location: location
                            ),
                            location: location
                          )
                        ]
                    end,
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # .[]
          members << Members::MethodDefinition.new(
            name: :[],
            kind: :singleton,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: args.map do |param|
                      Types::Function::Param.new(
                        name: param.name,
                        type: Types::ClassInstance.new(
                          name: param.type,
                          args: [],
                          location: location
                        ),
                        location: location
                      )
                    end,
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              ),
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    optional_keywords: args.to_h do |param|
                      [
                        param.name,
                        Types::Function::Param.new(
                          name: nil,
                          type: Types::ClassInstance.new(
                            name: param.type,
                            args: [],
                            location: location
                          ),
                          location: location
                        )
                      ]
                    end,
                    required_positionals: [],
                    required_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Bases::Instance.new(
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # .members
          members << Members::MethodDefinition.new(
            name: :members,
            kind: :singleton,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::ClassInstance.new(
                      name: BuiltinNames::Array,
                      args: [Types::ClassInstance.new(name: BuiltinNames::Symbol, args: [], location: location)],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          # .keyword_init?
          members << Members::MethodDefinition.new(
            name: :keyword_init?,
            kind: :singleton,
            location: location,
            overloading: false,
            comment: nil,
            annotations: nil,
            visibility: nil,
            overloads: [
              Members::MethodDefinition::Overload.new(
                method_type: MethodType.new(
                  type_params: [],
                  type: Types::Function.new(
                    required_keywords: {},
                    required_positionals: [],
                    optional_keywords: {},
                    optional_positionals: [],
                    rest_keywords: nil,
                    rest_positionals: nil,
                    trailing_positionals: [],
                    return_type: Types::Alias.new(
                      name: TypeName.new(name: :boolish, namespace: Namespace.root),
                      args: [],
                      location: location
                    ),
                  ),
                  location: location,
                  block: nil,
                ),
                annotations: []
              )
            ]
          )

          @args = args

          super(
            name: superklass.name,
            type_params: nil,
            super_class: superklass,
            annotations: nil,
            comment: nil,
            location: location,
            members: members
          )
        end
      end
    end
  end
end
