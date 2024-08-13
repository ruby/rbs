require "test_helper"

class RBS::FileFinderTest < Test::Unit::TestCase
  FileFinder = RBS::FileFinder

  def tmpdir
    @tmpdir
  end

  def setup
    super

    @tmpdir = Pathname(Dir.mktmpdir)

    (tmpdir / "sig").mkpath
    (tmpdir / "sig/app").mkpath
    (tmpdir / "sig/_internal/foo").mkpath
    (tmpdir / "_private/app").mkpath
    (tmpdir / "_private/_internal").mkpath

    (tmpdir / "top").write("")
    (tmpdir / "sig/a.rbs").write("")
    (tmpdir / "sig/b.rbs").write("")
    (tmpdir / "sig/_internal/foo/bar.rbs").write("")
    (tmpdir / "_private/app/x.rbs").write("")
    (tmpdir / "_private/_internal/y.rbs").write("")
  end

  def teardown
    tmpdir.rmtree
  end

  def test_file_path
    assert_equal [tmpdir + "sig/a.rbs"], FileFinder.each_file(tmpdir + "sig/a.rbs", skip_hidden: false).to_a
    assert_equal [tmpdir + "sig/a.rbs"], FileFinder.each_file(tmpdir + "sig/a.rbs", skip_hidden: false).to_a

    assert_equal [tmpdir + "top"], FileFinder.each_file(tmpdir + "top", skip_hidden: false).to_a
  end

  def test_dir_path
    assert_equal [tmpdir + "sig/a.rbs", tmpdir + "sig/b.rbs"], FileFinder.each_file(tmpdir + "sig", skip_hidden: true).to_a
    assert_equal [tmpdir + "sig/_internal/foo/bar.rbs", tmpdir + "sig/a.rbs", tmpdir + "sig/b.rbs"], FileFinder.each_file(tmpdir + "sig", skip_hidden: false).to_a

    assert_equal [tmpdir + "_private/app/x.rbs"], FileFinder.each_file(tmpdir + "_private", skip_hidden: true).to_a
    assert_equal [tmpdir + "_private/_internal/y.rbs", tmpdir + "_private/app/x.rbs"], FileFinder.each_file(tmpdir + "_private", skip_hidden: false).to_a
  end
end
