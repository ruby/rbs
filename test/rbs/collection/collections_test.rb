require "test_helper"

class RBS::CollectionCollectionsGitTest < Test::Unit::TestCase
  def test_has?
    c = collection

    assert c.has?({ 'name' => 'activesupport' })
    refute c.has?({ 'name' => 'rbs' })

    assert c.has?({ 'name' => 'protobuf' })

    old = collection(revision: '41cac76e768cc51485763f92b56d976e8efc96aa')
    refute old.has?({ 'name' => 'protobuf' })
  end

  def test_versions
    c = collection
    assert_equal ['2.4'], c.versions({ 'name' => 'ast' })
  end

  def collection(revision: 'b4d3b346d9657543099a35a1fd20347e75b8c523')
    RBS::Collection::Collections.from_config_entry({
      'name' => 'gem_rbs_collection',
      'revision' => revision,
      'remote' => 'https://github.com/ruby/gem_rbs_collection.git',
      'repo_dir' => 'gems',
    })
  end
end
