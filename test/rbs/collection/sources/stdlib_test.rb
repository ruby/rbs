require "test_helper"

class RBS::Collection::Sources::StdlibTest < Test::Unit::TestCase
  Manifest = RBS::Collection::Manifest

  def test_has?
    s = source

    assert s.has?({ 'name' => 'pathname' })
    refute s.has?({ 'name' => 'activesupport' })
    refute s.has?({ 'name' => 'rbs' })
  end

  def test_versions
    s = source
    assert_equal ['0'], s.versions({ 'name' => 'pathname' })
  end

  def test_manifest_of__exist
    s = source
    assert_equal(
      Manifest.new(
        Pathname("yaml/0/manifest.yaml"),
        dependencies: [
          Manifest::Dependency.new(name: "dbm"),
          Manifest::Dependency.new(name: "pstore"),
        ]
      ),
      s.manifest_of({ 'name' => 'yaml', 'version' => '0' })
    )
  end

  def test_manifest_of__nonexist
    s = source
    assert_equal(nil, s.manifest_of({ 'name' => 'pathname', 'version' => '0' }))
  end

  def source
    RBS::Collection::Sources.from_config_entry({
      'type' => 'stdlib',
    })
  end
end
