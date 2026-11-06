require_relative "test_helper"

require "psych"
require "date"
require "tmpdir"

class PsychSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych", "date"
  testing "singleton(::Psych)"

  def test_load
    assert_send_type(
      "(::String) -> untyped",
      Psych, :load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, filename: ::_ToS, fallback: ::Integer, symbolize_names: bool, freeze: bool) -> untyped",
      Psych, :load, <<-YAML, filename: ToS.new("foo.yaml"), fallback: 123, symbolize_names: true, freeze: true
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, strict_integer: bool) -> untyped",
      Psych, :load, <<-YAML, permitted_classes: [Date], permitted_symbols: [:foo], aliases: true, strict_integer: true
foo: &foo 2026-11-05
bar: *foo
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
        Psych, :load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, fallback: ::String, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :load_file, Pathname(File.join(dir, "test.yaml")), fallback: "foo", symbolize_names: false, freeze: false
      )

      assert_send_type(
        "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, strict_integer: bool) -> untyped",
        Psych, :load_file, File.join(dir, "test.yaml"), permitted_classes: [Date], permitted_symbols: [:foo], aliases: true, strict_integer: true
      )
    end
  end

  def test_safe_load
    assert_send_type(
      "(::String) -> untyped",
      Psych, :safe_load, <<-YAML
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, filename: ::_ToS, fallback: ::Symbol, symbolize_names: bool, freeze: bool) -> untyped",
      Psych, :safe_load, <<-YAML, permitted_classes: [Integer], permitted_symbols: [:foo], aliases: true, filename: ToS.new("foo.yaml"), fallback: :foo, symbolize_names: true, freeze: false
foo: 123
      YAML
    )

    assert_send_type(
      "(::String, strict_integer: bool) -> untyped",
      Psych, :safe_load, <<-YAML, strict_integer: true
foo: 123
      YAML
    )
  end

  def test_safe_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        Psych, :safe_load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool, fallback: ::Symbol, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :safe_load_file, Pathname(File.join(dir, "test.yaml")), permitted_classes: [Integer], permitted_symbols: [:foo], aliases: true, fallback: :foo, symbolize_names: true, freeze: false
      )

      assert_send_type(
        "(::String, strict_integer: bool) -> untyped",
        Psych, :safe_load_file, File.join(dir, "test.yaml"), strict_integer: true
      )
    end
  end

  def test_unsafe_load_file
    Dir.mktmpdir do |dir|
      (Pathname(dir) + "test.yaml").write(<<-YAML)
foo: 123
      YAML

      assert_send_type(
        "(::String) -> untyped",
        Psych, :unsafe_load_file, File.join(dir, "test.yaml")
      )

      assert_send_type(
        "(::_ToPath, fallback: ::String, symbolize_names: bool, freeze: bool) -> untyped",
        Psych, :unsafe_load_file, Pathname(File.join(dir, "test.yaml")), fallback: "foo", symbolize_names: false, freeze: false
      )

      assert_send_type(
        "(::String, strict_integer: bool) -> untyped",
        Psych, :unsafe_load_file, File.join(dir, "test.yaml"), strict_integer: true
      )
    end
  end

  def test_dump
    assert_send_type(
      "(::Array[::Integer]) -> ::String",
      Psych, :dump, [1]
    )

    assert_send_type(
      "(::Array[::Integer], ::StringIO) -> ::StringIO",
      Psych, :dump, [1], StringIO.new()
    )

    assert_send_type(
      "(::Array[::Integer], indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool) -> ::String",
      Psych, :dump, [1], indentation: 3, line_width: 30, canonical: true, header: true
    )

    assert_send_type(
      "(::Hash[::Symbol, ::Integer], ::StringIO, stringify_names: bool) -> ::StringIO",
      Psych, :dump, { foo: 1 }, StringIO.new(), stringify_names: true
    )
  end

  def test_safe_dump
    assert_send_type(
      "(::Array[::Integer]) -> ::String",
      Psych, :safe_dump, [1]
    )

    assert_send_type(
      "(::Array[::Integer], ::StringIO) -> ::StringIO",
      Psych, :safe_dump, [1], StringIO.new()
    )

    assert_send_type(
      "(::Array[::Date], ::StringIO, permitted_classes: ::Array[::Class], permitted_symbols: ::Array[::Symbol], aliases: bool) -> ::StringIO",
      Psych, :safe_dump, [Date.new(2026, 11, 5)], StringIO.new(), permitted_classes: [Date], permitted_symbols: [:foo], aliases: true
    )

    assert_send_type(
      "(::Hash[::String, ::Integer], ::StringIO, indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool, stringify_names: bool) -> ::StringIO",
      Psych, :safe_dump, { "foo" => 1 }, StringIO.new(), indentation: 3, line_width: 30, canonical: true, header: true, stringify_names: true
    )
  end

  def test_to_yaml
    assert_send_type(
      "() -> ::String",
      [1], :to_yaml
    )

    assert_send_type(
      "(::StringIO) -> ::StringIO",
      [1], :to_yaml, StringIO.new()
    )

    assert_send_type(
      "(indentation: ::Integer, line_width: ::Integer, canonical: bool, header: bool) -> ::String",
      [1], :to_yaml, indentation: 3, line_width: 30, canonical: true, header: true
    )
  end
end

class PsychObjectSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "psych"
  testing "singleton(::Object)"

  class Tagged
  end

  def test_yaml_tag
    assert_send_type(
      "(::String) -> ::String",
      Tagged, :yaml_tag, "!rbs-test/tagged"
    )
  end
end
