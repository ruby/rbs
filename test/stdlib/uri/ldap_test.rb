require_relative '../test_helper'
require 'uri'

class URILDAPSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing 'singleton(::URI::LDAP)'

  def test_build
    assert_send_type '(Array[nil | String | Integer] args) -> URI::LDAP',
                      URI::LDAP, :build,
                      [
                        'ldap.example.com',
                        80,
                        '/dc=example;dc=com',
                        'foo,bar,baz',
                        'sub',
                        '(t=1)',
                        't=2'
                      ]

    assert_send_type '({ host: String, port: Integer?, dn: String, attributes: String?, scope: String?, filter: String?, extensions: String? }) -> URI::LDAP',
                      URI::LDAP, :build,
                      {
                        host: 'ldap.example.com',
                        port: 80,
                        dn: '/dc=example;dc=com',
                        attributes: 'foo,bar,baz',
                        scope: 'sub',
                        filter: '(t=1)',
                        extensions: 't=2'
                      }

    assert_send_type '({ host: nil, port: nil, dn: nil, attributes: nil, scope: nil, filter: nil, extensions: nil }) -> URI::LDAP',
                      URI::LDAP, :build,
                      {
                        host: nil,
                        port: nil,
                        dn: nil,
                        attributes: nil,
                        scope: nil,
                        filter: nil,
                        extensions: nil
                      }
  end

  def test_new
    # fragment is passed
    assert_raises URI::InvalidURIError do
      assert_send_type  '(String schema, String? userinfo, String host, Integer? port, String? registry, String? path, String? opaque, String query, String? fragment) -> URI::LDAP',
                        URI::LDAP, :new, 'ldap', nil, 'ldap.example.com', 80, nil, '/dc=example;dc=com?foo,bar,baz?sub?(t=1)?t=2', nil, 'query', 'foo'
    end

    # fragment is missing
    assert_send_type  '(String schema, String? userinfo, String host, Integer? port, String? registry, String? path, String? opaque, String query, String? fragment) -> URI::LDAP',
                      URI::LDAP, :new, 'ldap', nil, 'ldap.example.com', 80, nil, '/dc=example;dc=com?foo,bar,baz?sub?(t=1)?t=2', nil, 'query', nil
  end
end

class URILDAPInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'uri'
  testing '::URI::LDAP'

  def ldap
    ::URI::LDAP.build(
      [
        'ldap.example.com',
        80,
        '/dc=example;dc=com',
        'foo,bar,baz',
        'sub',
        '(t=1)',
        't=2'
      ]
    )
  end

  def test_build_path_query
    assert_send_type  '() -> String',
                      ldap, :build_path_query
  end

  def test_dn
    assert_send_type  '() -> String',
                      ldap, :dn
  end

  def test_set_dn
    assert_send_type  '(String val) -> String',
                      ldap, :set_dn, '?(t=2)'
  end

  def test_dn=
    assert_send_type  '(String val) -> String',
                      ldap, :dn=, '?(t=2)'
  end

  def test_attributes
    assert_send_type  '() -> String',
                      ldap, :attributes
  end

  def test_set_attributes
    assert_send_type  '(String val) -> String',
                      ldap, :set_attributes, '?(t=2)'
  end

  def test_attributes=
    assert_send_type  '(String val) -> String',
                      ldap, :attributes=, '?(t=2)'
  end

  def test_scope
    assert_send_type  '() -> String',
                      ldap, :scope
  end

  def test_set_scope
    assert_send_type  '(String val) -> String',
                      ldap, :set_scope, '?(t=2)'
  end

  def test_scope=
    assert_send_type  '(String val) -> String',
                      ldap, :scope=, '?(t=2)'
  end

  def test_filter
    assert_send_type  '() -> String',
                      ldap, :filter
  end

  def test_set_filter
    assert_send_type  '(String val) -> String',
                      ldap, :set_filter, '?(t=2)'
  end

  def test_filter=
    assert_send_type  '(String val) -> String',
                      ldap, :filter=, '?(t=2)'
  end

  def test_extensions
    assert_send_type  '() -> String',
                      ldap, :extensions
  end

  def test_set_extensions
    assert_send_type  '(String val) -> String',
                      ldap, :set_extensions, 't=3'
  end

  def test_extensions=
    assert_send_type  '(String val) -> String',
                      ldap, :extensions=, 't=3'
  end

  def test_hierarchical?
    assert_send_type  '() -> ::FalseClass',
                      ldap, :hierarchical?
  end
end
