require "test_helper"
require "rbs/test"

class SetupHelperTest < Test::Unit::TestCase
  include RBS::Test::SetupHelper
  include TestHelper

  def test_get_valid_sample_size
    assert_equal 100, get_sample_size("100")
    assert_nil get_sample_size("ALL")

    Array.new(1000) { |int| int.succ.to_s}.each do
      |str| assert_equal str.to_i, get_sample_size(str)
    end
  end

  def test_get_invalid_sample_size_error
    assert_raises_invalid_sample_size_error("yes")
    assert_raises_invalid_sample_size_error("0")
    assert_raises_invalid_sample_size_error("-1")
    assert_raises_invalid_sample_size_error(nil)
  end

  def assert_raises_invalid_sample_size_error(invalid_value)
    assert_raises InvalidSampleSizeError do
      get_sample_size(invalid_value)
    end
  end

  def test_to_double_class
    assert_equal [
      '::RSpec::Mocks::Double',
      '::RSpec::Mocks::InstanceVerifyingDouble',
      '::RSpec::Mocks::ObjectVerifyingDouble',
      '::RSpec::Mocks::ClassVerifyingDouble',
    ], to_double_class('rspec')
    assert_equal ['::Minitest::Mock'], to_double_class('minitest')

    silence_warnings do
      assert_nil to_double_class('rr')
      assert_nil to_double_class('foo')
      assert_nil to_double_class('bar')
      assert_nil to_double_class('mocha')
      assert_nil to_double_class(nil)
    end
  end
end
