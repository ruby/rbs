require "test_helper"

class RBS::Collection::Sources::GitTest < Test::Unit::TestCase
  def test_has?
    s = source

    assert s.has?('activesupport', nil)
    refute s.has?('activesupport', "1.2.3.4")

    refute s.has?('rbs', nil)

    assert s.has?('protobuf', nil)

    old = source(revision: '41cac76e768cc51485763f92b56d976e8efc96aa')
    refute old.has?('protobuf', nil)
  end

  def test_versions
    s = source
    assert_equal ['2.4'], s.versions('ast')
  end

  def test_manifest_of
    s = source(revision: '45c7e873ce411dea05d7fd276efc71e57291e993')

    assert_instance_of Hash, s.manifest_of('activesupport', '6.0')
    assert_nil s.manifest_of('ast', '2.4')

    assert_raises do
      s.manifest_of('ast', '0.0')
    end
  end

  def source(revision: 'b4d3b346d9657543099a35a1fd20347e75b8c523')
    RBS::Collection::Sources.from_config_entry({
      'name' => 'gem_rbs_collection',
      'revision' => revision,
      'remote' => 'https://github.com/ruby/gem_rbs_collection.git',
      'repo_dir' => 'gems',
    })
  end
end
