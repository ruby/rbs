require_relative "test_helper"

# Guards against "constant drift" between the RBS core signatures and the actual
# runtime, in both directions:
#
# *   a constant declared in RBS but no longer defined by Ruby (e.g.
#     `Float::ROUNDS`, removed in Ruby 3.0), and
# *   a constant defined by Ruby but missing from RBS.
#
# Only platform- and build-invariant core classes are hard-gated here. Classes
# whose constant set legitimately varies by OS or build options (`Process`,
# `Socket`, `Errno`, `Signal`, `File::Constants`, `RbConfig`, `Etc`, ...) are
# intentionally excluded: their RBS declarations cannot match any single
# platform's runtime. `Object`/`BasicObject`/`Kernel` are excluded too, since
# every top-level class shows up under `Object.constants`.
class ConstantDriftTest < Test::Unit::TestCase
  # Platform/build-invariant core classes and modules whose declared constant
  # set must match the runtime exactly.
  HARD_GATE = [
    Float, Integer, Numeric, Rational, Complex,
    Math, Comparable,
    String, Symbol,
    Array, Hash, Range, Struct,
    NilClass, TrueClass, FalseClass
  ].freeze

  # Known, intentional exceptions keyed by "::Name" => [:CONST, ...]. Use this
  # for runtime constants that are `private_constant` or otherwise legitimately
  # undeclared, so the gate stays green there without being weakened elsewhere.
  SKIP = {}.freeze

  def env
    StdlibTest::DEFAULT_ENV
  end

  # Constants declared directly under `type_name` in the loaded RBS environment
  # (plain constants plus nested classes/modules and their aliases), matching
  # what `Module#constants(false)` returns at runtime.
  def rbs_constants(type_name)
    prefix = "#{type_name}::"
    names = []
    [env.constant_decls, env.class_decls, env.class_alias_decls].each do |store|
      store.each_key do |tn|
        s = tn.to_s
        next unless s.start_with?(prefix)

        rest = s.delete_prefix(prefix)
        names << rest.to_sym unless rest.include?("::")
      end
    end
    names.uniq.sort
  end

  HARD_GATE.each do |klass|
    define_method(:"test_no_constant_drift_#{klass.name.gsub("::", "_")}") do
      type_name = "::#{klass.name}"
      skip = SKIP[type_name] || []
      runtime = (klass.constants(false) - skip).sort
      declared = (rbs_constants(type_name) - skip).sort

      stale = declared - runtime
      missing = runtime - declared

      assert_empty stale,
        "RBS declares #{type_name} constants that no longer exist at runtime: #{stale.inspect}. " \
        "Remove them from the signature (or add to ConstantDriftTest::SKIP if intentional)."
      assert_empty missing,
        "Runtime defines #{type_name} constants missing from RBS: #{missing.inspect}. " \
        "Add them to the signature (or add to ConstantDriftTest::SKIP if intentional)."
    end
  end
end
