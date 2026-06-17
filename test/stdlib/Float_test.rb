require_relative 'test_helper'

class FloatSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(Float)'

  def test_constant_DIG
    assert_const_type 'Integer',
                      'Float::DIG'
  end

  def test_constant_EPSILON
    assert_const_type 'Float',
                      'Float::EPSILON'
  end

  def test_constant_INFINITY
    assert_const_type 'Float',
                      'Float::INFINITY'
  end

  def test_constant_MANT_DIG
    assert_const_type 'Integer',
                      'Float::MANT_DIG'
  end

  def test_constant_MAX
    assert_const_type 'Float',
                      'Float::MAX'
  end

  def test_constant_MAX_10_EXP
    assert_const_type 'Integer',
                      'Float::MAX_10_EXP'
  end

  def test_constant_MAX_EXP
    assert_const_type 'Integer',
                      'Float::MAX_EXP'
  end

  def test_constant_MIN
    assert_const_type 'Float',
                      'Float::MIN'
  end

  def test_constant_MIN_10_EXP
    assert_const_type 'Integer',
                      'Float::MIN_10_EXP'
  end

  def test_constant_MIN_EXP
    assert_const_type 'Integer',
                      'Float::MIN_EXP'
  end

  def test_constant_NAN
    assert_const_type 'Float',
                      'Float::NAN'
  end

  def test_constant_RADIX
    assert_const_type 'Integer',
                      'Float::RADIX'
  end

  def test_constant_ROUNDS
    notify "Skipping test: Float::ROUNDS does not exist" unless defined? Float::ROUNDS
    assert_const_type 'Integer',
                      'Float::ROUNDS'
  end
end

class FloatInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing 'Float'
end
