require_relative "test_helper"

# Guards against "method drift" between the RBS core signatures and the actual
# runtime, in both directions:
#
# *   a method defined by Ruby but missing from RBS (e.g.
#     `Hash.ruby2_keywords_hash`), and
# *   a method declared in RBS but no longer defined by Ruby.
#
# Singleton methods and public/protected instance methods are checked. Only
# methods implemented in C or `<internal:...>` count as runtime methods, so
# methods added by libraries (`pp`, `json/add`, ...) are ignored. A method
# counts as declared if RBS declares it on the class or any ancestor.
#
# Only platform- and build-invariant core classes are hard-gated, for the same
# reasons as in `ConstantDriftTest`.
class MethodDriftTest < Test::Unit::TestCase
  # Platform/build-invariant core classes and modules whose declared method set
  # must match the runtime.
  HARD_GATE = [
    Float, Integer, Numeric, Rational, Complex,
    Math, Comparable, Enumerable,
    String, Symbol,
    Array, Hash, Range, Struct,
    NilClass, TrueClass, FalseClass,
    Proc, Method, UnboundMethod, Binding
  ].freeze

  # Known, intentional exceptions keyed by "::Name#" (instance methods) or
  # "::Name." (singleton methods) => [:method, ...]. See "Why does RBS declare
  # methods that Ruby does not define on that class?" in docs/CONTRIBUTING.md.
  SKIP = {
    # Declared on `Numeric` so that code typed as `Numeric` can add and
    # subtract, though only the subclasses define them at runtime.
    "::Numeric#" => [:+, :-],
    # TODO: Defined in `Kernel` at runtime, and these declarations are no more
    # precise than `Kernel#enum_for` (they even require the method name).
    # Consider removing them.
    "::Enumerable#" => [:to_enum, :enum_for],
    # Declared on `Struct` itself, but defined only on the classes that
    # `Struct.new` creates.
    "::Struct." => [:members, :keyword_init?],
    # TODO: Declare these (added in Ruby 4.0).
    "::Binding#" => [:implicit_parameters, :implicit_parameter_get, :implicit_parameter_defined?],
    # TODO: Declare this once `Ruby::Box` (experimental in Ruby 4.0) has a
    # signature.
    "::Method#" => [:box]
  }.freeze

  def env
    StdlibTest::DEFAULT_ENV
  end

  def builder
    @builder ||= RBS::DefinitionBuilder.new(env: env)
  end

  def core_method?(meth)
    location = meth.source_location
    location.nil? || location[0].start_with?("<internal:")
  end

  # Methods that RBS declares on `type_name` itself, excluding undefined
  # methods kept in RBS with a `bot` return type (e.g. `Complex#<`).
  def declared_here(definition, type_name)
    definition.methods.filter_map do |name, method|
      next unless method.implemented_in == type_name
      next if method.method_types.all? { _1.type.return_type.is_a?(RBS::Types::Bases::Bottom) }

      name
    end
  end

  def assert_no_drift(label, runtime, definition, defined_at_runtime)
    skip = SKIP[label] || []
    missing = (runtime - definition.methods.keys - skip).sort
    stale = (declared_here(definition, definition.type_name) - skip).reject { defined_at_runtime.(_1) }.sort

    assert_empty missing.map { "#{label}#{_1}" },
      "Runtime defines methods missing from RBS. " \
      "Add them to the signature (or add to MethodDriftTest::SKIP if intentional)."
    assert_empty stale.map { "#{label}#{_1}" },
      "RBS declares methods that no longer exist at runtime. " \
      "Remove them from the signature (or add to MethodDriftTest::SKIP if intentional)."
  end

  HARD_GATE.each do |klass|
    test_name = klass.name.gsub("::", "_")
    type_name = RBS::TypeName.parse("::#{klass.name}")

    define_method(:"test_no_singleton_method_drift_#{test_name}") do
      runtime = klass.singleton_methods(false).select { core_method?(klass.method(_1)) }
      sclass = klass.singleton_class
      assert_no_drift("#{type_name}.", runtime, builder.build_singleton(type_name),
                      -> { sclass.method_defined?(_1) || sclass.private_method_defined?(_1) })
    end

    define_method(:"test_no_instance_method_drift_#{test_name}") do
      runtime = (klass.public_instance_methods(false) + klass.protected_instance_methods(false))
        .select { core_method?(klass.instance_method(_1)) }
      assert_no_drift("#{type_name}#", runtime, builder.build_instance(type_name),
                      -> { klass.method_defined?(_1) || klass.private_method_defined?(_1) })
    end
  end
end
