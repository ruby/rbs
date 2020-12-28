require_relative './test_helper'
require 'singleton'

class SingletonSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'singleton'
  testing 'singleton(::Singleton)'

  class TestClass
    include Singleton
  end

  def test_instance
    assert_send_type  '() -> SingletonSingletonTest::TestClass',
                      TestClass, :instance
  end
end
