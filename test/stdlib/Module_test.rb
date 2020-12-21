require_relative "test_helper"

class ModuleSingletonTest < Minitest::Test
  include TypeAssertions

  testing "singleton(::Module)"

  def test_used_modules
    assert_send_type "() -> Array[Module]",
                     Module, :used_modules
  end
end

class ModuleInstanceTest < Minitest::Test
  include TypeAssertions

  testing "::Module"

  module Foo
    BAR = 1
  end

  def test_const_source_location
    assert_send_type "(Symbol) -> [String, Integer]",
                     Foo, :const_source_location, :BAR
    assert_send_type "(Symbol) -> nil",
                     Foo, :const_source_location, :UNKNOWN
    assert_send_type "(String) -> [String, Integer]",
                     Foo, :const_source_location, "BAR"
    assert_send_type "(String) -> nil",
                     Foo, :const_source_location, "UNKNOWN"
    assert_send_type "(Symbol, true) -> [String, Integer]",
                     Foo, :const_source_location, :BAR, true
    assert_send_type "(String, nil) -> [String, Integer]",
                     Foo, :const_source_location, "BAR", nil
    assert_send_type "(Symbol) -> [ ]",
                     Foo, :const_source_location, :String
    assert_send_type "(String) -> [ ]",
                     Foo, :const_source_location, "String"
    assert_send_type "(Symbol, true) -> [ ]",
                     Foo, :const_source_location, :String, true
    assert_send_type "(String, nil) -> nil",
                     Foo, :const_source_location, "String", nil
  end
end
