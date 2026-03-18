require_relative "../test_helper"

require "socket"

class TCPSocketSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "singleton(::TCPSocket)"

  PORT = 12345

  def open_server(port = PORT, handler: nil)
    TCPServer.open(port) do |server|
      thread = if handler
        Thread.new do
          handler[server.accept]
        end
      else
        Thread.new do
          client = server.accept
          client.puts "Hello!"
          client.close
        end
      end

      yield()

      thread.join
    end
  end

  def test_new
    open_server do
      assert_send_type(
        "(::string, ::int) -> ::TCPSocket",
        TCPSocket, :new, "localhost", PORT
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, fast_fallback: boolish, resolv_timeout: Integer, connect_timeout: Integer) -> ::TCPSocket",
        TCPSocket, :new, "localhost", PORT, fast_fallback: nil, resolv_timeout: 4, connect_timeout: 5
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, fast_fallback: boolish, open_timeout: Integer) -> ::TCPSocket",
        TCPSocket, :new, "localhost", PORT, fast_fallback: "true", open_timeout: 4
      )
    end
  end
end

class TCPSocketInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::TCPSocket"
end
