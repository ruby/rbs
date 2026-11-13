require_relative "test_helper"
require "ipaddr"

class IPAddrTest < StdlibTest
  target IPAddr
  library "ipaddr"

  def test_hash
    IPAddr.new("192.168.2.0/24").hash
  end

  def test_hton
    IPAddr.new("192.168.2.0/24").hton
  end

  def test_include?
    net1 = IPAddr.new("192.168.2.0/24")
    net2 = IPAddr.new("192.168.2.100")
    net3 = IPAddr.new("192.168.3.0")
    net1.include?(net2)
    net1.include?(net3)
  end

  def test_inspect
    IPAddr.new("192.168.2.0/24").inspect
  end

  def test_ip6_arpa
    IPAddr.new("3ffe:505:2::1").ip6_arpa
  end

  def test_ip6_int
    IPAddr.new("3ffe:505:2::1").ip6_int
  end

  def test_ipv4?
    IPAddr.new("3ffe:505:2::1").ipv4?
  end

  def test_ipv4_mapped
    IPAddr.new("192.168.3.0").ipv4_mapped
  end

  def test_ipv6?
    IPAddr.new("3ffe:505:2::1").ipv6?
  end

  def test_link_local?
    IPAddr.new("3ffe:505:2::1").link_local?
  end

  def test_loopback?
    IPAddr.new("3ffe:505:2::1").loopback?
  end

  def test_prefix
    IPAddr.new("192.168.2.0/24").prefix
  end

  def test_private?
    IPAddr.new("3ffe:505:2::1").private?
  end

  def test_reverse
    IPAddr.new("3ffe:505:2::1").reverse
  end

  def test_succ
    IPAddr.new("192.168.2.0/24").succ
  end

  def test_to_i
    IPAddr.new("192.168.2.0/24").to_i
  end

  def test_to_string
    IPAddr.new("192.168.2.0/24").to_string
  end
end

class IPAddrInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "ipaddr"
  testing "::IPAddr"

  def test_as_json
    assert_send_type "() -> String", IPAddr.new("192.168.2.0/24"), :as_json
    assert_send_type "(nil) -> String", IPAddr.new("192.168.2.1"), :as_json, nil
  end

  def test_cidr
    assert_send_type "() -> String", IPAddr.new("192.168.2.0/24"), :cidr
  end

  def test_to_json
    assert_send_type "() -> String", IPAddr.new("192.168.2.0/24"), :to_json
    assert_send_type "(nil) -> String", IPAddr.new("192.168.2.0/24"), :to_json, nil
  end

  def test_wildcard_mask
    assert_send_type "() -> String", IPAddr.new("192.168.2.0/24"), :wildcard_mask
    assert_send_type "() -> String", IPAddr.new("2001:db8::/32"), :wildcard_mask
  end

  def test_zone_id
    assert_send_type "() -> String", IPAddr.new("fe80::1%eth0"), :zone_id
    assert_send_type "() -> nil", IPAddr.new("fe80::1"), :zone_id
  end

  def test_zone_id=
    assert_send_type "(String) -> String", IPAddr.new("fe80::1"), :zone_id=, "%eth0"
    assert_send_type "(nil) -> nil", IPAddr.new("fe80::1%eth0"), :zone_id=, nil
  end
end
