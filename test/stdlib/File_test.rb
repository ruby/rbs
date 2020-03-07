require_relative "test_helper"
require "ruby/signature/test/test_helper"

class FileSingletonTest < Minitest::Test
  include Ruby::Signature::Test::TypeAssertions

  testing "singleton(::File)"

  def test_absolute_path
    assert_send_type "(String) -> String",
                     File, :absolute_path, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :absolute_path, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :absolute_path, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :absolute_path, __FILE__, __dir__
    assert_send_type "(String, ToStr) -> String",
                     File, :absolute_path, __FILE__, ToStr.new(__dir__)
    assert_send_type "(String, ToPath) -> String",
                     File, :absolute_path, __FILE__, ToPath.new(__dir__)
  end

  def test_absolute_path?
    assert_send_type "(String) -> bool",
                     File, :absolute_path?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :absolute_path?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :absolute_path?, ToPath.new(__FILE__)
  end

  def test_atime
    assert_send_type "(String) -> Time",
                     File, :atime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :atime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :atime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :atime, IO.new(IO.sysopen(__FILE__))
  end

  def test_basename
    assert_send_type "(String) -> String",
                     File, :basename, __FILE__
    assert_send_type "(ToStr) -> String",
                     File, :basename, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> String",
                     File, :basename, ToPath.new(__FILE__)
    assert_send_type "(String, String) -> String",
                     File, :basename, __FILE__, '.rb'
    assert_send_type "(String, ToStr) -> String",
                     File, :basename, __FILE__, ToStr.new('.rb')
  end

  def test_birthtime
    assert_send_type "(String) -> Time",
                     File, :birthtime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :birthtime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :birthtime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :birthtime, IO.new(IO.sysopen(__FILE__))
  end

  def test_blockdev?
    assert_send_type "(String) -> bool",
                     File, :blockdev?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :blockdev?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :blockdev?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :blockdev?, IO.new(IO.sysopen(__FILE__))
  end

  def test_chardev?
    assert_send_type "(String) -> bool",
                     File, :chardev?, __FILE__
    assert_send_type "(ToStr) -> bool",
                     File, :chardev?, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> bool",
                     File, :chardev?, ToPath.new(__FILE__)
    assert_send_type "(IO) -> bool",
                     File, :chardev?, IO.new(IO.sysopen(__FILE__))
  end

  def test_chmod
    Dir.mktmpdir do |dir|
      File.open("#{dir}/chmod", "w"){}
      assert_send_type "(Integer, String) -> Integer",
                       File, :chmod, 0644, "#{dir}/chmod"
      assert_send_type "(ToInt, String) -> Integer",
                      File, :chmod, ToInt.new(0644), "#{dir}/chmod"
      assert_send_type "(Integer, ToStr) -> Integer",
                      File, :chmod, 0644, ToStr.new("#{dir}/chmod")
      assert_send_type "(Integer, ToPath) -> Integer",
                      File, :chmod, 0644, ToPath.new("#{dir}/chmod")
      assert_send_type "(Integer, String, String) -> Integer",
                      File, :chmod, 0644, "#{dir}/chmod", "#{dir}/chmod"
    end
  end

  def test_chown
    assert_send_type "(Integer, Integer, String) -> Integer",
                     File, :chown, Process.uid, Process.gid, __FILE__
    assert_send_type "(ToInt, Integer, String) -> Integer",
                     File, :chown, ToInt.new(Process.uid), Process.gid, __FILE__
    assert_send_type "(nil, Integer, String) -> Integer",
                     File, :chown, nil, Process.gid, __FILE__
    assert_send_type "(Integer, ToInt, String) -> Integer",
                     File, :chown, Process.uid, ToInt.new(Process.gid), __FILE__
    assert_send_type "(Integer, nil, String) -> Integer",
                     File, :chown, Process.uid, nil, __FILE__
    assert_send_type "(Integer, Integer, ToStr) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToStr.new(__FILE__)
    assert_send_type "(Integer, Integer, ToPath) -> Integer",
                     File, :chown, Process.uid, Process.gid, ToPath.new(__FILE__)
    assert_send_type "(Integer, nil, String, String) -> Integer",
                     File, :chown, Process.uid, nil, __FILE__, __FILE__
  end

  def test_ctime
    assert_send_type "(String) -> Time",
                     File, :ctime, __FILE__
    assert_send_type "(ToStr) -> Time",
                     File, :ctime, ToStr.new(__FILE__)
    assert_send_type "(ToPath) -> Time",
                     File, :ctime, ToPath.new(__FILE__)
    assert_send_type "(IO) -> Time",
                     File, :ctime, IO.new(IO.sysopen(__FILE__))
  end
end
