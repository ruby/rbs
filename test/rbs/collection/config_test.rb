require "test_helper"

# How to test
#
# it generates lockfile from config file, Gemfile.lock, gem_rbs_collection repository
# so the test generate and check the generated lockfile

class RBS::Collection::ConfigTest < Test::Unit::TestCase
  CONFIG = <<~YAML
    collections:
      - name: ruby/gem_rbs_collection
        remote: https://github.com/ruby/gem_rbs_collection.git
        revision: b4d3b346d9657543099a35a1fd20347e75b8c523
        repo_dir: gems

    path: /path/to/somewhare
  YAML

  def test_generate_lock_1
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write CONFIG
      gemfile_lock_path = tmpdir / 'Gemfile.lock'
      gemfile_lock_path.write <<~GEMFILE_LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            ast (2.4.2)
            rainbow (3.0.0)

        PLATFORMS
          x86_64-linux

        DEPENDENCIES
          ast
          rainbow

        BUNDLED WITH
           2.2.0
      GEMFILE_LOCK

      config = RBS::Collection::Config.generate_lockfile(config_path: config_path, gemfile_lock_path: gemfile_lock_path)
      io = StringIO.new
      config.dump_to(io)

      assert_config <<~YAML, io.string
        collections:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhare"
        gems:
          - name: ast
            version: "2.4"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
          - name: rainbow
            version: "3.0"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
      YAML
    end
  end

  def test_generate_lock_with_empty_gemfile_lock
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write CONFIG
      gemfile_lock_path = tmpdir / 'Gemfile.lock'
      gemfile_lock_path.write <<~GEMFILE_LOCK
        GEM
          remote: https://rubygems.org/
          specs:

        PLATFORMS
          x86_64-linux

        DEPENDENCIES

        BUNDLED WITH
           2.2.0
      GEMFILE_LOCK

      config = RBS::Collection::Config.generate_lockfile(config_path: config_path, gemfile_lock_path: gemfile_lock_path)
      io = StringIO.new
      config.dump_to(io)

      assert_config <<~YAML, io.string
        collections:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhare"
      YAML
    end
  end

  private def assert_config(expected_str, actual_str)
    assert_equal YAML.load(expected_str), YAML.load(actual_str)
  end

  private def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end
end
