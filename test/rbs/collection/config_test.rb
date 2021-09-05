require "test_helper"

# How to test
#
# it generates lockfile from config file, Gemfile.lock, gem_rbs_collection repository
# so the test generate and check the generated lockfile

class RBS::Collection::ConfigTest < Test::Unit::TestCase
  include TestHelper

  CONFIG = <<~YAML
    sources:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            source:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            source:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: rainbow
            ignore: false
            version: "3.0"
            source:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: ast
            version: "2.4"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            source:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: csv
            version: "0"
            source:
              type: stdlib
      YAML
    end
  end

  def test_generate_lock_from_rubygems
    omit unless has_gem?("rbs-amber")

    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write CONFIG
      gemfile_lock_path = tmpdir / 'Gemfile.lock'
      gemfile_lock_path.write <<~GEMFILE_LOCK
        GEM
          remote: https://rubygems.org/
          specs:
            rbs-amber (1.0.0)

        PLATFORMS
          x86_64-linux

        DEPENDENCIES
          rbs-amber

        BUNDLED WITH
           2.2.0
      GEMFILE_LOCK

      config = RBS::Collection::Config.generate_lockfile(config_path: config_path, gemfile_lock_path: gemfile_lock_path)
      io = StringIO.new
      config.dump_to(io)

      assert_config <<~YAML, io.string
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems:
          - name: rbs-amber
            version: "1.0.0"
            source:
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
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "/path/to/somewhere"
        gems: []
      YAML
    end
  end

  def test_repo_path
    mktmpdir do |tmpdir|
      config_path = tmpdir / 'rbs_collection.yaml'
      config_path.write <<~YAML
        sources: []
        path: '.gem_rbs_collection'
      YAML

      config = RBS::Collection::Config.from_path(config_path)

      assert config.repo_path.absolute?
      assert_equal tmpdir.join('.gem_rbs_collection'), config.repo_path
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
