require_relative "test_helper"

class FileCosntantsSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::File::Constants)"

  def test_const_RDONLY
    assert_const_type 'Integer',
                      'File::Constants::RDONLY'
  end

  def test_const_WRONLY
    assert_const_type 'Integer',
                      'File::Constants::WRONLY'
  end

  def test_const_RDWR
    assert_const_type 'Integer',
                      'File::Constants::RDWR'
  end

  def test_const_APPEND
    assert_const_type 'Integer',
                      'File::Constants::APPEND'
  end

  def test_const_CREAT
    assert_const_type 'Integer',
                      'File::Constants::CREAT'
  end

  def test_const_EXCL
    assert_const_type 'Integer',
                      'File::Constants::EXCL'
  end

  def test_const_NONBLOCK
    omit 'NONBLOCK not defined' unless defined? File::Constants::NONBLOCK

    assert_const_type 'Integer',
                      'File::Constants::NONBLOCK'
  end

  def test_const_TRUNC
    assert_const_type 'Integer',
                      'File::Constants::TRUNC'
  end

  def test_const_NOCTTY
    omit 'NOCTTY not defined' unless defined? File::Constants::NOCTTY

    assert_const_type 'Integer',
                      'File::Constants::NOCTTY'
  end

  def test_const_BINARY
    assert_const_type 'Integer',
                      'File::Constants::BINARY'
  end

  def test_const_SHARE_DELETE
    assert_const_type 'Integer',
                      'File::Constants::SHARE_DELETE'
  end

  def test_const_SYNC
    omit 'SYNC not defined' unless defined? File::Constants::SYNC

    assert_const_type 'Integer',
                      'File::Constants::SYNC'
  end

  def test_const_DSYNC
    omit 'DSYNC not defined' unless defined? File::Constants::DSYNC

    assert_const_type 'Integer',
                      'File::Constants::DSYNC'
  end

  def test_const_RSYNC
    omit 'RSYNC not defined' unless defined? File::Constants::RSYNC

    assert_const_type 'Integer',
                      'File::Constants::RSYNC'
  end

  def test_const_NOFOLLOW
    omit 'NOFOLLOW not defined' unless defined? File::Constants::NOFOLLOW

    assert_const_type 'Integer',
                      'File::Constants::NOFOLLOW'
  end

  def test_const_NOATIME
    omit 'NOATIME not defined' unless defined? File::Constants::NOATIME

    assert_const_type 'Integer',
                      'File::Constants::NOATIME'
  end

  def test_const_DIRECT
    omit 'DIRECT not defined' unless defined? File::Constants::DIRECT

    assert_const_type 'Integer',
                      'File::Constants::DIRECT'
  end

  def test_const_TMPFILE
    omit 'TMPFILE not defined' unless defined? File::Constants::TMPFILE

    assert_const_type 'Integer',
                      'File::Constants::TMPFILE'
  end

  def test_const_LOCK_SH
    assert_const_type 'Integer',
                      'File::Constants::LOCK_SH'
  end

  def test_const_LOCK_EX
    assert_const_type 'Integer',
                      'File::Constants::LOCK_EX'
  end

  def test_const_LOCK_UN
    assert_const_type 'Integer',
                      'File::Constants::LOCK_UN'
  end

  def test_const_LOCK_NB
    assert_const_type 'Integer',
                      'File::Constants::LOCK_NB'
  end

  def test_const_NULL
    assert_const_type 'String',
                      'File::Constants::NULL'
  end
end
