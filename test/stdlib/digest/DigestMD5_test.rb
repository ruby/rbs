require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestMD5SingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library 'digest'
  testing 'singleton(::Digest::MD5)'

  def test_base64digest
    assert_send_type '(::String str) -> ::String',
                     ::Digest::MD5, :base64digest, '_base64digest_'
  end

  def test_bubblebabble
    assert_send_type '(::String) -> ::String',
                     ::Digest::MD5, :bubblebabble, '_bubblebabble_'
  end

  def test_digest
    assert_send_type '(::String) -> ::String',
                     ::Digest::MD5, :digest, '_digest_'
  end

  def test_file
    assert_send_type '(::String) -> ::Digest::Class',
                     ::Digest::MD5, :file, 'README.md'
  end

  def test_hexdigest
    assert_send_type '(::String) -> ::String',
                     ::Digest::MD5, :hexdigest, '_hexdigest_'
  end
end

class DigestMD5InstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'digest'
  testing '::Digest::MD5'

  def test_left_shift
    assert_send_type '(::String) -> self',
                     ::Digest::MD5.new, :<<, '_binary_left_shift_'
  end

  def test_block_length
    assert_send_type '() -> ::Integer',
                     ::Digest::MD5.new, :block_length
  end

  def test_digest_length
    assert_send_type '() -> ::Integer',
                     ::Digest::MD5.new, :digest_length
  end

  def test_reset
    assert_send_type '() -> self',
                     ::Digest::MD5.new, :reset
  end

  def test_update
    assert_send_type '(::String) -> self',
                     ::Digest::MD5.new, :update, '_update_'
  end

  def test_finish
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :finish
  end

  def test_initialize_copy
    assert_send_type '(::Digest::Base) -> self',
                     ::Digest::MD5.new, :initialize_copy, ::Digest::MD5.new
  end

  def test_equal
    assert_send_type '(::Digest::Instance | ::String) -> bool',
                     ::Digest::MD5.new, :==, ::Digest::MD5.new

    assert_send_type '(::Digest::Instance | ::String) -> bool',
                     ::Digest::MD5.new, :==, '_equal_'
  end

  def test_base64digest
    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::MD5.new, :base64digest

    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::MD5.new, :base64digest, nil

    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::MD5.new, :base64digest, '_base64digest_'
  end

  def test_base64digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :base64digest!
  end

  def test_bubblebabble
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :bubblebabble
  end

  def test_digest
    assert_send_type '(?::String) -> ::String',
                     ::Digest::MD5.new, :digest

    assert_send_type '(?::String) -> ::String',
                     ::Digest::MD5.new, :digest, '_digest_'
  end

  def test_digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :digest
  end

  def test_file
    assert_send_type '(::String) -> self',
                     ::Digest::MD5.new, :file, 'README.md'
  end

  def test_hexdigest
    assert_send_type '(?::String) -> ::String',
                     ::Digest::MD5.new, :hexdigest

    assert_send_type '(?::String) -> ::String',
                     ::Digest::MD5.new, :hexdigest, '_hexdigest_'
  end

  def test_hexdigest_bang
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :hexdigest!
  end

  def test_inspect
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :inspect
  end

  def test_length
    assert_send_type '() -> ::Integer',
                     ::Digest::MD5.new, :length
  end

  def test_new
    assert_send_type '() -> ::Digest::Base',
                     ::Digest::MD5.new, :new
  end

  def test_size
    assert_send_type '() -> ::Integer',
                     ::Digest::MD5.new, :size
  end

  def test_to_s
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :to_s
  end
end
