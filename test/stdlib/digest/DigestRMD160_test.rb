require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestRMD160SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::RMD160)'

  def test_base64digest
    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                       ::Digest::RMD160, :base64digest, str
    end
  end

  def test_bubblebabble
    with_string('_bubblebabble_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::RMD160, :bubblebabble, str
    end
  end

  def test_digest
    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::RMD160, :digest, str
    end
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> ::Digest::RMD160',
                      ::Digest::RMD160, :file, str
    end
  end

  def test_hexdigest
    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                      ::Digest::RMD160, :hexdigest, str
    end
  end
end

class DigestRMD160InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::RMD160'

  def test_left_shift
    with_string('_binary_left_shift_') do |str|
      assert_send_type '(::string) -> Digest::RMD160',
                        ::Digest::RMD160.new, :<<, str
    end
  end

  def test_block_length
    assert_send_type '() -> ::Integer',
                     ::Digest::RMD160.new, :block_length
  end

  def test_digest_length
    assert_send_type '() -> ::Integer',
                     ::Digest::RMD160.new, :digest_length
  end

  def test_reset
    assert_send_type '() -> Digest::RMD160',
                     ::Digest::RMD160.new, :reset
  end

  def test_update
    with_string('_update_') do |str|
      assert_send_type '(::string) -> Digest::RMD160',
                      ::Digest::RMD160.new, :update, str
    end
  end

  def test_finish
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :finish
  end

  def test_initialize_copy
    assert_send_type '(Digest::RMD160) -> Digest::RMD160',
                     ::Digest::RMD160.new, :initialize_copy, ::Digest::RMD160.new
  end

  def test_equal
    assert_send_type '(::Digest::RMD160) -> bool',
                     ::Digest::RMD160.new, :==, ::Digest::RMD160.new

    with_string('_equal_') do |str|
      assert_send_type '(::string) -> bool',
                      ::Digest::RMD160.new, :==, str
    end
  end

  def test_base64digest
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :base64digest

    assert_send_type '(nil) -> ::String',
                     ::Digest::RMD160.new, :base64digest, nil

    with_string('_base64digest_') do |str|
      assert_send_type '(::string str) -> ::String',
                      ::Digest::RMD160.new, :base64digest, str
    end
  end

  def test_base64digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :base64digest!
  end

  def test_bubblebabble
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :bubblebabble
  end

  def test_digest
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :digest

    with_string('_digest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::RMD160.new, :digest, str
    end
  end

  def test_digest_bang
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :digest!
  end

  def test_file
    with_string('README.md') do |str|
      assert_send_type '(::string) -> Digest::RMD160',
                       ::Digest::RMD160.new, :file, str
    end
  end

  def test_hexdigest
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :hexdigest

    with_string('_hexdigest_') do |str|
      assert_send_type '(::string) -> ::String',
                       ::Digest::RMD160.new, :hexdigest, str
    end
  end

  def test_hexdigest_bang
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :hexdigest!
  end

  def test_inspect
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :inspect
  end

  def test_length
    assert_send_type '() -> ::Integer',
                     ::Digest::RMD160.new, :length
  end

  def test_new
    assert_send_type '() -> ::Digest::Base',
                     ::Digest::RMD160.new, :new
  end

  def test_size
    assert_send_type '() -> ::Integer',
                     ::Digest::RMD160.new, :size
  end

  def test_to_s
    assert_send_type '() -> ::String',
                     ::Digest::RMD160.new, :to_s
  end
end
