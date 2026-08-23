require_relative './test_helper'
require 'singleton'

class SingletonSingletonTest < Test::Unit::TestCase
  include TestHelper
  
  library 'singleton'
  testing 'singleton(::Singleton)'

  class TestClass
    include Singleton
  end

  def test_instance
    assert_send_type  '() -> SingletonSingletonTest::TestClass',
                      TestClass, :instance
  end

  def test_singleton_instance_methods
    omit "SingletonInstanceMethods is not available" unless Singleton.const_defined?(:SingletonInstanceMethods, false)

    assert_const_type "Module", "Singleton::SingletonInstanceMethods"
  end
end
