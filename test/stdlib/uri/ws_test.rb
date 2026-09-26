require_relative '../test_helper'
require 'uri'
require 'uri/ws'
require 'uri/wss'

class URIWSSingletonTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing 'singleton(::URI::WS)'

  def test_build
    assert_send_type '(Array[String | Integer | nil] args) -> URI::WS',
                      URI::WS, :build, [nil, 'www.example.com', 80, '/path', 'query']

    assert_send_type '({ host: String, path: String }) -> URI::WS',
                      URI::WS, :build, { host: 'www.example.com', path: '/path' }
  end
end

class URIWSInstanceTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing '::URI::WS'

  def ws
    URI::WS.build(host: 'www.example.com', path: '/foo/bar', query: 'test=true')
  end

  def test_request_uri
    assert_send_type '() -> String?',
                      ws, :request_uri
  end
end
