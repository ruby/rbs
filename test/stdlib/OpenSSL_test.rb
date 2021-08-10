require_relative "test_helper"
require "openssl"

class OpenSSLSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "openssl"
  testing "singleton(::OpenSSL)"

  def test_Digest
    assert_send_type "(String) -> singleton(::OpenSSL::Digest)",
                     OpenSSL, :Digest, "MD5"
  end
end
