require_relative "test_helper"

# Instantiate the pseudo class
module RBS
  module Unnamed
  end
end
RBS::Unnamed::TopLevelSelfClass = self.class
TopLevelSelf = self
def top_level_self_method1 = 1
def top_level_self_method2 = 2

class TopLevelSelfTest < Test::Unit::TestCase
  include TestHelper

  testing "::RBS::Unnamed::TopLevelSelfClass"

  def test_include
    assert_send_type "(Module) -> RBS::Unnamed::TopLevelSelfClass",
                     TopLevelSelf, :include, Module.new
  end

  def test_define_method
    assert_send_type "(Symbol) { () -> void } -> Symbol",
                     TopLevelSelf, :define_method, :foo do end
    assert_send_type "(Symbol, ^() -> void) -> Symbol",
                     TopLevelSelf, :define_method, :foo, -> {}
  end

  def test_public
    assert_send_type "() -> nil",
                     TopLevelSelf, :public
    assert_send_type "(Symbol) -> Symbol",
                     TopLevelSelf, :public, :top_level_self_method1
    assert_send_type "(Symbol, Symbol) -> [Symbol, Symbol]",
                     TopLevelSelf, :public, :top_level_self_method1, :top_level_self_method2
    assert_send_type "([Symbol, Symbol]) -> [Symbol, Symbol]",
                     TopLevelSelf, :public, [:top_level_self_method1, :top_level_self_method2]
  end

  def test_private
    assert_send_type "() -> nil",
                     TopLevelSelf, :private
    assert_send_type "(Symbol) -> Symbol",
                     TopLevelSelf, :private, :top_level_self_method1
    assert_send_type "(Symbol, Symbol) -> [Symbol, Symbol]",
                     TopLevelSelf, :private, :top_level_self_method1, :top_level_self_method2
    assert_send_type "([Symbol, Symbol]) -> [Symbol, Symbol]",
                     TopLevelSelf, :private, [:top_level_self_method1, :top_level_self_method2]
  end
end
