require_relative "test_helper"

require "etc"

class EtcSingletonTest < Test::Unit::TestCase
  include TestHelper

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

class EtcGroupSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "etc"
  testing "singleton(::Etc::Group)"

  def test_each
    assert_send_type  "() { (::Etc::Group) -> void } -> singleton(::Etc::Group)",
                      Etc::Group, :each do |_g| end
    assert_send_type  "() -> ::Enumerator[::Etc::Group]",
                      Etc::Group, :each
  end
end

class EtcPasswdSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "etc"
  testing "singleton(::Etc::Passwd)"

  def test_each
    assert_send_type  "() { (::Etc::Passwd) -> void } -> singleton(::Etc::Passwd)",
                      Etc::Passwd, :each do |_u| end
    assert_send_type  "() -> ::Enumerator[::Etc::Passwd]",
                      Etc::Passwd, :each
  end
end

class EtcPasswdInstanceTest < Test::Unit::TestCase
  include TestHelper

  library "etc"
  testing "::Etc::Passwd"

  def test_age
    omit "no age member on this platform" unless Etc::Passwd.members.include?(:age)
    pw = Etc.getpwuid

    assert_send_type  "() -> ::Integer",
                      pw, :age
    assert_send_type  "(::Integer) -> void",
                      pw, :age=, pw.age
  end

  def test_comment
    omit "no comment member on this platform" unless Etc::Passwd.members.include?(:comment)
    pw = Etc.getpwuid

    assert_send_type  "() -> ::String",
                      pw, :comment
    assert_send_type  "(::String) -> void",
                      pw, :comment=, pw.comment
  end

  def test_quota
    omit "no quota member on this platform" unless Etc::Passwd.members.include?(:quota)
    pw = Etc.getpwuid

    assert_send_type  "() -> ::Integer",
                      pw, :quota
    assert_send_type  "(::Integer) -> void",
                      pw, :quota=, pw.quota
  end
end
