require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA2SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA2)'

  def test_new
    assert_send_type '() -> ::Digest::SHA2',
                     ::Digest::SHA2, :new
    [256, 384, 512].each do |bitlen|
      assert_send_type "(#{bitlen}) -> ::Digest::SHA2",
                       ::Digest::SHA2, :new, bitlen
    end
  end

  def test_base64digest
    with_string('message') do |str|
      assert_send_type '(string) -> ::String',
                       ::Digest::SHA2, :base64digest, str
      [256, 384, 512].each do |bitlen|
        assert_send_type "(string, #{bitlen}) -> ::String",
                         ::Digest::SHA2, :base64digest, str, bitlen
      end
    end
  end

  def test_bubblebabble
    with_string('message') do |str|
      assert_send_type '(string) -> ::String',
                       ::Digest::SHA2, :bubblebabble, str
      [256, 384, 512].each do |bitlen|
        assert_send_type "(string, #{bitlen}) -> ::String",
                         ::Digest::SHA2, :bubblebabble, str, bitlen
      end
    end
  end

  def test_digest
    with_string('message') do |str|
      assert_send_type '(string) -> ::String',
                       ::Digest::SHA2, :digest, str
      [256, 384, 512].each do |bitlen|
        assert_send_type "(string, #{bitlen}) -> ::String",
                         ::Digest::SHA2, :digest, str, bitlen
      end
    end
  end

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::SHA2',
                       ::Digest::SHA2, :file, name
      [256, 384, 512].each do |bitlen|
        assert_send_type "(string, #{bitlen}) -> ::Digest::SHA2",
                         ::Digest::SHA2, :file, name, bitlen
      end
    end
  end

  def test_hexdigest
    with_string('message') do |str|
      assert_send_type '(string) -> ::String',
                       ::Digest::SHA2, :hexdigest, str
      [256, 384, 512].each do |bitlen|
        assert_send_type "(string, #{bitlen}) -> ::String",
                         ::Digest::SHA2, :hexdigest, str, bitlen
      end
    end
  end
end
