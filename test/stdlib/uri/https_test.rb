require_relative '../test_helper'
require 'uri'

class URIHTTPSSingletonTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing 'singleton(::URI::HTTPS)'

  def test_build
    assert_send_type  '(Array[String | Integer] args) -> URI::HTTPS',
                      URI::HTTPS, :build,
                      [
                        'user:pass',
                        'localhost',
                        443,
                        '/foo/bar',
                        't=1',
                        'baz'
                      ]

    assert_send_type  '({ userinfo: String, host: String, port: Integer, path: String, query: String, fragment: String }) -> URI::HTTPS',
                      URI::HTTPS, :build,
                      {
                        userinfo: 'user:pass',
                        host: 'localhost',
                        port: 443,
                        path: '/foo/bar',
                        query: 't=1',
                        fragment: 'baz'
                      }

    assert_send_type  '({ userinfo: nil, host: nil, port: nil, path: nil, query: nil, fragment: nil }) -> URI::HTTPS',
                      URI::HTTPS, :build,
                      {
                        userinfo: nil,
                        host: nil,
                        port: nil,
                        path: nil,
                        query: nil,
                        fragment: nil
                      }
  end
end

class URIHTTPSInstanceTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing '::URI::HTTPS'

  def https
    ::URI::HTTPS.build({ userinfo: 'user:pass', host: 'localhost', port: 80, path: '/foo/bar', query: 't=1', fragment: 'baz' })
  end

  def test_request_uri
    assert_send_type  '() -> String',
                      https, :request_uri
  end
end
