require_relative './test_helper'
require 'singleton'

class SingletonSingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'singleton'
  testing 'singleton(::Singleton)'

  class TestClass
    include Singleton
  end

  def test_singleton_instance_methods
    omit "SingletonInstanceMethods is not available" unless Singleton.const_defined?(:SingletonInstanceMethods, false)

    assert_const_type "Module", "Singleton::SingletonInstanceMethods"
  end

  def test_version
    assert_const_type "String", "Singleton::VERSION"
  end

  def test_module_with_class_methods
    assert_send_type "() -> singleton(Singleton::SingletonClassMethods)",
                     Singleton, :module_with_class_methods
  end
end
