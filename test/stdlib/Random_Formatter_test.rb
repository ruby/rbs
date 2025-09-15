require_relative "test_helper"
require "random/formatter"

class RandomFormatterSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "random-formatter"
  testing "singleton(::Random)"

  def test_base64
    assert_send_type "() -> ::String",
                     Random, :base64
    assert_send_type "(::Integer) -> ::String",
                     Random, :base64, 10
  end

  def test_hex
    assert_send_type "() -> ::String",
                     Random, :hex
    assert_send_type "(::Integer) -> ::String",
                     Random, :hex, 10
  end

  def test_random_bytes
    assert_send_type "() -> ::String",
                     Random, :random_bytes
    assert_send_type "(::Integer) -> ::String",
                     Random, :random_bytes, 10
  end

  def test_urlsafe_base64
    assert_send_type "() -> ::String",
                     Random, :urlsafe_base64
    assert_send_type "(::Integer) -> ::String",
                     Random, :urlsafe_base64, 10
    assert_send_type "(::Integer, boolish) -> ::String",
                     Random, :urlsafe_base64, 10, true
  end

  def test_uuid
    assert_send_type "() -> ::String",
                     Random, :uuid
  end

  def test_alphanumeric
    assert_send_type "() -> ::String",
                     Random, :alphanumeric
    assert_send_type  "(::Integer) -> ::String",
                     Random, :alphanumeric, 10
    assert_send_type "(::Integer, chars: Array[::String]) -> ::String",
                     Random, :alphanumeric, 10, chars: ["a", "b", "c"]
  end
end

class RandomFormatterTest < Test::Unit::TestCase
  include TestHelper

  library "random-formatter"
  testing "::Random"

  def test_base64
    assert_send_type "() -> ::String",
                     Random.new, :base64
    assert_send_type "(::Integer) -> ::String",
                     Random.new, :base64, 10
  end

  def test_hex
    assert_send_type "() -> ::String",
                     Random.new, :hex
    assert_send_type "(::Integer) -> ::String",
                     Random.new, :hex, 10
  end

  def test_random_bytes
    assert_send_type "() -> ::String",
                     Random.new, :random_bytes
    assert_send_type "(::Integer) -> ::String",
                     Random.new, :random_bytes, 10
  end

  def test_urlsafe_base64
    assert_send_type "() -> ::String",
                     Random.new, :urlsafe_base64
    assert_send_type "(::Integer) -> ::String",
                     Random.new, :urlsafe_base64, 10
    assert_send_type "(::Integer, boolish) -> ::String",
                     Random.new, :urlsafe_base64, 10, true
  end

  def test_uuid
    assert_send_type "() -> ::String",
                     Random.new, :uuid
  end

  def test_alphanumeric
    assert_send_type "() -> ::String",
                     Random.new, :alphanumeric
    assert_send_type "(::Integer) -> ::String",
                     Random.new, :alphanumeric, 10
    assert_send_type "(::Integer, chars: Array[::String]) -> ::String",
                     Random.new, :alphanumeric, 10, chars: ["a", "b", "c"]
  end
end
