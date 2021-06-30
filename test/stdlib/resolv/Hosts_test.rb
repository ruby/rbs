require_relative '../test_helper'
require 'resolv'

class ResolvHostsInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::Hosts'

  def hosts
    Resolv::Hosts.new
  end

  def test_each_address
    assert_send_type "(String) { (String) -> void } -> void",
      hosts, :each_address, "localhost" do |c| c end
  end

  def test_each_name
    assert_send_type "(String) { (String) -> void } -> void",
      hosts, :each_name, "127.0.0.1"  do |c| c end
  end

  def test_getaddress
    assert_send_type "(String) -> String",
      hosts, :getaddress, "localhost"
  end

  def test_getaddresses
    assert_send_type "(String) -> Array[String]",
      hosts, :getaddresses, "localhost"
  end

  def test_getname
    assert_send_type "(String) -> String",
      hosts, :getname, "127.0.0.1"
  end

  def test_getnames
    assert_send_type "(String) -> Array[String]",
      hosts, :getnames, "127.0.0.1"
  end
end