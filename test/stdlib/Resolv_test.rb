require_relative "test_helper"
require "resolv"

class ResolvSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "resolv"
  testing "singleton(::Resolv)"

  def test_each_address
    assert_send_type "(String) { (String) -> void } -> void",
    Resolv, :each_address, "localhost" do |c| c end
  end

  def test_each_name
    assert_send_type "(String) { (String) -> void } -> void",
    Resolv, :each_name, "127.0.0.1"  do |c| c end
  end

  def test_getaddress
    assert_send_type "(String) -> String",
    Resolv, :getaddress, "localhost"
  end

  def test_getaddresses
    assert_send_type "(String) -> Array[String]",
    Resolv, :getaddresses, "localhost"
  end

  def test_getname
    assert_send_type "(String) -> String",
    Resolv, :getname, "127.0.0.1"
  end

  def test_getnames
    assert_send_type "(String) -> Array[String]",
    Resolv, :getnames, "127.0.0.1"
  end
end

class ResolvInstanceTest < Test::Unit::TestCase
    include TypeAssertions

    library "resolv"
    testing "::Resolv"

    def resolv
      Resolv.new
    end

    def test_each_address
      assert_send_type "(String) { (String) -> void } -> void",
      resolv, :each_address, "localhost" do |c| c end
    end

    def test_each_name
      assert_send_type "(String) { (String) -> void } -> void",
      resolv, :each_name, "127.0.0.1"  do |c| c end
    end

    def test_getaddress
      assert_send_type "(String) -> String",
      resolv, :getaddress, "localhost"
    end

    def test_getaddresses
      assert_send_type "(String) -> Array[String]",
      resolv, :getaddresses, "localhost"
    end

    def test_getname
      assert_send_type "(String) -> String",
      resolv, :getname, "127.0.0.1"
    end

    def test_getnames
      assert_send_type "(String) -> Array[String]",
      resolv, :getnames, "127.0.0.1"
    end
  end
