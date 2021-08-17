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

    path: /path/to/somewhere
  YAML

  def test_generate_lock_from_collection_repository
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
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
    end
  end

  def test_generate_lock_from_collection_repository_with_lockfile
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

      lockfile = <<~YAML
        collections:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
      tmpdir.join('rbs_collection.lock.yaml').write lockfile

      config = RBS::Collection::Config.generate_lockfile(config_path: config_path, gemfile_lock_path: gemfile_lock_path)
      io = StringIO.new
      config.dump_to(io)

      assert_config lockfile, io.string
    end
  end

  def test_generate_lock_from_collection_repository_ignoring
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write [CONFIG, <<~YAML].join("\n")
        gems:
          - name: ast
            ignore: true
          - name: rainbow
            ignore: false
      YAML
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
        path: "/path/to/somewhere"
        gems:
          - name: rainbow
            ignore: false
            version: "3.0"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
    end
  end

  def test_generate_lock_from_collection_repository_specified
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write [CONFIG, <<~YAML].join("\n")
        gems:
          - name: ast
          - name: rainbow
      YAML
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
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            collection:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
    end
  end

  def test_generate_lock_from_stdlib
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write CONFIG
      gemfile_lock_path = tmpdir / 'Gemfile.lock'
      gemfile_lock_path.write <<~GEMFILE_LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            csv (3.2.0)

        PLATFORMS
          x86_64-linux

        DEPENDENCIES
          csv

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
        path: "/path/to/somewhere"
        gems:
          - name: csv
            version: "0"
            collection:
              type: stdlib
      YAML
    end
  end

  def test_generate_lock_from_rubygems
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write CONFIG
      gemfile_lock_path = tmpdir / 'Gemfile.lock'
      gemfile_lock_path.write <<~GEMFILE_LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            strong_json (2.1.2)

        PLATFORMS
          x86_64-linux

        DEPENDENCIES
          strong_json

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
        path: "/path/to/somewhere"
        gems:
          - name: strong_json
            version: "2.1.2"
            collection:
              type: rubygems
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
        path: "/path/to/somewhere"
        gems: []
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
