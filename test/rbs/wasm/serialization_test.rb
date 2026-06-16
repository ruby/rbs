# frozen_string_literal: true

require "test_helper"
require "rbs/wasm/deserializer"

# Verifies that the binary serialization produced by `rbs_serialize_node`
# (src/serialize.c) round-trips back into exactly the same AST objects that the
# C extension builds directly via ast_translation.c.
#
# The parser is run twice over the same buffer: once through the normal
# C -> Ruby translation, and once through serialize -> deserialize. The two
# results must be deeply identical, down to locations and string encodings. This
# is what gives us confidence that the same format, produced inside WebAssembly,
# will rebuild correct objects on JRuby.
class RBS::WASM::SerializationTest < Test::Unit::TestCase
  ROOT = File.expand_path("../../..", __dir__)

  def buffer(source)
    RBS::Buffer.new(content: source, name: "test.rbs")
  end

  def assert_round_trips(buf)
    directives, decls = RBS::Parser._parse_signature(buf, 0, buf.content.bytesize)
    bytes = RBS::Parser._parse_signature_to_bytes(buf, 0, buf.content.bytesize)
    actual = RBS::WASM::Deserializer.deserialize(bytes, buf)

    diff = ast_diff([directives, decls], actual)
    assert_nil diff, "round-trip mismatch in #{buf.name}: #{diff}"
  end

  def test_signature_round_trip_for_bundled_rbs
    paths = Dir.glob(File.join(ROOT, "{core,stdlib,sig}/**/*.rbs")).sort
    assert_operator paths.size, :>, 0, "expected to find bundled RBS files"

    paths.each do |path|
      source = File.read(path)
      assert_round_trips(RBS::Buffer.new(content: source, name: path))
    end
  end

  def test_signature_round_trip_for_features
    sources = [
      "class Foo end",
      "class Foo < Bar end",
      "class Foo[A, out B, unchecked in C < Comparable[A]] end",
      "module M : Comparable, _Each[Integer] end",
      <<~RBS,
        # A documented class.
        class Account
          @balance: Integer
          self.@registry: Hash[Symbol, Account]
          @@count: Integer

          attr_reader name: String
          attr_accessor age (@years): Integer
          attr_writer secret (): String

          public
          def deposit: (Integer amount) -> void
                     | (Float) -> void
          private
          def self.find: (Symbol) -> Account?
          alias credit deposit
          include Comparable
          extend ClassMethods
          prepend Logging
        end
      RBS
      "type t[T] = [T, t[T]?] | { value: T, ?next: t[T] } | ^(T) { () -> void } -> bool",
      "type lit = 1 | -2 | :sym | \"str\" | true | false | nil",
      "interface _Each[A] def each: () { (A) -> void } -> void end",
      "$global: Integer\nCONST: String\nFoo::Bar: bool",
      "class A = B\nmodule M = N",
      "use Foo::Bar, Baz::*, Qux::Quux as Q\nclass A end",
      "# resolve-type-names: false\nclass A end",
    ]

    sources.each { |source| assert_round_trips(buffer(source)) }
  end

  def test_type_round_trip
    types = [
      "Integer", "::Foo::Bar::Baz", "Array[Integer]", "Integer | String | nil",
      "(Integer & Comparable)", "Integer?", "[Integer, String, bool]",
      "{ name: String, ?age: Integer }", "^(Integer, ?String) { () -> void } -> bool",
      "^() [self: Foo] -> void", "singleton(String)", "self", "instance", "class",
      "void", "untyped", "bool", "top", "bot", "nil",
      "1", "-42", ":symbol", '"string"', "true", "false",
      "123456789012345678901234567890", "Hash[Symbol, Array[Integer]]", "_Each[String]",
    ]

    types.each do |source|
      buf = buffer(source)
      expected = RBS::Parser._parse_type(buf, 0, source.bytesize, nil, true, true, true, true)
      bytes = RBS::Parser._parse_type_to_bytes(buf, 0, source.bytesize, nil, true, true, true, true)
      actual = RBS::WASM::Deserializer.deserialize(bytes, buf)

      assert_nil ast_diff(expected, actual), "type round-trip mismatch for #{source.inspect}"
    end
  end

  def test_method_type_round_trip
    method_types = [
      "() -> void",
      "(Integer) -> String",
      "[T] (T) -> T",
      "(Integer, ?String, *Symbol, foo: bool, ?bar: Integer, **untyped) -> void",
      "() { (Integer) -> void } -> bool",
      "() ?{ () -> void } -> void",
      "[A, B < Comparable[A]] (A) -> B",
    ]

    method_types.each do |source|
      buf = buffer(source)
      expected = RBS::Parser._parse_method_type(buf, 0, source.bytesize, nil, true)
      bytes = RBS::Parser._parse_method_type_to_bytes(buf, 0, source.bytesize, nil, true)
      actual = RBS::WASM::Deserializer.deserialize(bytes, buf)

      assert_nil ast_diff(expected, actual), "method type round-trip mismatch for #{source.inspect}"
    end
  end

  private

  # Returns nil when the two trees are deeply identical, or a String describing
  # the first difference found. This is stricter than RBS object `==` (which
  # ignores locations and comments) and also checks string encodings, so it
  # catches anything the serialization could get subtly wrong.
  def ast_diff(a, b, path = "")
    return nil if a.equal?(b)

    case a
    when nil, true, false, Symbol, Integer, Float
      a == b ? nil : "#{path}: #{a.inspect} != #{b.inspect}"
    when String
      if a == b && a.encoding == b.encoding
        nil
      else
        "#{path}: #{a.inspect} (#{a.encoding}) != #{b.inspect} (#{b.encoding})"
      end
    when Array
      return "#{path}: expected Array, got #{b.class}" unless b.is_a?(Array)
      return "#{path}: size #{a.size} != #{b.size}" unless a.size == b.size

      a.each_index do |i|
        diff = ast_diff(a[i], b[i], "#{path}[#{i}]")
        return diff if diff
      end
      nil
    when Hash
      return "#{path}: expected Hash, got #{b.class}" unless b.is_a?(Hash)
      return "#{path}: size #{a.size} != #{b.size}" unless a.size == b.size

      a.each do |key, value|
        return "#{path}: missing key #{key.inspect}" unless b.key?(key)

        diff = ast_diff(value, b[key], "#{path}{#{key.inspect}}")
        return diff if diff
      end
      nil
    when RBS::Location
      return "#{path}: expected Location, got #{b.class}" unless b.is_a?(RBS::Location)
      a == b ? nil : "#{path}: location #{a} != #{b}"
    when RBS::Buffer
      a.name == b.name ? nil : "#{path}: buffer #{a.name.inspect} != #{b.name.inspect}"
    else
      return "#{path}: class #{a.class} != #{b.class}" unless a.class == b.class

      a_ivars = a.instance_variables.sort
      unless a_ivars == b.instance_variables.sort
        return "#{path}: ivars #{a_ivars} != #{b.instance_variables.sort}"
      end

      a_ivars.each do |ivar|
        diff = ast_diff(a.instance_variable_get(ivar), b.instance_variable_get(ivar), "#{path}.#{ivar}")
        return diff if diff
      end
      nil
    end
  end
end
