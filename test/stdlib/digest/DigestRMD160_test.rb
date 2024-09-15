require_relative '../test_helper'
require 'digest'
require 'digest/bubblebabble'

class DigestRMD160SingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing 'singleton(::Digest::RMD160)'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> ::Digest::RMD160',
                      ::Digest::RMD160, :file, name
    end
  end
end

class DigestRMD160InstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'digest'
  testing '::Digest::RMD160'

  def test_file
    with_string('README.md') do |name|
      assert_send_type '(string) -> Digest::RMD160',
                      ::Digest::RMD160.new, :file, name
    end
  end
end
