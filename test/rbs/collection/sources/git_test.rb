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

  def git(*cmd, **opts)
    Bundler.with_unbundled_env do
      Open3.capture3("git", *cmd, **opts).then do |out, err, status|
        raise "Unexpected git status: \n\n#{err.each_line.map {|line| ">> #{line}" }.join}" unless status.success?
        out
      end
    end
  end

  def test_resolved_revision_updated_after_fetch
    Dir.mktmpdir do |dir|
      origin_repo = File.join(dir, "origin_repo")
      Dir.mkdir(origin_repo)
      git "init", chdir: origin_repo
      git "config", "user.email", "you@example.com", chdir: origin_repo
      git "config", "user.name", "Your Name", chdir: origin_repo
      git "checkout", "-b", "main", chdir: origin_repo

      git "commit", "--allow-empty", "-m", "Initial commit", chdir: origin_repo
      sha_initial_commit = git("rev-parse", "HEAD", chdir: origin_repo).chomp

      RBS::Collection::Sources::Git.new(name: "test", revision: "main", remote: origin_repo, repo_dir: "gems").tap do |source|
        assert_equal sha_initial_commit, source.resolved_revision
      end

      git "commit", "--allow-empty", "-m", "Second commit", chdir: origin_repo
      sha_second_commit = git("rev-parse", "HEAD", chdir: origin_repo).chomp

      RBS::Collection::Sources::Git.new(name: "test", revision: "main", remote: origin_repo, repo_dir: "gems").tap do |source|
        assert_equal sha_second_commit, source.resolved_revision
      end
    end
  end
end
