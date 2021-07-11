require_relative '../test_helper'
require 'resolv'


class ResolvIPv6SingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing 'singleton(::Resolv::IPv6)'

  def test_create
    assert_send_type "(String) -> Resolv::IPv6",
      Resolv::IPv6, :create, "2001:4860:4860::8888"

    ip = Resolv::IPv6.create("2001:4860:4860::8888")
    assert_send_type "(Resolv::IPv6) -> Resolv::IPv6",
      Resolv::IPv6, :create, ip
  end
end

class ResolvIPv6InstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::IPv6'

  def ip(ipv6 = "::1")
    Resolv::IPv6.create(ipv6)
  end

  def test_eql?
    assert_send_type "(Resolv::IPv6) -> bool",
      ip, :==, ip("2001:4860:4860::8888")
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
