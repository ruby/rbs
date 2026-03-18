require_relative "test_helper"
require "resolv"

class RubyTest < Test::Unit::TestCase
  include TestHelper

  testing "::Ruby"

  def test_constants
    assert_const_type '::String', 'Ruby::COPYRIGHT'
    assert_const_type '::String', 'Ruby::DESCRIPTION'
    assert_const_type '::String', 'Ruby::ENGINE'
    assert_const_type '::String', 'Ruby::ENGINE_VERSION'
    assert_const_type '::Integer', 'Ruby::PATCHLEVEL'
    assert_const_type '::String', 'Ruby::PLATFORM'
    assert_const_type '::String', 'Ruby::RELEASE_DATE'
    assert_const_type '::String', 'Ruby::REVISION'
    assert_const_type '::String', 'Ruby::VERSION'
  end
end
