require_relative '../test_helper'
require 'uri'

class URIFTPSingletonTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing 'singleton(::URI::FTP)'

  def test_build
    assert_send_type '(Array[String | Integer] args) -> URI::FTP',
                      URI::FTP, :build, ['user:pass', 'ftp.example.com', 21, '/path/to/file', 'i']

    assert_send_type '({ host: String, path: String }) -> URI::FTP',
                      URI::FTP, :build, { host: 'ftp.example.com', path: '/path/to/file' }
  end
end

class URIFTPInstanceTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing '::URI::FTP'

  def ftp
    URI::FTP.build(['user:pass', 'ftp.example.com', 21, '/path/to/file', 'i'])
  end

  def test_path
    assert_send_type '() -> String',
                      ftp, :path
  end

  def test_typecode
    assert_send_type '() -> String?',
                      ftp, :typecode
  end

  def test_typecode=
    assert_send_type '(String? typecode) -> String?',
                      ftp, :typecode=, 'a'
  end

  def test_set_typecode
    assert_send_type '(String? v) -> untyped',
                      ftp, :set_typecode, 'a'
  end
end
