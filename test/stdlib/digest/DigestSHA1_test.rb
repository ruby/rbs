require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA1SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA1)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::SHA1',
                      ::Digest::SHA1, :file, name
    end
  end
end

class DigestSHA1InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA1'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::SHA1',
                      ::Digest::SHA1.new, :file, name
    end
  end
end
