require_relative "test_helper"
require 'miniTest/mock'

class MockTest < Test::Unit::TestCase
  include TypeAssertions

  library 'miniTest'
  testing '::Minitest::Mock'

  def array_of_strings
    ["one", "two", "three"]
  end

  def mock_initialize
    @mock = ::Minitest::Mock.new
    @mock.expect(:foo, nil)
    @mock.expect(:bar, nil, [["one"]])
  end

  def initialize_with_delegator

  end

  def array_of_hashes
    [{"a"=> 42, "b" => 1}, {a: "bar", b: "foo"}]
  end

  def test_expect
    assert_send_type "(Symbol, untyped, [Integer]) -> ::Minitest::Mock",
                      mock_initialize, :expect, :delete, true, [1]
    assert_send_type "(Symbol, untyped) -> ::Minitest::Mock",
                      mock_initialize, :expect, :delete, nil
    assert_send_type "(Symbol, untyped) {(String) -> String } -> ::Minitest::Mock",
                      mock_initialize, :expect, :delete, nil do "" end
    assert_raises ArgumentError do
      assert_send_type "(Symbol, untyped, Array[untyped]) {(untyped) -> untyped } -> untyped",
                       mock_initialize, :expect, :foobar, nil, ["one"] do "" end
    end
  end

  def test__call
    assert_send_type "(String, Hash[Symbol, Integer]) -> String",
                     mock_initialize, :__call, "test", a: 1, b: 2
    assert_send_type "(String, Hash[String, String]) -> String",
                     mock_initialize, :__call, "test", {"a" => "1", "b" => "2"}
    assert_send_type "(String, Array[Hash[untyped, untyped]]) -> String",
                     mock_initialize, :__call, "test", array_of_hashes
  end

  def test_method_missing
    assert_raises NoMethodError do
      assert_send_type "(Symbol, Array[String]) -> untyped",
                     mock_initialize, :method_missing, mock_initialize.delete, array_of_strings do "" end
    end

    assert_send_type "(Symbol) -> untyped",
                     mock_initialize, :method_missing, :foo
    assert_send_type "(Symbol, Array[String] args) -> untyped",
                     mock_initialize, :method_missing, :bar, ["one"]
    assert_send_type "(Symbol, Array[String] args) {(untyped) -> untyped} -> untyped",
                     mock_initialize, :method_missing, :bar, ["one"] do "" end
  end

  def test_respond_to?
    assert_send_type "(String) -> TrueClass",
                     mock_initialize, :respond_to?, "foo"
    assert_send_type "(Symbol) -> TrueClass",
                     mock_initialize, :respond_to?, :foo
    assert_send_type "(Symbol, bool) -> bool",
                     mock_initialize, :respond_to?, :foo, true
  end
end
