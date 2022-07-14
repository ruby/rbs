require "test_helper"

class RBS::Collection::Sources::GitTest < Test::Unit::TestCase
  def test_has?
    s = source

    assert s.has?({ 'name' => 'activesupport' })
    refute s.has?({ 'name' => 'rbs' })

    assert s.has?({ 'name' => 'protobuf' })

    old = source(revision: '41cac76e768cc51485763f92b56d976e8efc96aa')
    refute old.has?({ 'name' => 'protobuf' })
  end

  def test_versions
    s = source
    assert_equal ['2.4'], s.versions({ 'name' => 'ast' })
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
