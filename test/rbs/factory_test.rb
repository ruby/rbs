require "test_helper"

class RBS::FactoryTest < Minitest::Test
  include TestHelper

  def test_type_name
    factory = RBS::Factory.new()

    assert_equal type_name("Foo"), factory.type_name("Foo")
    assert_equal type_name("::Foo::Bar"), factory.type_name("::Foo::Bar")
  end
end
