require_relative 'test_helper'

class FloatSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Float)'
end

class FloatInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Float'
end
