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
      YAML

      stdout = StringIO.new
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: stdout).install_from_lockfile

      assert dest.join('ast/2.4/ast.rbs').file?
      assert dest.join('rainbow/3.0/rainbow.rbs').file?
      assert_match('Installing ast:2.4 (ast@b4d3b346d96)', stdout.string)
      assert_match('Installing rainbow:3.0 (rainbow@b4d3b346d96)', stdout.string)
      assert_match("It's done! 2 gems' RBSs now installed.", stdout.string)
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

      assert dest.glob('*').empty? # because rubygems installer does nothing
      assert_match(%r!Using rbs-amber:1.0.0 \(.+/rbs/test/assets/test-gem/sig\)!, stdout.string)
      assert_match("It's done! 1 gems' RBSs now installed.", stdout.string)
    end
  end

  private def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end
end
