require_relative "../test_helper"

require "socket"

class TCPServerSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "singleton(::TCPServer)"

  def test_new
    assert_send_type(
      "(::Integer) -> ::TCPServer",
      TCPServer, :new, 0
    ).close

    assert_send_type(
      "(::String) -> ::TCPServer",
      TCPServer, :new, "0"
    ).close

    assert_send_type(
      "(::String, ::Integer) -> ::TCPServer",
      TCPServer, :new, "127.0.0.1", 0
    ).close

    assert_send_type(
      "(::String, ::String) -> ::TCPServer",
      TCPServer, :new, "127.0.0.1", "0"
    ).close

    assert_send_type(
      "(nil, ::Integer) -> ::TCPServer",
      TCPServer, :new, nil, 0
    ).close
  end
end

class TCPServerInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::TCPServer"

  def test_listen
    TCPServer.open("127.0.0.1", 0) do |server|
      with_int(1) do |backlog|
        assert_send_type(
          "(::int) -> 0",
          server, :listen, backlog
        )
      end
    end
  end
end
