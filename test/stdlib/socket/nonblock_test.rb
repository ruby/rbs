require_relative "../test_helper"

require "socket"
require "tmpdir"

class BasicSocketNonblockInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::BasicSocket"

  def test_recv_nonblock
    UNIXSocket.pair do |a, b|
      b.write("abc")
      assert_send_type "(::Integer) -> ::String",
                       a, :recv_nonblock, 1
      assert_send_type "(::Integer, ::Integer, ::String) -> ::String",
                       a, :recv_nonblock, 1, 0, +""
      assert_send_type "(::Integer, exception: true) -> ::String",
                       a, :recv_nonblock, 1, exception: true
      assert_send_type "(::Integer, exception: false) -> :wait_readable",
                       a, :recv_nonblock, 1, exception: false
      b.write("d")
      assert_send_type "(::Integer, exception: false) -> ::String",
                       a, :recv_nonblock, 1, exception: false

      b.close
      assert_send_type "(::Integer) -> nil",
                       a, :recv_nonblock, 1
      assert_send_type "(::Integer, exception: false) -> nil",
                       a, :recv_nonblock, 1, exception: false
    end
  end

  def test_recvmsg_nonblock
    UNIXSocket.pair do |a, b|
      # The message tuple branch is not asserted: the runtime value is
      # `[mesg, addr, rflags, *controls]`, which the declared tuple type does not model.
      assert_send_type "(exception: false) -> :wait_readable",
                       a, :recvmsg_nonblock, exception: false

      b.close
      assert_send_type "() -> nil",
                       a, :recvmsg_nonblock
      assert_send_type "(exception: false) -> nil",
                       a, :recvmsg_nonblock, exception: false
    end
  end

  def test_sendmsg_nonblock
    UNIXSocket.pair do |a, b|
      assert_send_type "(::String) -> ::Integer",
                       a, :sendmsg_nonblock, "abc"
      assert_send_type "(::String, exception: true) -> ::Integer",
                       a, :sendmsg_nonblock, "abc", exception: true
      assert_send_type "(::String, exception: false) -> ::Integer",
                       a, :sendmsg_nonblock, "abc", exception: false

      chunk = "x" * 65536
      result = nil
      100_000.times do
        result = a.sendmsg_nonblock(chunk, exception: false)
        break if result == :wait_writable
      end
      assert_send_type "(::String, exception: false) -> :wait_writable",
                       a, :sendmsg_nonblock, chunk, exception: false
    end
  end
end

class SocketNonblockInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::Socket"

  def test_accept_nonblock
    server = Socket.new(:INET, :STREAM)
    server.bind(Addrinfo.tcp("127.0.0.1", 0))
    server.listen(5)

    assert_send_type "(exception: false) -> :wait_readable",
                     server, :accept_nonblock, exception: false

    3.times { TCPSocket.new("127.0.0.1", server.local_address.ip_port) }
    IO.select([server])
    assert_send_type "() -> [::Socket, ::Addrinfo]",
                     server, :accept_nonblock
    IO.select([server])
    assert_send_type "(exception: true) -> [::Socket, ::Addrinfo]",
                     server, :accept_nonblock, exception: true
    IO.select([server])
    assert_send_type "(exception: false) -> [::Socket, ::Addrinfo]",
                     server, :accept_nonblock, exception: false
  ensure
    server&.close
  end

  def test_connect_nonblock
    Dir.mktmpdir do |dir|
      path = File.join(dir, "sock")
      UNIXServer.open(path) do
        addr = Socket.sockaddr_un(path)

        Socket.new(:UNIX, :STREAM).tap do |s|
          assert_send_type "(::String) -> ::Integer", s, :connect_nonblock, addr
        end.close
        Socket.new(:UNIX, :STREAM).tap do |s|
          assert_send_type "(::String, exception: true) -> ::Integer", s, :connect_nonblock, addr, exception: true
        end.close
        Socket.new(:UNIX, :STREAM).tap do |s|
          assert_send_type "(::String, exception: false) -> ::Integer", s, :connect_nonblock, addr, exception: false
        end.close
      end
    end
  end

  def test_recvfrom_nonblock
    Socket.pair(:UNIX, :STREAM) do |a, b|
      b.write("abc")
      assert_send_type "(::Integer) -> [::String, ::Addrinfo]",
                       a, :recvfrom_nonblock, 1
      assert_send_type "(::Integer, exception: true) -> [::String, ::Addrinfo]",
                       a, :recvfrom_nonblock, 1, exception: true
      assert_send_type "(::Integer, exception: false) -> [::String, ::Addrinfo]",
                       a, :recvfrom_nonblock, 1, exception: false
      assert_send_type "(::Integer, exception: false) -> :wait_readable",
                       a, :recvfrom_nonblock, 1, exception: false

      b.close
      assert_send_type "(::Integer) -> nil",
                       a, :recvfrom_nonblock, 1
      assert_send_type "(::Integer, exception: false) -> nil",
                       a, :recvfrom_nonblock, 1, exception: false
    end
  end
end

class UDPSocketNonblockInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::UDPSocket"

  def test_recvfrom_nonblock
    receiver = UDPSocket.new
    receiver.bind("127.0.0.1", 0)
    sender = UDPSocket.new
    sender.connect("127.0.0.1", receiver.addr[1])

    assert_send_type "(::Integer, exception: false) -> :wait_readable",
                     receiver, :recvfrom_nonblock, 10, exception: false

    3.times { sender.send("abc", 0) }
    IO.select([receiver])
    assert_send_type "(::Integer) -> [::String, [::String, ::Integer, ::String, ::String]]",
                     receiver, :recvfrom_nonblock, 10
    IO.select([receiver])
    assert_send_type "(::Integer, exception: true) -> [::String, [::String, ::Integer, ::String, ::String]]",
                     receiver, :recvfrom_nonblock, 10, exception: true
    IO.select([receiver])
    assert_send_type "(::Integer, exception: false) -> [::String, [::String, ::Integer, ::String, ::String]]",
                     receiver, :recvfrom_nonblock, 10, exception: false
  ensure
    receiver&.close
    sender&.close
  end
end

class TCPServerNonblockInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::TCPServer"

  def test_accept_nonblock
    TCPServer.open("127.0.0.1", 0) do |server|
      assert_send_type "(exception: false) -> :wait_readable",
                       server, :accept_nonblock, exception: false

      clients = 3.times.map { TCPSocket.new("127.0.0.1", server.addr[1]) }
      IO.select([server])
      assert_send_type("() -> ::TCPSocket", server, :accept_nonblock).close
      IO.select([server])
      assert_send_type("(exception: true) -> ::TCPSocket", server, :accept_nonblock, exception: true).close
      IO.select([server])
      assert_send_type("(exception: false) -> ::TCPSocket", server, :accept_nonblock, exception: false).close
      clients.each(&:close)
    end
  end
end

class UNIXServerNonblockInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::UNIXServer"

  def test_accept_nonblock
    Dir.mktmpdir do |dir|
      path = File.join(dir, "sock")
      UNIXServer.open(path) do |server|
        assert_send_type "(exception: false) -> :wait_readable",
                         server, :accept_nonblock, exception: false

        clients = 3.times.map { UNIXSocket.new(path) }
        assert_send_type("() -> ::UNIXSocket", server, :accept_nonblock).close
        assert_send_type("(exception: true) -> ::UNIXSocket", server, :accept_nonblock, exception: true).close
        assert_send_type("(exception: false) -> ::UNIXSocket", server, :accept_nonblock, exception: false).close
        clients.each(&:close)
      end
    end
  end
end
