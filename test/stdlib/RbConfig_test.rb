require_relative 'test_helper'

class RbConfigSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(::RbConfig)'

  def test_CONFIG
    assert_const_type 'Hash[String, String]',
                      'RbConfig::CONFIG'
  end

  def test_DESTDIR
    assert_const_type 'String',
                      'RbConfig::DESTDIR'
  end

  def test_MAKEFILE_CONFIG
    assert_const_type 'Hash[String, String]',
                      'RbConfig::MAKEFILE_CONFIG'
  end

  def test_TOPDIR
    assert_const_type 'String',
                      'RbConfig::TOPDIR'
  end

  def test_expand
    assert_send_type  '(String) -> String',
                      RbConfig, :expand, 'hello/world'

    assert_send_type  '(String, Hash[String, String]) -> String',
                      RbConfig, :expand, 'hello/world', 'a' => 'b'
  end

  def test_fire_update!
    orig_makefile_config = RbConfig::MAKEFILE_CONFIG.clone
    orig_config = RbConfig::CONFIG.clone

    key, val = RbConfig::MAKEFILE_CONFIG.to_a.first

    # Note: we use `val += '1'` instead of `val.concat '1'`, as `val.concat` would leave the updated
    # key in the config hash, and so you couldn't update it.

    assert_send_type  '(String, String) -> nil',
                      RbConfig, :fire_update!, key, val
    assert_send_type  '(String, String) -> Array[String]',
                      RbConfig, :fire_update!, key, (val += '1')

    assert_send_type  '(String, String, Hash[String, String]) -> nil',
                      RbConfig, :fire_update!, key, val, RbConfig::MAKEFILE_CONFIG
    assert_send_type  '(String, String, Hash[String, String]) -> Array[String]',
                      RbConfig, :fire_update!, key, (val += '1'), RbConfig::MAKEFILE_CONFIG

    assert_send_type  '(String, String, Hash[String, String], Hash[String, String]) -> nil',
                      RbConfig, :fire_update!, key, val, RbConfig::MAKEFILE_CONFIG, RbConfig::CONFIG
    assert_send_type  '(String, String, Hash[String, String], Hash[String, String]) -> Array[String]',
                      RbConfig, :fire_update!, key, (val += '1'), RbConfig::MAKEFILE_CONFIG, RbConfig::CONFIG
  ensure
    RbConfig::MAKEFILE_CONFIG.replace orig_makefile_config
    RbConfig::CONFIG.replace orig_config
  end

  def test_ruby
    assert_send_type  '() -> String',
                      RbConfig, :ruby
  end
end
