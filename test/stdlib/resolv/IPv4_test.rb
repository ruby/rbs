require_relative '../test_helper'
require 'resolv'


class ResolvIPv4SingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing 'singleton(::Resolv::IPv4)'

  def test_create
    assert_send_type "(String) -> Resolv::IPv4",
      Resolv::IPv4, :create, "8.8.8.8"

    rdata = [8,8,8,8].pack("CCCC")
    ip = Resolv::IPv4.new(rdata)
    assert_send_type "(Resolv::IPv4) -> Resolv::IPv4",
      Resolv::IPv4, :create, ip
  end
end

class ResolvIPv4InstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::IPv4'

  def ip(ipv4 = "127.0.0.1")
    rdata = ipv4.split(".").map(&:to_i).pack("CCCC")
    Resolv::IPv4.new(rdata)
  end

  def test_eql?
    assert_send_type "(Resolv::IPv4) -> bool",
      ip, :==, ip("8.8.8.8")
  end

  def test_address
    assert_send_type "() -> String",
      ip, :address
  end

  def test_hash
    assert_send_type "() -> Integer",
      ip, :hash
  end

  def test_to_name
    assert_send_type "() -> Resolv::DNS::Name",
      ip, :to_name
  end
end
