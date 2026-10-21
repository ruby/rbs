require_relative "../test_helper"

require "socket"

class SocketResolutionErrorTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::Socket::ResolutionError"

  def resolution_error
    Addrinfo.getaddrinfo("nonexistent.invalid", nil)
  rescue Socket::ResolutionError => error
    error
  end

  def test_error_code
    assert_send_type(
      "() -> ::Integer",
      resolution_error, :error_code
    )
  end
end
