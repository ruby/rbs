require_relative '../test_helper'
require 'resolv'

class ResolvHostsInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::Hosts'

  def with_hosts
    Tempfile.create do |f|
      f.write(<<~HOSTS)
        127.0.0.1 localhost
      HOSTS
      f.close
      yield Resolv::Hosts.new(f.path)
    end
  end

  def test_each_address
    with_hosts do |hosts|
      assert_send_type "(String) { (String) -> void } -> void",
        hosts, :each_address, "localhost" do |c| c end
    end
  end

  def test_each_name
    with_hosts do |hosts|
      assert_send_type "(String) { (String) -> void } -> void",
        hosts, :each_name, "127.0.0.1"  do |c| c end
    end
  end

  def test_getaddress
    with_hosts do |hosts|
      assert_send_type "(String) -> String",
        hosts, :getaddress, "localhost"
    end
  end

  def test_getaddresses
    with_hosts do |hosts|
      assert_send_type "(String) -> Array[String]",
        hosts, :getaddresses, "localhost"
    end
  end

  def test_getname
    with_hosts do |hosts|
      assert_send_type "(String) -> String",
        hosts, :getname, "127.0.0.1"
    end
  end

  def test_getnames
    with_hosts do |hosts|
      assert_send_type "(String) -> Array[String]",
        hosts, :getnames, "127.0.0.1"
    end
  end
end
