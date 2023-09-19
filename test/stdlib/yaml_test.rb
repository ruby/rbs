require_relative "test_helper"

require "yaml"
require "tmpdir"

class YAMLSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "yaml"
  testing "singleton(::YAML)"

  def test_load
    assert_send_type(
      "(::String) -> untyped",
      YAML, :load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, filename: ::_ToS, fallback: ::Integer, symbolize_names: bool, freeze: bool) -> untyped",
      YAML, :load, <<-YAML, filename: ToS.new("foo.yaml"), fallback: 123, symbolize_names: true, freeze: true
foo: 123
      YAML
    )
  end

  def test_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        YAML, :load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, fallback: ::String, symbolize_names: bool, freeze: bool) -> untyped",
        YAML, :load_file, Pathname(File.join(dir, "test.yaml")), fallback: "foo", symbolize_names: false, freeze: false
      )
    end
  end

  def test_safe_load
    assert_send_type(
      "(::String) -> untyped",
      YAML, :safe_load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, filename: ::_ToS, fallback: ::Symbol, symbolize_names: bool, freeze: bool) -> untyped",
      YAML, :safe_load, <<-YAML, permitted_classes: [Integer], permitted_symbols: [:foo], aliases: true, filename: ToS.new("foo.yaml"), fallback: :foo, symbolize_names: true, freeze: false
foo: 123
      YAML
    )
  end

  def test_unsafe_load
    assert_send_type(
      "(::String) -> untyped",
      YAML, :unsafe_load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, filename: ::_ToS, fallback: ::Symbol, symbolize_names: bool, freeze: bool, strict_integer: bool) -> untyped",
      YAML, :unsafe_load, <<-YAML, filename: ToS.new("foo.yaml"), fallback: :foo, symbolize_names: true, freeze: false, strict_integer: false
foo: 123
      YAML
    )
  end

  def test_dump
    assert_send_type(
      "(::Array[::Integer]) -> ::String",
      YAML, :dump, [1]
    )

    assert_send_type(
      "(::Array[::Integer], ::StringIO) -> ::StringIO",
      YAML, :dump, [1], StringIO.new()
    )

    assert_send_type(
      "(::Array[::Integer], indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool) -> ::String",
      YAML, :dump, [1], indentation: 3, line_width: 30, canonical: true, header: true
    )
  end
end
