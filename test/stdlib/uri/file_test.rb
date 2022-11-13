require_relative '../test_helper'
require 'uri'

class URIFileSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing 'singleton(::URI::File)'

  def test_build
    assert_send_type  '(Array[String] args) -> URI::File',
                      URI::File, :build, ['localhost', '/path/to/file']

    assert_send_type  '({ host: String, path: String }) -> URI::File',
                      URI::File, :build,
                      {
                        host: 'localhost',
                        path: '/path/to/file'
                      }

    assert_send_type  '({ host: nil, path: nil }) -> URI::File',
                      URI::File, :build,
                      {
                        host: nil,
                        path: nil
                      }
  end
end

class URIFileInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing '::URI::File'

  def file
    ::URI::File.build({ host: 'test.org', path: '/path' })
  end

  def test_set_host
    assert_send_type  '(String? v) -> String',
                      file, :set_host, nil

    assert_send_type  '(String? v) -> String',
                      file, :set_host, "localhost"
  end

  def test_set_port
    assert_send_type  '(Integer v) -> nil',
                      file, :set_port, 80
  end

  def test_check_userinfo
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        file, :check_userinfo, 'user:pass'
    end
  end

  def test_check_user
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        file, :check_user, 'user'
    end
  end

  def test_check_password
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        file, :check_password, 'pass'
    end
  end

  def test_set_userinfo
    assert_send_type  '(String v) -> nil',
                      file, :set_userinfo, 'user:pass'
  end

  def test_set_user
    assert_send_type  '(String v) -> nil',
                      file, :set_user, 'user'
  end

  def test_set_password
    assert_send_type  '(String v) -> nil',
                      file, :set_password, 'pass'
  end
end
