require "test_helper"

class RBS::TypeNameTest < Minitest::Test
  include TestHelper
  include RBS

  def test_relative_name
    assert_equal type_name("B::C"), type_name("::A::B::C").relative_name_from(namespace("::A"))
    assert_equal type_name("C"), type_name("::A::B::C").relative_name_from(namespace("::A::B"))
    assert_equal type_name("B"), type_name("::A::B").relative_name_from(namespace("::A::B::C"))
    assert_equal type_name("C"), type_name("::A::B::C").relative_name_from(namespace("::A::B::C::D"))

    assert_equal type_name("::A::B::C"), type_name("::A::B::C").relative_name_from(namespace("::X"))

    assert_equal type_name("C"), type_name("::A::B::B::C").relative_name_from(namespace("::A::B::B"))
    assert_equal type_name("B::C"), type_name("::A::B::B::C").relative_name_from(namespace("::A::B"))
    assert_equal type_name("B::B::C"), type_name("::A::B::B::C").relative_name_from(namespace("::A"))
  end
end
