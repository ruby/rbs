require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestMD5SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::MD5)'

  def test_base64digest
    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                       ::Digest::MD5, :base64digest, str
    end
  end

  def test_bubblebabble
    with_string('_bubblebabble_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::MD5, :bubblebabble, str
    end
  end

  def test_digest
    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::MD5, :digest, str
    end
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> ::Digest::MD5',
                      ::Digest::MD5, :file, str
    end
  end

  def test_hexdigest
    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::MD5, :hexdigest, str
    end
  end
end

class DigestMD5InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::MD5'

  def test_left_shift
    with_string('_binary_left_shift_') do |str|
      assert_send_type '(::string) -> Digest::MD5',
                        ::Digest::MD5.new, :<<, str
    end
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
    assert_send_type '() -> Digest::MD5',
                     ::Digest::MD5.new, :reset
  end

  def test_update
    with_string('_update_') do |str|
      assert_send_type '(::string) -> Digest::MD5',
                      ::Digest::MD5.new, :update, str
    end
  end

  def test_finish
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :finish
  end

  def test_initialize_copy
    assert_send_type '(Digest::MD5) -> Digest::MD5',
                     ::Digest::MD5.new, :initialize_copy, ::Digest::MD5.new
  end

  def test_equal
    assert_send_type '(::Digest::MD5) -> bool',
                     ::Digest::MD5.new, :==, ::Digest::MD5.new

    with_string('_equal_') do |str|
      assert_send_type '(::string) -> bool',
                      ::Digest::MD5.new, :==, str
    end
  end

  def test_base64digest
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :base64digest

    assert_send_type '(nil) -> ::String',
                     ::Digest::MD5.new, :base64digest, nil

    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                      ::Digest::MD5.new, :base64digest, str
    end
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
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :digest

    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::MD5.new, :digest, str
    end
  end

  def test_digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :digest!
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> Digest::MD5',
                       ::Digest::MD5.new, :file, str
    end
  end

  def test_hexdigest
    assert_send_type '() -> ::String',
                     ::Digest::MD5.new, :hexdigest

    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::MD5.new, :hexdigest, str
    end
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
