require "test_helper"

class RBS::Collection::Sources::StdlibTest < Test::Unit::TestCase
  def test_has?
    s = source

    assert s.has?('base64', nil)
    refute s.has?('activesupport', nil)
    refute s.has?('rbs', nil)
  end

  def test_versions
    s = source
    assert_equal ['0'], s.versions('base64')
  end

  def test_manifest_of__exist
    s = source
    assert_equal({ 'dependencies' => [{ 'name' => 'dbm'}, { 'name' => 'pstore'}] },
                 s.manifest_of('psych', '0'))
  end

  def test_manifest_of__nonexist
    s = source
    assert_equal(nil, s.manifest_of('base64', '0'))
  end

  def source
    RBS::Collection::Sources.from_config_entry({
      'type' => 'stdlib',
    }, base_directory: nil)
  end
end
