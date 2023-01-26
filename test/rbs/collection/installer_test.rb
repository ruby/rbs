require "test_helper"

class RBS::Collection::InstallerTest < Test::Unit::TestCase
  include TestHelper

  def test_install_from_git
    mktmpdir do |tmpdir|
      lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
      dest = tmpdir / 'gem_rbs_collection'
      lockfile_path.write(<<~YAML)
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "#{dest}"
        gems:
          - name: ast
            version: "2.4"
            source:
              type: git
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
          - name: rainbow
            version: "3.0"
            source:
              type: git
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
          - name: activerecord # To test symlink
            version: "6.1"
            source:
              type: git
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: 51880bed87fbc3dc8076fedb5cf798be05148220
              repo_dir: gems
      YAML

      stdout = StringIO.new
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

      assert dest.join('ast/2.4/ast.rbs').file?
      assert dest.join('rainbow/3.0/rainbow.rbs').file?
      assert dest.join('activerecord/6.1/activerecord-6.1.rbs').file?
      assert dest.join('activerecord/6.1/activerecord.rbs').file?

      refute dest.join('ast/2.4/_test').exist?
      refute dest.join('rainbow/3.0/_src').exist?
      refute dest.join('activerecord/6.1/_test').exist?

      assert_match('Installing ast:2.4 (ast@b4d3b346d96)', stdout.string)
      assert_match('Installing rainbow:3.0 (rainbow@b4d3b346d96)', stdout.string)
      assert_match('Installing activerecord:6.1 (activerecord@51880bed87f)', stdout.string)
      assert_match("It's done! 3 gems' RBSs now installed.", stdout.string)
    end
  end

  def test_install_from_stdlib
    mktmpdir do |tmpdir|
      lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
      dest = tmpdir / 'gem_rbs_collection'
      lockfile_path.write(<<~YAML)
        sources: []
        path: "#{dest}"
        gems:
          - name: csv
            version: "0"
            source:
              type: stdlib
      YAML

      stdout = StringIO.new
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

      assert dest.directory?
      assert dest.glob('*').empty? # because stdlib installer does nothing
      assert_match(%r!Using csv:0 \(.+/stdlib/csv/0\)!, stdout.string)
      assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
    end
  end

  def test_install_from_gem_sig_dir
    omit unless has_gem?("rbs-amber")

    mktmpdir do |tmpdir|
      lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
      dest = tmpdir / 'gem_rbs_collection'
      lockfile_path.write(<<~YAML)
        sources: []
        path: "#{dest}"
        gems:
          - name: rbs-amber
            version: "1.0.0"
            source:
              type: rubygems
      YAML

      stdout = StringIO.new
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

      assert dest.directory?
      assert dest.glob('*').empty? # because rubygems installer does nothing
      assert_match(%r!Using rbs-amber:1.0.0 \(.+/rbs/test/assets/test-gem/sig\)!, stdout.string)
      assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
    end
  end

  def test_install_from_local
    mktmpdir do |tmpdir|
      with_local_source do |local_source|
        lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
        dest = tmpdir / 'gem_rbs_collection'
        lockfile_path.write(<<~YAML)
          sources:
            - type: local
              name: the local source
              path: "#{local_source}"
          path: "#{dest}"
          gems:
            - name: super-cool-gem
              version: "0.1"
              source:
                type: local
                name: the local source
                path: "#{local_source}"
        YAML

        # Check installing
        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

        assert dest.glob('*/').size == 1
        assert dest.join('super-cool-gem/0.1').symlink?
        assert dest.join('super-cool-gem/0.1/super-cool-gem.rbs').file?

        assert_match("Installing super-cool-gem:0.1 (#{local_source.join("super-cool-gem/0.1")})", stdout.string)
        assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)

        # Check idempotency
        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

        assert_match("Using super-cool-gem:0.1 (#{local_source.join("super-cool-gem/0.1")})", stdout.string)

        # Check updating
        lockfile_path.write lockfile_path.read.sub('version: "0.1"', 'version: "0.42"')
        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

        assert dest.glob('*/').size == 1
        assert dest.join('super-cool-gem/0.42').symlink?
        assert dest.join('super-cool-gem/0.42/super-cool-gem.rbs').file?

        assert_match("Installing super-cool-gem:0.42 (#{local_source.join("super-cool-gem/0.42")})", stdout.string)
        assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
      end
    end
  end

  def test_update_from_git_to_local
    mktmpdir do |tmpdir|
      lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
      dest = tmpdir / 'gem_rbs_collection'
      lockfile_path.write(<<~YAML)
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: "#{dest}"
        gems:
          - name: ast
            version: "2.4"
            source:
              type: git
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
      YAML

      # Preparation by installing RBSs from git source
      stdout = StringIO.new
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile
      assert dest.join('ast/2.4/ast.rbs').file?

      # Install from local source
      with_local_source do |local_source|
        lockfile_path.write(<<~YAML)
          sources:
            - type: local
              name: the local source
              path: "#{local_source}"
          path: "#{dest}"
          gems:
            - name: ast
              version: "2.4"
              source:
                type: local
                name: the local source
                path: "#{local_source}"
        YAML

        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

        assert dest.glob('*/').size == 1
        assert dest.join('ast/2.4').symlink?
        assert dest.join('ast/2.4/ast.rbs').file?

        assert_match("Updating ast:2.4 from git source", stdout.string)
        assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
      end
    end
  end

  def test_update_from_local_to_git
    mktmpdir do |tmpdir|
      with_local_source do |local_source|
        lockfile_path = tmpdir.join('rbs_collection.lock.yaml')
        dest = tmpdir / 'gem_rbs_collection'
        lockfile_path.write(<<~YAML)
          sources:
            - type: local
              name: the local source
              path: "#{local_source}"
          path: "#{dest}"
          gems:
            - name: ast
              version: "2.4"
              source:
                type: local
                name: the local source
                path: "#{local_source}"
        YAML

        # Preparation by installing RBSs from local source
        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile
        assert dest.join('ast/2.4/ast.rbs').file?

        # Install from git source
        lockfile_path.write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
          path: "#{dest}"
          gems:
            - name: ast
              version: "2.4"
              source:
                type: git
                name: ruby/gem_rbs_collection
                remote: https://github.com/ruby/gem_rbs_collection.git
                revision: b4d3b346d9657543099a35a1fd20347e75b8c523
                repo_dir: gems
        YAML

        stdout = StringIO.new
        RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

        assert dest.glob('*/').size == 1
        refute dest.join('ast/2.4').symlink?
        assert dest.join('ast/2.4/ast.rbs').file?

        assert_match("Updating to ast:2.4 (ast@b4d3b346d96) from a local source", stdout.string)
        assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
      end
    end
  end

  private def with_local_source
    mktmpdir do |path|
      path.join('super-cool-gem/0.1').tap do |dir|
        dir.mkpath
        dir.join('super-cool-gem.rbs').write('class SuperCoolGem end')
      end
      path.join('super-cool-gem/0.42').tap do |dir|
        dir.mkpath
        dir.join('super-cool-gem.rbs').write('class SuperCoolGem end')
      end
      path.join('ast/2.4').tap do |dir|
        dir.mkpath
        dir.join('ast.rbs').write('class Ast end')
      end

      yield path
    end
  end

  private def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end
end
