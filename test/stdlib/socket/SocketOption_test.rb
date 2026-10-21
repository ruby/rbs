require_relative "../test_helper"

require "socket"

class SocketOptionSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "singleton(::Socket::Option)"

  def test_new
    assert_send_type(
      "(::Symbol, ::Symbol, ::Symbol, ::String) -> ::Socket::Option",
      Socket::Option, :new, :INET, :SOCKET, :KEEPALIVE, [1].pack("i")
    )
    assert_send_type(
      "(::String, ::Integer, ::Integer, ::String) -> ::Socket::Option",
      Socket::Option, :new, "INET", Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, [1].pack("i")
    )
  end

  def test_bool
    assert_send_type(
      "(::Symbol, ::Symbol, ::Symbol, bool) -> ::Socket::Option",
      Socket::Option, :bool, :INET, :SOCKET, :KEEPALIVE, true
    )
  end

  def test_byte
    assert_send_type(
      "(::Symbol, ::Symbol, ::Symbol, ::Integer) -> ::Socket::Option",
      Socket::Option, :byte, :INET, :IP, :TTL, 3
    )
  end

  def test_int
    assert_send_type(
      "(::Symbol, ::Symbol, ::Symbol, ::Integer) -> ::Socket::Option",
      Socket::Option, :int, :INET, :SOCKET, :KEEPALIVE, 1
    )
  end

  def test_ipv4_multicast_loop
    assert_send_type(
      "(::Integer) -> ::Socket::Option",
      Socket::Option, :ipv4_multicast_loop, 1
    )
  end

  def test_ipv4_multicast_ttl
    assert_send_type(
      "(::Integer) -> ::Socket::Option",
      Socket::Option, :ipv4_multicast_ttl, 1
    )
  end

  def test_linger
    assert_send_type(
      "(bool, ::Integer) -> ::Socket::Option",
      Socket::Option, :linger, true, 10
    )
    assert_send_type(
      "(::Integer, ::Integer) -> ::Socket::Option",
      Socket::Option, :linger, 1, 10
    )
  end
end

class SocketOptionTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::Socket::Option"

  def keepalive
    Socket::Option.new(:INET, :SOCKET, :KEEPALIVE, [1].pack("i"))
  end

  def test_bool
    assert_send_type "() -> bool", keepalive, :bool
  end

  def test_byte
    assert_send_type "() -> ::Integer", Socket::Option.byte(:INET, :IP, :TTL, 3), :byte
  end

  def test_data
    assert_send_type "() -> ::String", keepalive, :data
  end

  def test_to_s
    assert_send_type "() -> ::String", keepalive, :to_s
  end

  def test_family
    assert_send_type "() -> ::Integer", keepalive, :family
  end

  def test_inspect
    assert_send_type "() -> ::String", keepalive, :inspect
  end

  def test_int
    assert_send_type "() -> ::Integer", keepalive, :int
  end

  def test_ipv4_multicast_loop
    assert_send_type "() -> ::Integer", Socket::Option.ipv4_multicast_loop(1), :ipv4_multicast_loop
  end

  def test_ipv4_multicast_ttl
    assert_send_type "() -> ::Integer", Socket::Option.ipv4_multicast_ttl(1), :ipv4_multicast_ttl
  end

  def test_level
    assert_send_type "() -> ::Integer", keepalive, :level
  end

  def test_linger
    assert_send_type "() -> [bool, ::Integer]", Socket::Option.linger(true, 10), :linger
  end

  def test_optname
    assert_send_type "() -> ::Integer", keepalive, :optname
  end

  def test_unpack
    assert_send_type "(::String) -> ::Array[untyped]", keepalive, :unpack, "i"
  end
end
