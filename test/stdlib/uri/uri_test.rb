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
