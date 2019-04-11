module Ruby
  module Signature
    class Definition
      class Variable
        attr_reader :parent_variable
        attr_reader :type
        attr_reader :declaration

        def initialize(parent_variable:, type:, declaration:)
          @parent_variable = parent
          @type = type
          @declaration = declaration
        end
      end

      class Method
        attr_reader :super_method
        attr_reader :method_types
        attr_reader :defined_in
        attr_reader :implemented_in
        attr_reader :accessibility

        def initialize(super_method:, method_types:, defined_in:, implemented_in:, accessibility:)
          @super_method = super_method
          @method_types = method_types
          @defined_in = defined_in
          @implemented_in = implemented_in
          @accessibility = accessibility
        end

        def public?
          @accessibility == :public
        end

        def private?
          @accessibility == :private
        end

        def sub(s)
          self.class.new(
            super_method: super_method&.sub(s),
            method_types: method_types.map {|ty| ty.sub(s) },
            defined_in: defined_in,
            implemented_in: implemented_in,
            accessibility: @accessibility
          )
        end

        def map_type(&block)
          self.class.new(
            super_method: super_method&.map_type(&block),
            method_types: method_types.map do |ty|
              ty.map_type &block
            end,
            defined_in: defined_in,
            implemented_in: implemented_in,
            accessibility: @accessibility
          )
        end
      end

      module Ancestor
        Instance = Struct.new(:name, :args, keyword_init: true)
        Singleton = Struct.new(:name, keyword_init: true)
      end

      attr_reader :declaration
      attr_reader :self_type
      attr_reader :methods
      attr_reader :instance_variables
      attr_reader :class_variables
      attr_reader :ancestors

      def initialize(declaration:, self_type:, ancestors:)
        unless declaration.is_a?(AST::Declarations::Class) || declaration.is_a?(AST::Declarations::Module) || declaration.is_a?(AST::Declarations::Interface)
          raise "Declaration should be a class, module, or interface: #{declaration.name}"
        end

        unless (self_type.is_a?(Types::ClassSingleton) || self_type.is_a?(Types::Interface) || self_type.is_a?(Types::ClassInstance)) && self_type.name == declaration.name.absolute!
          raise "self_type should be the type of declaration: #{self_type}"
        end

        @self_type = self_type
        @declaration = declaration
        @methods = {}
        @instance_variables = {}
        @class_variables = {}
        @ancestors = ancestors
      end

      def name
        declaration.name
      end

      def class?
        declaration.is_a?(AST::Declarations::Class)
      end

      def module?
        declaration.is_a?(AST::Declarations::Module)
      end

      def class_type?
        @self_type.is_a?(Types::ClassSingleton)
      end

      def instance_type?
        @self_type.is_a?(Types::ClassInstance)
      end

      def interface_type?
        @self_type.is_a?(Types::Interface)
      end

      def type_params
        @self_type.args.map(&:name)
      end
    end
  end
end
