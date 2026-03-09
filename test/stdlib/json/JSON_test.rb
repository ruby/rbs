require_relative "../test_helper"
require "json"
require "tempfile"

class JsonToStr
  def initialize(value = "")
    @value = value
  end

  def to_str
    @value
  end
end

class JsonToS
  def initialize(value = "")
    @value = value
  end

  def to_s
    @value
  end
end

class JSONSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "json"
  testing "singleton(::JSON)"

  def test_aref
    assert_send_type "(String) -> 42", JSON, :[], "42"
    assert_send_type "(_ToStr) -> 42", JSON, :[], JsonToStr.new("42")
    assert_send_type "(ToJson) -> String", JSON, :[], ToJson.new
    assert_send_type "(ToJson, indent: String) -> String", JSON, :[], ToJson.new, { indent: "\t" }
  end

  def test_create_id
    JSON.create_id = JsonToS.new("json_class")
    assert_send_type "() -> _ToS", JSON, :create_id
    JSON.create_id = "json_class"
    assert_send_type "() -> String", JSON, :create_id
  end

  def test_create_id_eq
    assert_send_type "(_ToS) -> _ToS", JSON, :create_id=, JsonToS.new("json_class")
    assert_send_type "(String) -> String", JSON, :create_id=, "json_class"
  end

  def test_dump
    assert_send_type "(ToJson) -> String", JSON, :dump, ToJson.new
    assert_send_type "(ToJson, Integer) -> String", JSON, :dump, ToJson.new, 100
    assert_send_type "(ToJson, JsonToWritableIO) -> JsonWrite", JSON, :dump, ToJson.new, JsonToWritableIO.new
    assert_send_type "(ToJson, JsonWrite) -> JsonWrite", JSON, :dump, ToJson.new, JsonWrite.new
    assert_send_type "(ToJson, JsonWrite, Integer) -> JsonWrite", JSON, :dump, ToJson.new, JsonWrite.new, 100
  end

  def test_generate
    assert_send_type "(ToJson) -> String", JSON, :generate, ToJson.new
    assert_send_type "(ToJson, indent: String) -> String", JSON, :generate, ToJson.new, { indent: "\t" }
  end

  def test_generator
    assert_send_type "() -> singleton(JSON::Ext::Generator)", JSON, :generator
  end

  def test_generator=
    assert_send_type "(singleton(JSON::Ext::Generator)) -> void", JSON, :generator=, JSON::Ext::Generator
  end

  def test_load
    assert_send_type "(String) -> 42", JSON, :load, "42"
    assert_send_type "(_ToStr) -> 42", JSON, :load, JsonToStr.new("42")
    assert_send_type "(JsonToReadableIO) -> 42", JSON, :load, JsonToReadableIO.new
    assert_send_type "(JsonRead) -> 42", JSON, :load, JsonRead.new
    assert_send_type "(String, Proc) -> 42", JSON, :load, "42", proc { |a| a }
    assert_send_type "(String, Proc, Hash[untyped, untyped]) -> 42", JSON, :load, "42", proc { |a| a }, { alllow_nan: true }
  end

  def test_load_file
    Tempfile.create("json") do |f|
      f.write '{}'
      f.close

      assert_send_type "(String) -> untyped", JSON, :load_file, f.path
      assert_send_type "(String, Hash[untyped, untyped]) -> untyped", JSON, :load_file, f.path, { allow_nan: true }
    end
  end

  def test_load_file!
    Tempfile.create("json") do |f|
      f.write '{}'
      f.close

      assert_send_type "(String) -> untyped", JSON, :load_file!, f.path
      assert_send_type "(String, Hash[untyped, untyped]) -> untyped", JSON, :load_file!, f.path, { allow_nan: true }
    end
  end

  def test_parse
    assert_send_type "(String) -> 42", JSON, :parse, "42"
    assert_send_type "(_ToStr) -> 42", JSON, :parse, JsonToStr.new("42")
    assert_send_type "(String, Hash[untyped, untyped]) -> 42", JSON, :parse, "42", { allow_nan: true }
  end

  def test_parse!
    assert_send_type "(String) -> 42", JSON, :parse!, "42"
    assert_send_type "(_ToStr) -> 42", JSON, :parse!, JsonToStr.new("42")
    assert_send_type "(String, Hash[untyped, untyped]) -> 42", JSON, :parse!, "42", { allow_nan: true }
  end

  def test_parser
    assert_send_type "() -> singleton(JSON::Ext::Parser)", JSON, :parser
  end

  def test_parser=
    assert_send_type "(singleton(JSON::Ext::Parser)) -> void", JSON, :parser=, JSON::Ext::Parser
  end

  def test_pretty_generate
    assert_send_type "(ToJson) -> String", JSON, :pretty_generate, ToJson.new
    assert_send_type "(ToJson, indent: String) -> String", JSON, :pretty_generate, ToJson.new, { indent: "\t" }
  end

  def test_state
    assert_send_type "() -> singleton(JSON::Ext::Generator::State)", JSON, :state
  end

  def test_state_eq
    assert_send_type "(singleton(JSON::Ext::Generator::State)) -> singleton(JSON::Ext::Generator::State)", JSON, :state=, JSON::Ext::Generator::State
  end
end

class JSONInstanceTest < Test::Unit::TestCase
  include TestHelper

  class MyJSON
    include JSON

    def load_default_options
      {}
    end
  end

  library "json"
  testing "::JSON"

  def test_dump
    assert_send_type "(ToJson) -> String", MyJSON.new, :dump, ToJson.new
    assert_send_type "(ToJson, Integer) -> String", MyJSON.new, :dump, ToJson.new, 100
    assert_send_type "(ToJson, JsonToWritableIO) -> JsonWrite", MyJSON.new, :dump, ToJson.new, JsonToWritableIO.new
    assert_send_type "(ToJson, JsonWrite) -> JsonWrite", MyJSON.new, :dump, ToJson.new, JsonWrite.new
    assert_send_type "(ToJson, JsonWrite, Integer) -> JsonWrite", MyJSON.new, :dump, ToJson.new, JsonWrite.new, 100
  end

  def test_generate
    assert_send_type "(ToJson) -> String", MyJSON.new, :generate, ToJson.new
    assert_send_type "(ToJson, indent: String) -> String", MyJSON.new, :generate, ToJson.new, { indent: "\t" }
  end

  def test_parse
    assert_send_type "(String) -> 42", MyJSON.new, :parse, "42"
    assert_send_type "(_ToStr) -> 42", MyJSON.new, :parse, JsonToStr.new("42")
    assert_send_type "(String, Hash[untyped, untyped]) -> 42", MyJSON.new, :parse, "42", { allow_nan: true }
  end

  def test_parse!
    assert_send_type "(String) -> 42", MyJSON.new, :parse!, "42"
    assert_send_type "(_ToStr) -> 42", MyJSON.new, :parse!, JsonToStr.new("42")
    assert_send_type "(String, Hash[untyped, untyped]) -> 42", MyJSON.new, :parse!, "42", { allow_nan: true }
  end

  def test_pretty_generate
    assert_send_type "(ToJson) -> String", MyJSON.new, :pretty_generate, ToJson.new
    assert_send_type "(ToJson, indent: String) -> String", MyJSON.new, :pretty_generate, ToJson.new, { indent: "\t" }
  end

  def test_to_json_with_object
    assert_send_type "() -> String", Object.new, :to_json
    assert_send_type "(nil) -> String", Object.new, :to_json, nil
    assert_send_type "(JSON::State) -> String",  Object.new, :to_json, JSON::State.new
  end

  def test_to_json_with_nil
    assert_send_type "() -> String", nil, :to_json
    assert_send_type "(nil) -> String", nil, :to_json, nil
    assert_send_type "(JSON::State) -> String", nil, :to_json, JSON::State.new
  end

  def test_to_json_with_true
    assert_send_type "() -> String", true, :to_json
    assert_send_type "(nil) -> String", true, :to_json, nil
    assert_send_type "(JSON::State) -> String", true, :to_json, JSON::State.new
  end

  def test_to_json_with_false
    assert_send_type "() -> String", false, :to_json
    assert_send_type "(nil) -> String", false, :to_json, nil
    assert_send_type "(JSON::State) -> String", false, :to_json, JSON::State.new
  end

  def test_to_json_with_string
    assert_send_type "() -> String", "foo", :to_json
    assert_send_type "(nil) -> String", "foo", :to_json, nil
    assert_send_type "(JSON::State) -> String", "foo", :to_json, JSON::State.new
  end

  def test_to_json_with_integer
    assert_send_type "() -> String", 123, :to_json
    assert_send_type "(nil) -> String", 123, :to_json, nil
    assert_send_type "(JSON::State) -> String", 123, :to_json, JSON::State.new
  end

  def test_to_json_with_float
    assert_send_type "() -> String", 0.123, :to_json
    assert_send_type "(nil) -> String", 0.123, :to_json, nil
    assert_send_type "(JSON::State) -> String", 0.123, :to_json, JSON::State.new
  end

  def test_to_json_with_hash
    assert_send_type "() -> String", { a: 1 }, :to_json
    assert_send_type "(nil) -> String", { a: 1 }, :to_json, nil
    assert_send_type "(JSON::State) -> String", { a: 1 }, :to_json, JSON::State.new
  end

  def test_to_json_with_array
    assert_send_type "() -> String", [], :to_json
    assert_send_type "(nil) -> String", [], :to_json, nil
    assert_send_type "(JSON::State) -> String", [], :to_json, JSON::State.new
  end
end
