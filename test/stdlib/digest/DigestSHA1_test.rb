require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA1SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA1)'

  def test_base64digest
    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                       ::Digest::SHA1, :base64digest, str
    end
  end

  def test_bubblebabble
    with_string('_bubblebabble_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::SHA1, :bubblebabble, str
    end
  end

  def test_digest
    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::SHA1, :digest, str
    end
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> ::Digest::SHA1',
                      ::Digest::SHA1, :file, str
    end
  end

  def test_hexdigest
    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::SHA1, :hexdigest, str
    end
  end
end

class DigestSHA1InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA1'

  def test_left_shift
    with_string('_binary_left_shift_') do |str|
      assert_send_type '(::string) -> Digest::SHA1',
                        ::Digest::SHA1.new, :<<, str
    end
  end

  def test_block_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA1.new, :block_length
  end

  def test_digest_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA1.new, :digest_length
  end

  def test_reset
    assert_send_type '() -> Digest::SHA1',
                     ::Digest::SHA1.new, :reset
  end

  def test_update
    with_string('_update_') do |str|
      assert_send_type '(::string) -> Digest::SHA1',
                      ::Digest::SHA1.new, :update, str
    end
  end

  def test_finish
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :finish
  end

  def test_initialize_copy
    assert_send_type '(Digest::SHA1) -> Digest::SHA1',
                     ::Digest::SHA1.new, :initialize_copy, ::Digest::SHA1.new
  end

  def test_equal
    assert_send_type '(::Digest::SHA1) -> bool',
                     ::Digest::SHA1.new, :==, ::Digest::SHA1.new

    with_string('_equal_') do |str|
      assert_send_type '(::string) -> bool',
                      ::Digest::SHA1.new, :==, str
    end
  end

  def test_base64digest
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :base64digest

    assert_send_type '(nil) -> ::String',
                     ::Digest::SHA1.new, :base64digest, nil

    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                      ::Digest::SHA1.new, :base64digest, str
    end
  end

  def test_base64digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :base64digest!
  end

  def test_bubblebabble
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :bubblebabble
  end

  def test_digest
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :digest

    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::SHA1.new, :digest, str
    end
  end

  def test_digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :digest!
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> Digest::SHA1',
                       ::Digest::SHA1.new, :file, str
    end
  end

  def test_hexdigest
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :hexdigest

    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::SHA1.new, :hexdigest, str
    end
  end

  def test_hexdigest_bang
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :hexdigest!
  end

  def test_inspect
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :inspect
  end

  def test_length
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA1.new, :length
  end

  def test_new
    assert_send_type '() -> ::Digest::Base',
                     ::Digest::SHA1.new, :new
  end

  def test_size
    assert_send_type '() -> ::Integer',
                     ::Digest::SHA1.new, :size
  end

  def test_to_s
    assert_send_type '() -> ::String',
                     ::Digest::SHA1.new, :to_s
  end
end
