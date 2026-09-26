require_relative '../test_helper'
require 'uri'

class URISingletonTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing 'singleton(::URI)'

  def test_register_scheme
    assert_send_type '(String scheme, singleton(URI::Generic) klass) -> singleton(URI::Generic)',
                      URI, :register_scheme, 'TEST_SCHEME', URI::Generic
  end

  def test_parser=
    orig = URI::DEFAULT_PARSER
    assert_send_type '(URI::RFC2396_Parser | URI::RFC3986_Parser parser) -> void',
                      URI, :parser=, orig
  ensure
    URI.parser = orig
  end
end

class URIUtilTest < Test::Unit::TestCase
  include TestHelper
  library 'uri'
  testing 'singleton(::URI::Util)'

  def test_make_components_hash
    assert_send_type '(singleton(URI::Generic) klass, Array[untyped] array_hash) -> Hash[Symbol, untyped]',
                      URI::Util, :make_components_hash, URI::Generic, ['user:pass', 'host', 80, 'registry', '/path', 'opaque', 'query', 'fragment']
    assert_send_type '(singleton(URI::Generic) klass, Hash[Symbol, untyped] array_hash) -> Hash[Symbol, untyped]',
                      URI::Util, :make_components_hash, URI::Generic, { host: 'example.com', path: '/' }
  end
end
