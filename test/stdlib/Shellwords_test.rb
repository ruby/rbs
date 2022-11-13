require_relative "test_helper"
require "shellwords"

class ShellwordsSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "shellwords"
  testing "singleton(::Shellwords)"

  def test_shellescape
    assert_send_type  "(::String str) -> ::String",
                      Shellwords, :shellescape, "shell"
  end

  def test_shelljoin
    assert_send_type  "(::Array[::String] array) -> ::String",
                      Shellwords, :shelljoin, ["shell", "words"]
  end

  def test_shellsplit
    assert_send_type  "(::String line) -> ::Array[::String]",
                      Shellwords, :shellsplit, "shell"
  end

  def test_escape
    assert_send_type  "(::String str) -> ::String",
                      Shellwords, :escape, "shell"
  end

  def test_join
    assert_send_type  "(::Array[::String] array) -> ::String",
                      Shellwords, :join, ["shell", "words"]
  end

  def test_shellwords
    assert_send_type  "(::String line) -> ::Array[::String]",
                      Shellwords, :shellwords, "shell"
  end

  def test_split
    assert_send_type  "(::String line) -> ::Array[::String]",
                      Shellwords, :split, "shell"
  end
end

class ShellwordsTest < Test::Unit::TestCase
  include TypeAssertions

  library "shellwords"
  testing "::Shellwords"

  class Container
    include Shellwords
  end

  def test_shellescape
    assert_send_type  "(::String str) -> ::String",
                      Container.new, :shellescape, "shell"
  end

  def test_shelljoin
    assert_send_type  "(::Array[::String] array) -> ::String",
                      Container.new, :shelljoin, ["shell", "words"]
  end

  def test_shellsplit
    assert_send_type  "(::String line) -> ::Array[::String]",
                      Container.new, :shellsplit, "shell"
  end

  def test_shellwords
    assert_send_type  "(::String line) -> ::Array[::String]",
                      Container.new, :shellwords, "shell"
  end
end

class ShellwordsArrayTest < Test::Unit::TestCase
  include TypeAssertions

  library "shellwords"
  testing "::Array[String]"

  def test_shelljoin
    assert_send_type  "() -> ::String",
                      ["shell", "words"], :shelljoin
  end
end

class ShellwordsStringTest < Test::Unit::TestCase
  include TypeAssertions

  library "shellwords"
  testing "::String"

  def test_shellescape
    assert_send_type  "() -> ::String",
                      "shell", :shellescape
  end

  def test_shellsplit
    assert_send_type  "() -> ::Array[String]",
                      "shell words", :shellsplit
  end
end
