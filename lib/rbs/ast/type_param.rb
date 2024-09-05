# frozen_string_literal: true

module RBS
  module AST
    class TypeParam
      attr_reader :name, :variance, :location, :upper_bound_type

      def initialize(name:, variance:, upper_bound:, location:)
        @name = name
        @variance = variance
        @upper_bound_type = upper_bound
        @location = location
        @unchecked = false
      end

      def upper_bound
        case upper_bound_type
        when Types::ClassInstance, Types::ClassSingleton, Types::Interface
          upper_bound_type
        end
      end

      def unchecked!(value = true)
        @unchecked = value ? true : false
        self
      end

      def unchecked?
        @unchecked
      end

      def ==(other)
        other.is_a?(TypeParam) &&
          other.name == name &&
          other.variance == variance &&
          other.upper_bound_type == upper_bound_type &&
          other.unchecked? == unchecked?
      end

      alias eql? ==

      def hash
        self.class.hash ^ name.hash ^ variance.hash ^ upper_bound_type.hash ^ unchecked?.hash
      end

      def to_json(state = JSON::State.new)
        {
          name: name,
          variance: variance,
          unchecked: unchecked?,
          location: location,
          upper_bound: upper_bound_type,
        }.to_json(state)
      end

      def rename(name)
        TypeParam.new(
          name: name,
          variance: variance,
          location: location
          upper_bound: upper_bound_type,
        ).unchecked!(unchecked?)
      end

      def map_type(&block)
        if b = upper_bound_type
          _upper_bound_type = yield(b)
        end

        TypeParam.new(
          name: name,
          variance: variance,
          location: location
          upper_bound: _upper_bound_type,
        ).unchecked!(unchecked?)
      end

      def self.resolve_variables(params)
        return if params.empty?

        vars = Set.new(params.map(&:name))

        params.map! do |param|
          param.map_type {|bound| _ = subst_var(vars, bound) }
        end
      end

      def self.subst_var(vars, type)
        case type
        when Types::ClassInstance
          namespace = type.name.namespace
          if namespace.relative? && namespace.empty? && vars.member?(type.name.name)
            return Types::Variable.new(name: type.name.name, location: type.location)
          end
        end

        type.map_type {|t| subst_var(vars, t) }
      end

      def self.rename(params, new_names:)
        raise unless params.size == new_names.size

        subst = Substitution.build(new_names, Types::Variable.build(new_names))

        params.map.with_index do |param, index|
          new_name = new_names[index]

          TypeParam.new(
            name: new_name,
            variance: param.variance,
            location: param.location
            upper_bound: param.upper_bound_type&.map_type {|type| type.sub(subst) },
          ).unchecked!(param.unchecked?)
        end
      end

      def to_s
        s = +""

        if unchecked?
          s << "unchecked "
        end

        case variance
        when :invariant
          # nop
        when :covariant
          s << "out "
        when :contravariant
          s << "in "
        end

        s << name.to_s

        if type = upper_bound_type
          s << " < #{type}"
        end

        s
      end
    end
  end
end
