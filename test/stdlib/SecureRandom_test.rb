require_relative "test_helper"
require "securerandom"

class SecureRandomSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "securerandom"
  testing "singleton(::SecureRandom)"

  def test_bytes
    assert_send_type "(::Integer) -> ::String",
                     SecureRandom, :bytes, 10
  end

  def test_uuid
    assert_send_type "() -> ::String",
                     SecureRandom, :uuid
  end
end
