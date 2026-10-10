require_relative "../test_helper"

require "socket"

class BasicSocketSockoptTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::BasicSocket"

  def test_getsockopt
    Socket.open(:INET, :STREAM) do |socket|
      assert_send_type(
        "(::Symbol, ::Symbol) -> ::Socket::Option",
        socket, :getsockopt, :SOCKET, :KEEPALIVE
      )
      assert_send_type(
        "(::Integer, ::Integer) -> ::Socket::Option",
        socket, :getsockopt, Socket::SOL_SOCKET, Socket::SO_KEEPALIVE
      )
    end
  end

  def test_setsockopt
    Socket.open(:INET, :STREAM) do |socket|
      assert_send_type(
        "(::Socket::Option) -> void",
        socket, :setsockopt, Socket::Option.bool(:INET, :SOCKET, :KEEPALIVE, true)
      )
      assert_send_type(
        "(::Symbol, ::Symbol, bool) -> void",
        socket, :setsockopt, :SOCKET, :KEEPALIVE, true
      )
      assert_send_type(
        "(::Symbol, ::Symbol, ::Integer) -> void",
        socket, :setsockopt, :SOCKET, :KEEPALIVE, 1
      )
      assert_send_type(
        "(::Integer, ::Integer, ::String) -> void",
        socket, :setsockopt, Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, [1].pack("i")
      )
    end
  end
end
