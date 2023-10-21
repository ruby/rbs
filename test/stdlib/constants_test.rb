require_relative 'test_helper'

# initialize temporary class
module RBS
  module Unnamed
    ARGFClass ||= ARGF.class
  end
end

class ConstantsTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(Object)'

  def test_ARGF
    assert_const_type  'RBS::Unnamed::ARGFClass',
                       'ARGF'
  end

  def test_ARGV
    assert_const_type  'Array[String]',
                       'ARGV'
  end

  def test_CROSS_COMPILING
    # There's no way to test both variants of `CROSS_COMPILING`.
    assert_const_type 'true?',
                      'CROSS_COMPILING'
  end

  def test_DATA
    omit_unless defined?(DATA) # If you run this file from rake `DATA` won't be visible.
    assert_const_type 'File',
                      'DATA'
  end

  def test_RUBY_COPYRIGHT
    assert_const_type 'String',
                      'RUBY_COPYRIGHT'
  end

  def test_RUBY_DESCRIPTION
    assert_const_type 'String',
                      'RUBY_DESCRIPTION'
  end

  def test_RUBY_ENGINE
    assert_const_type 'String',
                      'RUBY_ENGINE'
  end

  def test_RUBY_ENGINE_VERSION
    assert_const_type 'String',
                      'RUBY_ENGINE_VERSION'
  end

  def test_RUBY_PATCHLEVEL
    assert_const_type 'Integer',
                      'RUBY_PATCHLEVEL'
  end

  def test_RUBY_PLATFORM
    assert_const_type 'String',
                      'RUBY_PLATFORM'
  end

  def test_RUBY_RELEASE_DATE
    assert_const_type 'String',
                      'RUBY_RELEASE_DATE'
  end

  def test_RUBY_REVISION
    assert_const_type 'String',
                      'RUBY_REVISION'
  end

  def test_RUBY_VERSION
    assert_const_type 'String',
                      'RUBY_VERSION'
  end

  def test_STDERR
    assert_const_type 'IO',
                      'STDERR'
  end

  def test_STDIN
    assert_const_type 'IO',
                      'STDIN'
  end

  def test_STDOUT
    assert_const_type 'IO',
                      'STDOUT'
  end

  def test_TOPLEVEL_BINDING
    assert_const_type 'Binding',
                      'TOPLEVEL_BINDING'
  end
end

__END__
This `__END__` is here so `DATA` is visible in the `test_DATA` method.
