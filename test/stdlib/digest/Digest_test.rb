require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest)'

  def test_const_missing
    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :SHA1

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :MD5

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :RMD160

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :SHA256

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :SHA384

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Class)',
                      ::Digest, :const_missing, :SHA512
  end

  def test_bubblebabble
    assert_send_type  '(::String) -> ::String',
                      ::Digest, :bubblebabble, '_bubblebabble_'
  end

  def test_hexencode
    assert_send_type  '(::String) -> ::String',
                      ::Digest, :hexencode, '_hexencode_'
  end
end

class DigestInstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest'

  def test_bubblebabble
    assert_send_type '(::String) -> ::String',
                     Class.new.include(Digest).new,
                     :bubblebabble, '_bubblebabble_'
  end

  def test_hexencode
    assert_send_type '(::String) -> ::String',
                     Class.new.include(Digest).new,
                     :hexencode, '_hexencode_'
  end
end

class ::Digest::Foo < ::Digest::Class
end

class DigestRootTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Object'

  def test_digest
    with_interned(:Foo) do |sym|
      assert_send_type '(interned name) -> singleton(::Digest::Class)',
                       ::Object, :Digest, :Foo
    end
  end
end
