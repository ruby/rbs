require_relative "test_helper"
require "fcntl"

class FcntlConstantsTest < Test::Unit::TestCase
  include TestHelper

  library "fcntl"

  def test_VERSION
    assert_const_type "String", "Fcntl::VERSION"
  end

  def test_O_ACCMODE
    assert_const_type "Integer", "Fcntl::O_ACCMODE"
  end

  def test_fcntl_commands
    assert_fcntl_constants :F_DUPFD, :F_GETFD, :F_GETLK, :F_SETFD, :F_GETFL, :F_SETFL, :F_SETLK, :F_SETLKW, :FD_CLOEXEC
  end

  def test_lock_types
    assert_fcntl_constants :F_RDLCK, :F_UNLCK, :F_WRLCK
  end

  def test_open_flags
    assert_fcntl_constants :O_CREAT, :O_EXCL, :O_NOCTTY, :O_TRUNC, :O_APPEND, :O_NONBLOCK, :O_NDELAY, :O_RDONLY, :O_RDWR, :O_WRONLY
  end

  def test_pipe_size
    assert_fcntl_constants :F_SETPIPE_SZ, :F_GETPIPE_SZ
  end

  def test_dup2fd
    assert_fcntl_constants :F_DUP2FD, :F_DUP2FD_CLOEXEC
  end

  def test_preallocate
    assert_fcntl_constants :F_PREALLOCATE, :F_ALLOCATECONTIG, :F_ALLOCATEALL, :F_ALLOCATEPERSIST, :F_PEOFPOSMODE, :F_VOLPOSMODE
  end

  private

  # Fcntl defines a constant only when the platform's <fcntl.h> does.
  def assert_fcntl_constants(*names)
    defined = names.select { Fcntl.const_defined?(_1, false) }
    omit "#{names.join(", ")} are not defined on this platform" if defined.empty?

    defined.each do |name|
      assert_const_type "Integer", "Fcntl::#{name}"
    end
  end
end
