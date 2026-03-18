require_relative "../test_helper"

require "socket"

class SocketSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "singleton(::Socket)"

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

  def test_tcp
    open_server do
      assert_send_type(
        "(::string, ::int) -> ::Socket",
        Socket, :tcp, "localhost", PORT
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, resolv_timeout: Integer, connect_timeout: Integer) -> ::Socket",
        Socket, :tcp, "localhost", PORT, resolv_timeout: 4, connect_timeout: 5
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, open_timeout: Integer) -> ::Socket",
        Socket, :tcp, "localhost", PORT, open_timeout: 10
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, resolv_timeout: Integer, connect_timeout: Integer) { (::Socket) -> Integer } -> Integer",
        Socket, :tcp, "localhost", PORT, resolv_timeout: 4, connect_timeout: 5, &-> (socket) { 123 }
      )
    end

    open_server do
      assert_send_type(
        "(::string, ::int, open_timeout: Integer) { (::Socket) -> Integer } -> Integer",
        Socket, :tcp, "localhost", PORT, open_timeout: 10, &-> (socket) { 123 }
      )
    end
  end
end

class SocketInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::Socket"
end
