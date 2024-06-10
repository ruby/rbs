require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA512SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA512)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::SHA512',
                      ::Digest::SHA512, :file, name
    end
  end
end

class DigestSHA512InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA512'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::SHA512',
                      ::Digest::SHA512.new, :file, name
    end
  end
end
