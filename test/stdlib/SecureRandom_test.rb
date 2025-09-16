require_relative "test_helper"
require "securerandom"

class SecureRandomSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "securerandom"
  testing "singleton(::SecureRandom)"

  def test_uuid
    assert_send_type "() -> ::String",
                     SecureRandom, :uuid
  end
end
