require_relative '../test_helper'
require 'uri'

class URIHTTPSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing 'singleton(::URI::HTTP)'

  def test_build
    assert_send_type  '(Array[String | Integer] args) -> URI::HTTP',
                      URI::HTTP, :build,
                      [
                        'user:pass',
                        'localhost',
                        80,
                        '/foo/bar',
                        't=1',
                        'baz'
                      ]

    assert_send_type  '({ userinfo: String, host: String, port: Integer, path: String, query: String, fragment: String }) -> URI::HTTP',
                      URI::HTTP, :build,
                      {
                        userinfo: 'user:pass',
                        host: 'localhost',
                        port: 80,
                        path: '/foo/bar',
                        query: 't=1',
                        fragment: 'baz'
                      }

    assert_send_type  '({ userinfo: nil, host: nil, port: nil, path: nil, query: nil, fragment: nil }) -> URI::HTTP',
                      URI::HTTP, :build,
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

class URIHTTPInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing '::URI::HTTP'

  def http
    ::URI::HTTP.build({ userinfo: 'user:pass', host: 'localhost', port: 80, path: '/foo/bar', query: 't=1', fragment: 'baz' })
  end

  def test_request_uri
    assert_send_type  '() -> String',
                      http, :request_uri
  end
end
