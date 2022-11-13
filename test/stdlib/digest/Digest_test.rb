require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library 'digest'
  testing 'singleton(::Digest)'


  def test_const_missing
    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :const_missing, :SHA1

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :const_missing, :MD5

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :const_missing, :RMD160

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :const_missing, :SHA256

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :const_missing, :SHA384

    assert_send_type  '(::Symbol name) -> singleton(::Digest::Base)',
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
  include TypeAssertions

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

class DigestRootTest < Test::Unit::TestCase
  include TypeAssertions

  library 'digest'
  testing '::Object'

  def test_digest
    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :SHA1

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'SHA1'

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :MD5

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'MD5'

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :RMD160

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'RMD160'

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :SHA256

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'SHA256'

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :SHA384

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'SHA384'

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, :SHA512

    assert_send_type  '(::String | ::Symbol name) -> singleton(::Digest::Base)',
                      ::Digest, :Digest, 'SHA512'
  end
end
