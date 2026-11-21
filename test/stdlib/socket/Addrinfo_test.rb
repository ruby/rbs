require_relative "../test_helper"

require "socket"

class AddrinfoInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "socket"
  testing "::Addrinfo"

  def test_bind
    assert_send_type(
      "() -> Socket",
      Addrinfo.tcp("127.0.0.1", 0), :bind
    ).close

    assert_send_type(
      "() { (Socket) -> Integer } -> Integer",
      Addrinfo.tcp("127.0.0.1", 0), :bind
    ) { |sock| sock.local_address.ip_port }
  end

  def test_connect
    with_server do |remote|
      assert_send_type(
        "() -> Socket",
        remote, :connect
      ).close
      assert_send_type(
        "(timeout: Integer) -> Socket",
        remote, :connect, timeout: 1
      ).close
      assert_send_type(
        "(timeout: nil) -> Socket",
        remote, :connect, timeout: nil
      ).close

      assert_send_type(
        "() { (Socket) -> Integer } -> Integer",
        remote, :connect
      ) { |sock| sock.remote_address.ip_port }
      assert_send_type(
        "(timeout: Integer) { (Socket) -> Integer } -> Integer",
        remote, :connect, timeout: 1
      ) { |sock| sock.remote_address.ip_port }
    end
  end

  def test_connect_from
    with_server do |remote|
      assert_send_type(
        "(String, Integer) -> Socket",
        remote, :connect_from, "127.0.0.1", 0
      ).close
      assert_send_type(
        "(Addrinfo, timeout: nil) -> Socket",
        remote, :connect_from, Addrinfo.tcp("127.0.0.1", 0), timeout: nil
      ).close

      assert_send_type(
        "(String, Integer) { (Socket) -> Integer } -> Integer",
        remote, :connect_from, "127.0.0.1", 0
      ) { |sock| sock.remote_address.ip_port }
      assert_send_type(
        "(Addrinfo, timeout: Integer) { (Socket) -> Integer } -> Integer",
        remote, :connect_from, Addrinfo.tcp("127.0.0.1", 0), timeout: 1
      ) { |sock| sock.remote_address.ip_port }
    end
  end

  def test_connect_to
    with_server do |remote|
      local = Addrinfo.tcp("127.0.0.1", 0)
      port = remote.ip_port

      assert_send_type(
        "(String, Integer) -> Socket",
        local, :connect_to, "127.0.0.1", port
      ).close
      assert_send_type(
        "(Addrinfo, timeout: nil) -> Socket",
        local, :connect_to, remote, timeout: nil
      ).close

      assert_send_type(
        "(String, Integer) { (Socket) -> Integer } -> Integer",
        local, :connect_to, "127.0.0.1", port
      ) { |sock| sock.remote_address.ip_port }
      assert_send_type(
        "(Addrinfo, timeout: Integer) { (Socket) -> Integer } -> Integer",
        local, :connect_to, remote, timeout: 1
      ) { |sock| sock.remote_address.ip_port }
    end
  end

  def test_listen
    assert_send_type(
      "() -> Socket",
      Addrinfo.tcp("127.0.0.1", 0), :listen
    ).close

    with_int(5) do |backlog|
      assert_send_type(
        "(int) -> Socket",
        Addrinfo.tcp("127.0.0.1", 0), :listen, backlog
      ).close

      assert_send_type(
        "(int) { (Socket) -> Integer } -> Integer",
        Addrinfo.tcp("127.0.0.1", 0), :listen, backlog
      ) { |sock| sock.local_address.ip_port }
    end

    assert_send_type(
      "() { (Socket) -> Integer } -> Integer",
      Addrinfo.tcp("127.0.0.1", 0), :listen
    ) { |sock| sock.local_address.ip_port }
  end

  private

  def with_server
    server = TCPServer.new("127.0.0.1", 0)
    yield server.local_address
  ensure
    server&.close
  end
end
