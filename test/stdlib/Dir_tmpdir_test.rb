require_relative "test_helper"

class Tmpdir_Dir_SingletonTest < Test::Unit::TestCase
  include TestHelper

  library "tmpdir"
  testing "singleton(Dir)"

  def test_tmpdir
    assert_send_type(
      "() -> String",
      Dir, :mktmpdir
    )
  end

  def test_mktmpdir
    assert_send_type(
      "() -> String",
      Dir, :mktmpdir
    )
    assert_send_type(
      "() { (String) -> Integer} -> Integer",
      Dir, :mktmpdir, &->(s) { s.size }
    )

    assert_send_type(
      "(max_try: Integer) -> String",
      Dir, :mktmpdir, max_try: 1
    )
    assert_send_type(
      "(max_try: Integer) { (String) -> Integer } -> Integer",
      Dir, :mktmpdir, max_try: 1, &->(s) { s.size}
    )

    with_string("foo") do |foo|
      assert_send_type(
        "(string) -> String",
        Dir, :mktmpdir, foo
      )
      assert_send_type(
        "(string) { (String) -> Integer } -> Integer",
        Dir, :mktmpdir, foo, &->(x) { x.size }
      )
    end

    assert_send_type(
      "(nil) -> String",
      Dir, :mktmpdir, nil
    )
    assert_send_type(
      "(nil) { (String) -> Integer } -> Integer",
      Dir, :mktmpdir, nil, &->(x) { x.size }
    )

    with_string("foo") do |foo|
      with_string("bar") do |bar|
        assert_send_type(
          "([string, string]) -> String",
          Dir, :mktmpdir, [foo, bar]
        )
        assert_send_type(
          "([string, string]) { (String) -> Integer } -> Integer",
          Dir, :mktmpdir, [foo, bar], &->(s) { s.size }
        )
      end
    end

    with_string("foo") do |foo|
      with(Dir.tmpdir, Pathname(Dir.tmpdir)) do |bar|
        assert_send_type(
          "(string, path) -> String",
          Dir, :mktmpdir, foo, bar
        )

        assert_send_type(
          "(string, path) { (String) -> Integer } -> Integer",
          Dir, :mktmpdir, foo, bar, &->(s) { s.size }
        )
      end
    end
  end
end
