require_relative "test_helper"

require "etc"

class EtcSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "etc"
  testing "singleton(::Etc)"

  def test_confstr
    assert_send_type  "(::Integer) -> ::String?",
                      Etc, :confstr, Etc::CS_PATH
  end

  def test_endgrent
    assert_send_type  "() -> void",
                      Etc, :endgrent
  end

  def test_endpwent
    assert_send_type  "() -> void",
                      Etc, :endpwent
  end

  def test_getgrent
    assert_send_type  "() -> ::Etc::Group?",
                      Etc, :getgrent
  end

  def test_getgrgid
    assert_send_type  "() -> ::Etc::Group",
                      Etc, :getgrgid
    assert_send_type  "(::Integer) -> ::Etc::Group",
                      Etc, :getgrgid, Etc.getgrgid.gid
  end

  def test_getgrnam
    assert_send_type  "(::String) -> ::Etc::Group",
                      Etc, :getgrnam, Etc.getgrgid.name
  end

  def test_getlogin
    assert_send_type  "() -> ::String?",
                      Etc, :getlogin
  end

  def test_getpwent
    assert_send_type  "() -> ::Etc::Passwd?",
                      Etc, :getpwent
  end

  def test_getpwnam
    assert_send_type  "(::String) -> ::Etc::Passwd",
                      Etc, :getpwnam, Etc.getpwuid.name
  end

  def test_getpwuid
    assert_send_type  "() -> ::Etc::Passwd",
                      Etc, :getpwuid
    assert_send_type  "(::Integer) -> ::Etc::Passwd",
                      Etc, :getpwuid, Etc.getpwuid.uid
  end

  def test_group
    assert_send_type  "() { (::Etc::Group) -> void } -> void",
                      Etc, :group do end
    assert_send_type  "() -> ::Etc::Group?",
                      Etc, :group
  end

  def test_nprocessors
    assert_send_type  "() -> ::Integer",
                      Etc, :nprocessors
  end

  def test_passwd
    assert_send_type  "() { (::Etc::Passwd) -> void } -> void",
                      Etc, :passwd do end
    assert_send_type  "() -> ::Etc::Passwd?",
                      Etc, :passwd
  end

  def test_setgrent
    assert_send_type  "() -> void",
                      Etc, :setgrent
  end

  def test_setpwent
    assert_send_type  "() -> void",
                      Etc, :setpwent
  end

  def test_sysconf
    assert_send_type  "(::Integer) -> ::Integer",
                      Etc, :sysconf, Etc::SC_ARG_MAX
  end

  def test_sysconfdir
    assert_send_type  "() -> ::String",
                      Etc, :sysconfdir
  end

  def test_systmpdir
    assert_send_type  "() -> ::String",
                      Etc, :systmpdir
  end

  def test_uname
    assert_send_type  "() -> { sysname: ::String, nodename: ::String, release: ::String, version: ::String, machine: ::String }",
                      Etc, :uname
  end
end
