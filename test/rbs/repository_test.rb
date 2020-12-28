require "test_helper"

class RBS::RepositoryTest < Test::Unit::TestCase
  Repository = RBS::Repository

  def dir
    @dir
  end

  def dir2
    @dir2
  end

  def setup
    super

    @dir = Pathname(Dir.mktmpdir).tap do |dir|
      gem1 = dir + "gem1"
      gem1.mkdir
      (gem1 + "0.1.0").mkdir
      (gem1 + "0.3.0").mkdir
      (gem1 + "1.0.0").mkdir

      gem2 = dir + "gem2"
      gem2.mkdir
      (gem2 + "invalid version name").mkdir
    end

    @dir2 = Pathname(Dir.mktmpdir).tap do |dir|
      gem1 = dir + "gem1"
      gem1.mkdir
      (gem1 + "0.3.1").mkdir
      (gem1 + "1.0.0").mkdir
    end
  end

  def teardown
    FileUtils.remove_entry(@dir.to_s)
    FileUtils.remove_entry(@dir2.to_s)
  end

  def test_repository_stdlib
    repo = Repository.new

    refute_nil repo.lookup("set", nil)
  end

  def test_repository
    repo = Repository.new(no_stdlib: true)
    repo.add(dir)

    assert_equal Set["gem1", "gem2"], Set.new(repo.gems.keys)

    assert_equal Pathname("1.0.0"), repo.lookup("gem1", nil).basename
    assert_equal Pathname("0.1.0"), repo.lookup("gem1", "0.0.2").basename
    assert_equal Pathname("0.1.0"), repo.lookup("gem1", "0.2.0").basename
    assert_equal Pathname("0.3.0"), repo.lookup("gem1", "0.3.0").basename
    assert_equal Pathname("0.3.0"), repo.lookup("gem1", "0.3.3").basename
    assert_equal Pathname("1.0.0"), repo.lookup("gem1", "1.3.2").basename

    assert_nil repo.lookup("gem2", nil)

    assert_nil repo.lookup("no-such-gem", nil)
  end

  def test_repo_overwrite
    repo = Repository.new()
    repo.add(dir)
    repo.add(dir2)

    # Lookup versions from both of dirs.
    assert_equal Pathname("1.0.0"), repo.lookup("gem1", nil).basename
    assert_equal Pathname("0.1.0"), repo.lookup("gem1", "0.0.2").basename
    assert_equal Pathname("0.1.0"), repo.lookup("gem1", "0.2.0").basename
    assert_equal Pathname("0.3.0"), repo.lookup("gem1", "0.3.0").basename
    assert_equal Pathname("0.3.1"), repo.lookup("gem1", "0.3.3").basename
    assert_equal Pathname("1.0.0"), repo.lookup("gem1", "1.3.2").basename

    # Latter dir wins.
    assert_equal (dir2 + "gem1/1.0.0"), repo.lookup("gem1", "1.0.0")
  end
end
