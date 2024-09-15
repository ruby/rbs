require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestMD5SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::MD5)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::MD5',
                      ::Digest::MD5, :file, name
    end
  end
end

class DigestMD5InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::MD5'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::MD5',
                      ::Digest::MD5.new, :file, name
    end
  end
end
