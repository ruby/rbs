require "test_helper"

class RBS::Collection::CleanerTest < Test::Unit::TestCase
  def test_install_from_lockfile_1
    mktmpdir do |tmpdir|
      lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
      dest = tmpdir / 'gem_rbs_collection'
      lockfile_path.write(<<~YAML)
        collections:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "#{dest}"
        gems:
          - name: ast
            version: "2.4"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
      YAML

      dest.join('ast/2.4').mkpath
      FileUtils.touch dest.join('ast/2.4/ast.rbs')
      dest.join('rainbow/3.0').mkpath
      FileUtils.touch dest.join('rainbow/3.0/rainbow.rbs')

      RBS::Collection::Cleaner.new(lockfile_path: lockfile_path).clean

      assert dest.join('ast/2.4/ast.rbs').file?
      refute dest.join('rainbow/3.0/rainbow.rbs').file?
    end
  end

  private def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end
end
