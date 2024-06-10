require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestSHA384SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::SHA384)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::SHA384',
                      ::Digest::SHA384, :file, name
    end
  end
end

class DigestSHA384InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::SHA384'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::SHA384',
                      ::Digest::SHA384.new, :file, name
    end
  end
end
