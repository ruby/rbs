require_relative 'test_helper'

class StructTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::Struct[::Integer]'

  MyStruct = Struct.new(:foo, :bar)

  def test_each
    assert_send_type '() { (::Integer?) -> void } -> self',
                      MyStruct.new(42), :each do end
    assert_send_type '() -> ::Enumerator[::Integer?, self]',
                      MyStruct.new(42), :each
  end
end
