require_relative '../test_helper'
require 'uri'

class URIGenericSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing 'singleton(::URI::Generic)'

  def test_default_port
    assert_send_type  '() -> Integer?',
                      URI::Generic, :default_port
  end

  def test_component
    assert_send_type  '() -> Array[Symbol]',
                      URI::Generic, :component
  end

  def test_use_registry
    assert_send_type  '() -> bool',
                      URI::Generic, :use_registry
  end

  def test_build2
    assert_send_type  '(Array[nil | String | Integer]) -> URI::Generic',
                      URI::Generic, :build2, [nil, nil, nil, nil, nil, nil, nil, nil, nil]

    assert_send_type  '(Array[nil | String | Integer]) -> URI::Generic',
                      URI::Generic, :build2, ['http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?t=1', 'baz']

    assert_send_type '({ scheme: String, userinfo: String, host: String, port: Integer, registry: String?, path: String, opaque: String?, query: String, fragment: String }) -> URI::Generic',
                      URI::Generic, :build2,
                      {
                        scheme: 'http',
                        userinfo: 'user:pass',
                        host: 'localhost',
                        port: 80,
                        registry: nil,
                        path: '/foo/bar',
                        opaque: nil,
                        query: '?t=1',
                        fragment: 'baz'
                      }

    assert_send_type '({ scheme: nil, userinfo: nil, host: nil, port: nil, registry: nil, path: nil, opaque: nil, query: nil, fragment: nil }) -> URI::Generic',
                      URI::Generic, :build2,
                      {
                        scheme: nil,
                        userinfo: nil,
                        host: nil,
                        port: nil,
                        registry: nil,
                        path: nil,
                        opaque: nil,
                        query: nil,
                        fragment: nil
                      }
  end

  def test_build
    assert_send_type  '(Array[nil | String | Integer]) -> URI::Generic',
                      URI::Generic, :build, [nil, nil, nil, nil, nil, nil, nil, nil, nil]

    assert_send_type  '(Array[nil | String | Integer]) -> URI::Generic',
                      URI::Generic, :build, ['http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?t=1', 'baz']

    assert_send_type '({ scheme: String, userinfo: String, host: String, port: Integer, registry: String?, path: String, opaque: String?, query: String, fragment: String }) -> URI::Generic',
                      URI::Generic, :build,
                      {
                        scheme: 'http',
                        userinfo: 'user:pass',
                        host: 'localhost',
                        port: 80,
                        registry: nil,
                        path: '/foo/bar',
                        opaque: nil,
                        query: '?t=1',
                        fragment: 'baz'
                      }
  end

  def test_new
    assert_send_type  '(String scheme, String userinfo, String host, Integer port, String? registry, String path, String? opaque, String query, String fragment, ?untyped parser, ?bool arg_check) -> URI::Generic',
                      URI::Generic, :new, 'http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?test=1', 'baz'

    assert_send_type  '(String scheme, String userinfo, String host, Integer port, String? registry, String path, String? opaque, String query, String fragment, ?untyped parser, ?bool arg_check) -> URI::Generic',
                      URI::Generic, :new, 'http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?test=1', 'baz', URI::Parser

    assert_send_type  '(String scheme, String userinfo, String host, Integer port, String? registry, String path, String? opaque, String query, String fragment, ?untyped parser, ?bool arg_check) -> URI::Generic',
                      URI::Generic, :new, 'http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?test=1', 'baz', URI::Parser, false
  end

  def test_use_proxy?
    assert_send_type  '(String hostname, String addr, Integer port, String no_proxy) -> bool',
                      URI::Generic, :use_proxy?, 'www.test.com', '1:1:1:1', 80, 'http_proxy'
  end
end

class URIGenericInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing '::URI::Generic'

  def generic
    ::URI::Generic.new('http', 'user:pass', 'localhost', 80, nil, '/foo/bar', nil, '?t=1', '#baz')
  end

  def mail
    ::URI::Generic.new('mailto', nil, nil, nil, nil, nil, 'foo@bar.org', nil, nil)
  end

  def other
    ::URI::Generic.new('https', 'user:pass', 'localhost', 443, nil, '/foo/bar', nil, '?t=1', '#baz')
  end

  def test_schema
    assert_send_type  '() -> String',
                      generic, :scheme
  end

  def test_host
    assert_send_type  '() -> String',
                      generic, :host
  end

  def test_port
    assert_send_type  '() -> Integer',
                      generic, :port
  end

  def test_registry
    assert_send_type  '() -> nil',
                      generic, :registry
  end

  def test_path
    assert_send_type  '() -> String',
                      generic, :path
  end

  def test_query
    assert_send_type  '() -> String',
                      generic, :query
  end

  def test_opaque
    assert_send_type  '() -> String?',
                      generic, :opaque
  end

  def test_fragment
    assert_send_type  '() -> String',
                      generic, :fragment
  end

  def test_replace!
    assert_raises URI::InvalidURIError do
      assert_send_type '(URI::Generic oth) -> URI::Generic',
                        generic, :replace!, other
    end
  end

  def test_component
    assert_send_type  '() -> Array[Symbol]',
                      generic, :component
  end

  def test_check_scheme
    assert_send_type  '(String v) -> true',
                      generic, :check_scheme, 'https'
  end

  def test_set_scheme
    assert_send_type  '(String v) -> String',
                      generic, :set_scheme, 'https'
  end

  def test_scheme=
    assert_send_type  '(String v) -> String',
                      generic, :scheme=, 'https'
  end

  def test_check_userinfo
    assert_send_type  '(String user, ?String? password) -> true',
                      generic, :check_userinfo, 'user'

    assert_send_type  '(String user, ?String? password) -> true',
                      generic, :check_userinfo, 'user', nil

    assert_send_type  '(String user, ?String? password) -> true',
                      generic, :check_userinfo, 'user', 'pass'
  end

  def test_check_user
    assert_send_type  '(String v) -> (String | true)',
                      generic, :check_user, 'user'
  end

  def test_check_password
    assert_send_type  '(String v, ?String user) -> (String | true)',
                      generic, :check_password, 'pass', 'user'
  end

  def test_userinfo=
    omit "userinfo= returns an array, but we want String?"

    assert_send_type  '(String? userinfo) -> Array[String | nil]?',
                      generic, :userinfo=, nil

    assert_send_type  '(String? userinfo) -> Array[String | nil]?',
                      generic, :userinfo=, 'user:pass'
  end

  def test_user=
    assert_send_type  '(String user) -> String',
                      generic, :user=, 'user'
  end

  def test_password=
    assert_send_type  '(String password) -> String',
                      generic, :password=, 'pass'
  end

  def test_set_userinfo
    assert_send_type  '(String user, ?String? password) -> Array[String | nil]',
                      generic, :set_userinfo, 'user', nil

    assert_send_type  '(String user, ?String? password) -> Array[String | nil]',
                      generic, :set_userinfo, 'user', 'pass'
  end

  def test_set_user
    assert_send_type  '(String v) -> String',
                      generic, :set_user, 'user'
  end

  def test_set_password
    assert_send_type  '(String v) -> String',
                      generic, :set_password, 'pass'
  end

  def test_split_userinfo
    assert_send_type  '(String ui) -> Array[String | nil]',
                      generic, :split_userinfo, 'user:pass'
  end

  def test_escape_userpass
    assert_send_type  '(String v) -> String',
                      generic, :escape_userpass, 'user:pass@'
  end

  def test_userinfo
    assert_send_type  '() -> String?',
                      generic, :userinfo

    generic.user = nil

    assert_send_type  '() -> String?',
                      generic, :userinfo
  end

  def test_user
    assert_send_type  '() -> String',
                      generic, :user
  end

  def test_password
    assert_send_type  '() -> String',
                      generic, :password
  end

  def test_check_host
    assert_send_type  '(String v) -> (String | true)',
                      generic, :check_host, 'localhost'
  end

  def test_set_host
    assert_send_type  '(String v) -> String',
                      generic, :set_host, 'localhost'
  end

  def test_host=
    assert_send_type  '(String v) -> String',
                      generic, :host=, 'localhost'
  end

  def test_hostname
    assert_send_type  '() -> String',
                      generic, :hostname
  end

  def test_hostname=
    assert_send_type  '(String v) -> String',
                      generic, :hostname=, 'localhost'
  end

  def test_check_port
    assert_send_type  '(Integer v) -> (Integer | true)',
                      generic, :check_port, 80
  end

  def test_set_port
    assert_send_type  '(Integer v) -> Integer',
                      generic, :set_port, 443
  end

  def test_port=
    assert_send_type  '(Integer v) -> Integer',
                      generic, :port=, 443
  end

  def test_check_registry
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        generic, :check_registry, 'registry'
    end
  end

  def test_set_registry
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        generic, :set_registry, 'registry'
    end
  end

  def test_registry=
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String v) -> nil',
                        generic, :registry=, 'registry'
    end
  end

  def test_check_path
    assert_send_type  '(String) -> true',
                      generic, :check_path, '/abs/path'
  end

  def test_set_path
    assert_send_type  '(String v) -> String',
                      generic, :set_path, '/a/path'
  end

  def test_path=
    assert_send_type  '(String v) -> String',
                      generic, :path=, '/a/path'
  end

  def test_query=
    assert_send_type  '(String v) -> String',
                      generic, :query=, '?some=query'
  end

  def test_check_opaque
    assert_send_type  '(String v) -> (String | true)',
                      mail, :check_opaque, 'opaque'
  end

  def test_set_opaque
    assert_send_type  '(String v) -> String',
                      mail, :set_opaque, 'foo@baz.org'
  end

  def test_opaque=
    assert_send_type  '(String v) -> String',
                      mail, :opaque=, 'foo@baz.org'
  end

  def test_fragment=
    assert_send_type  '(String v) -> String',
                      generic, :fragment=, '#fragment'
  end

  def test_hierarchical?
    assert_send_type  '() -> bool',
                      generic, :hierarchical?
  end

  def test_absolute?
    assert_send_type  '() -> bool',
                      generic, :absolute?
  end

  def test_relative?
    assert_send_type  '() -> bool',
                      generic, :relative?
  end

  def test_split_path
    assert_send_type  '(String path) -> Array[String]',
                      generic, :split_path, 'nested/path'
  end

  def test_merge_path
    assert_send_type  '(String base, String rel) -> String',
                      generic, :merge_path, 'nested', 'path'
  end

  def test_merge
    assert_send_type  '(String oth) -> URI::Generic',
                      generic, :merge, '/extra'
  end

  def test_route_from_path
    assert_send_type  '(String src, String dst) -> String',
                      generic, :route_from_path, 'http://localhost', '/foo/bar'
  end

  def test_route_from0
    assert_send_type  '(String oth) -> Array[URI::Generic]',
                      generic, :route_from0, 'http://localhost'
  end

  def test_route_from
    assert_send_type  '(String oth) -> URI::Generic',
                      generic, :route_from, 'http://localhost'
  end

  def test_route_to
    assert_send_type  '(String oth) -> URI::Generic',
                      generic, :route_to, 'http://localhost/foo/bar'
  end

  def test_to_s
    assert_send_type  '() -> String',
                      generic, :to_s
  end

  def test_equal_equal
    assert_send_type  '(URI::Generic oth) -> bool',
                      generic, :==, mail
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      generic, :hash
  end

  def test_eql?
    assert_send_type  '(URI::Generic oth) -> bool',
                      generic, :eql?, mail
  end

  def test_component_ary
    assert_send_type  '() -> Array[nil | String | Integer]',
                      generic, :component_ary
  end

  def test_select
    assert_send_type  '(*Symbol components) -> Array[nil | String | Integer]',
                      generic, :select, :scheme

    assert_send_type  '(*Symbol components) -> Array[nil | String | Integer]',
                      generic, :select, :scheme, :port

    assert_send_type  '(*Symbol components) -> Array[nil | String | Integer]',
                      generic, :select, :scheme, :port, :registry
  end

  def test_inspect
    assert_send_type  '() -> String',
                      generic, :inspect
  end

  def test_find_proxy
    assert_send_type  '(?String env) -> (nil | URI::Generic)',
                      generic, :find_proxy, 'http_proxy=proxy'
  end
end
