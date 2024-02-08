require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA512SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA512)'

  def test_base64digest
    assert_send_type '(::String str) -> ::String',
                     ::Digest::SHA512, :base64digest, '_base64digest_'
  end

  def test_bubblebabble
    assert_send_type '(::String) -> ::String',
                     ::Digest::SHA512, :bubblebabble, '_bubblebabble_'
  end

  def test_digest
    assert_send_type '(::String) -> ::String',
                     ::Digest::SHA512, :digest, '_digest_'
  end

  def test_file
    assert_send_type '(::String) -> ::Digest::Class',
                     ::Digest::SHA512, :file, 'README.md'
  end

  def test_hexdigest
    assert_send_type '(::String) -> ::String',
                     ::Digest::SHA512, :hexdigest, '_hexdigest_'
  end
end

class DigestSHA512InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA512'

  def test_left_shift
    assert_send_type '(::String) -> Digest::SHA512',
                     ::Digest::SHA512.new, :<<, '_binary_left_shift_'
  end

  def test_block_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA512.new, :block_length
  end

  def test_digest_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA512.new, :digest_length
  end

  def test_reset
    assert_send_type '() -> Digest::SHA512',
                     ::Digest::SHA512.new, :reset
  end

  def test_update
    assert_send_type '(::String) -> Digest::SHA512',
                     ::Digest::SHA512.new, :update, '_update_'
  end

  def test_finish
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :finish
  end

  def test_initialize_copy
    assert_send_type '(::Digest::Base) -> Digest::SHA512',
                     ::Digest::SHA512.new, :initialize_copy, ::Digest::SHA512.new
  end

  def test_equal
    assert_send_type '(::Digest::Instance | ::String) -> bool',
                     ::Digest::SHA512.new, :==, ::Digest::SHA512.new

    assert_send_type '(::Digest::Instance | ::String) -> bool',
                     ::Digest::SHA512.new, :==, '_equal_'
  end

  def test_base64digest
    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::SHA512.new, :base64digest

    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::SHA512.new, :base64digest, nil

    assert_send_type '(?::String? str) -> ::String',
                     ::Digest::SHA512.new, :base64digest, '_base64digest_'
  end

  def test_base64digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :base64digest!
  end

  def test_bubblebabble
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :bubblebabble
  end

  def test_digest
    assert_send_type '(?::String) -> ::String',
                     ::Digest::SHA512.new, :digest

    assert_send_type '(?::String) -> ::String',
                     ::Digest::SHA512.new, :digest, '_digest_'
  end

  def test_digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :digest
  end

  def test_file
    assert_send_type '(::String) -> Digest::SHA512',
                     ::Digest::SHA512.new, :file, 'README.md'
  end

  def test_hexdigest
    assert_send_type '(?::String) -> ::String',
                     ::Digest::SHA512.new, :hexdigest

    assert_send_type '(?::String) -> ::String',
                     ::Digest::SHA512.new, :hexdigest, '_hexdigest_'
  end

  def test_hexdigest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :hexdigest!
  end

  def test_inspect
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :inspect
  end

  def test_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA512.new, :length
  end

  def test_new
    assert_send_type '() -> ::Digest::Base',
                     ::Digest::SHA512.new, :new
  end

  def test_size
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA512.new, :size
  end

  def test_to_s
    assert_send_type '() -> ::String',
                     ::Digest::SHA512.new, :to_s
  end
end
