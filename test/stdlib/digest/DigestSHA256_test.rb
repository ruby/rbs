require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA256SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA256)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::SHA256',
                      ::Digest::SHA256, :file, name
    end
  end
end

class DigestSHA256InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA256'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::SHA256',
                      ::Digest::SHA256.new, :file, name
    end
  end
end
