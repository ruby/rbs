require "test_helper"
require "json"
require "rbs/json_schema/generator"

class RBS::JSONSchema::GeneratorTest < Test::Unit::TestCase

  def generator_object
    yield RBS::JSONSchema::Generator.new(options: {stringify_keys: false}, stdout: STDOUT, stderr: STDERR)
  end

  def test_error_validaiton
    invalid_schemas = JSON.parse(File.read(File.join(__dir__, "hello.json")))
    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[0]) }
      assert_equal "Invalid JSON Schema: type: untyped", err.message
    end

    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[1]) }
      assert_equal "Invalid JSON Schema: items: nil", err.message
    end

    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[2]) }
      assert_equal "Invalid JSON Schema: properties: #{invalid_schemas[2]["properties"]}", err.message
    end

    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[3]) }
      assert_equal "Invalid JSON Schema: enum: Can't assign string!", err.message
    end

    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[4]) }
      assert_equal "Invalid JSON Schema: oneOf: Wrong type", err.message
    end

    generator_object do |generator|
      err = assert_raises(RBS::JSONSchema::ValidationError) { generator.parse_schema("hello", invalid_schemas[5]) }
      assert_equal "Invalid JSON Schema: allOf: #{invalid_schemas[5]["allOf"]}", err.message
    end
  end
end