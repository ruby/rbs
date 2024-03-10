require "test_helper"
require "rbs/cli"

class RBS::DiffTest < Test::Unit::TestCase
  include TestHelper

  Diff = RBS::Diff

  def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end

  def test_diff
    mktmpdir do |path|
      dir1 = (path / "dir1")
      dir1.mkdir
      (dir1 / 'before.rbs').write(<<~RBS)
        class Foo
          def bar: () -> void
          def self.baz: () -> (Integer | String)
          def qux: (untyped) -> untyped
          def quux: () -> void

          SAME_MOD_SAME_VALUE: 1
          SAME_MOD_OTHER_VALUE: 2
          SAME_MOD_BEFORE_ONLY: 3
          OTHER_MOD_SAME_VALUE: 4
          OTHER_MOD_OTHER_VALUE: 5
        end
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        module Bar
          def bar: () -> void
          OTHER_MOD_SAME_VALUE: 4
          OTHER_MOD_OTHER_VALUE: Array[Integer]
        end

        module Baz
          def baz: (Integer) -> Integer?
        end

        class Foo
          include Bar
          extend Baz
          alias quux bar
          SAME_MOD_SAME_VALUE: 1
          SAME_MOD_OTHER_VALUE: String
          SAME_MOD_AFTER_ONLY: 3
        end
      RBS

      diff = Diff.new(
        type_name: TypeName("::Foo"),
        library_options: RBS::CLI::LibraryOptions.new,
        before_path: [dir1],
        after_path: [dir2],
      )
      results = diff.each_diff.map do |before, after|
        [before, after]
      end
      assert_equal [
        ["def qux: (untyped) -> untyped", "-"],
        ["def quux: () -> void", "alias quux bar"],
        ["def self.baz: () -> (::Integer | ::String)", "def self.baz: (::Integer) -> ::Integer?"],
        ["SAME_MOD_OTHER_VALUE: 2", "SAME_MOD_OTHER_VALUE: ::String"],
        ["SAME_MOD_BEFORE_ONLY: 3", "-"],
        ["OTHER_MOD_OTHER_VALUE: 5", "OTHER_MOD_OTHER_VALUE: ::Array[::Integer]"],
        ["-", "SAME_MOD_AFTER_ONLY: 3"]
      ], results
    end
  end

  def test_detail
    mktmpdir do |path|
      dir1 = (path / "dir1")
      dir1.mkdir
      (dir1 / 'before.rbs').write(<<~RBS)
        class Foo
          def bar: () -> void
          def self.baz: () -> (Integer | String)
          def qux: (untyped) -> untyped
          def quux: () -> void

          SAME_MOD_SAME_VALUE: 1
          SAME_MOD_OTHER_VALUE: 2
          SAME_MOD_BEFORE_ONLY: 3
          OTHER_MOD_SAME_VALUE: 4
          OTHER_MOD_OTHER_VALUE: 5
        end
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        module Bar
          def bar: () -> void
          OTHER_MOD_SAME_VALUE: 4
          OTHER_MOD_OTHER_VALUE: Array[Integer]
        end

        module Baz
          def baz: (Integer) -> Integer?
        end

        class Foo
          include Bar
          extend Baz
          alias quux bar
          SAME_MOD_SAME_VALUE: 1
          SAME_MOD_OTHER_VALUE: String
          SAME_MOD_AFTER_ONLY: 3
        end
      RBS

      diff = Diff.new(
        type_name: TypeName("::Foo"),
        library_options: RBS::CLI::LibraryOptions.new,
        before_path: [dir1],
        after_path: [dir2],
        detail: true,
      )
      results = diff.each_diff.map do |before, after|
        [before, after]
      end
      assert_equal [
        ["[::Foo public] def bar: () -> void", "[::Bar public] def bar: () -> void"],
        ["[::Foo public] def qux: (untyped) -> untyped", "-"],
        ["[::Foo public] def quux: () -> void", "[::Foo public] alias quux bar"],
        ["[::Foo public] def self.baz: () -> (::Integer | ::String)", "[::Baz public] def self.baz: (::Integer) -> ::Integer?"],
        ["[::Foo] SAME_MOD_OTHER_VALUE: 2", "[::Foo] SAME_MOD_OTHER_VALUE: ::String"],
        ["[::Foo] SAME_MOD_BEFORE_ONLY: 3", "-"],
        ["[::Foo] OTHER_MOD_SAME_VALUE: 4", "[::Bar] OTHER_MOD_SAME_VALUE: 4"],
        ["[::Foo] OTHER_MOD_OTHER_VALUE: 5", "[::Bar] OTHER_MOD_OTHER_VALUE: ::Array[::Integer]"],
        ["-", "[::Foo] SAME_MOD_AFTER_ONLY: 3"]
      ], results
    end
  end

  def test_with_manifest_yaml
    mktmpdir do |path|
      dir1 = (path / "dir1")
      dir1.mkdir
      (dir1 / 'before.rbs').write(<<~RBS)
        class Pathname
        end
      RBS
      (dir1 / 'manifest.yaml').write(<<~RBS)
        dependencies:
          - name: pathname
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        class Pathname
          def foooooooo: () -> void
        end
      RBS
      (dir2 / 'manifest.yaml').write(<<~RBS)
        dependencies:
          - name: pathname
      RBS

      diff = Diff.new(
        type_name: TypeName("::Pathname"),
        library_options: RBS::CLI::LibraryOptions.new,
        before_path: [dir1],
        after_path: [dir2],
        detail: true,
      )
      assert_equal [["-", "[::Pathname public] def foooooooo: () -> void"]], diff.each_diff.to_a
    end
  end

  def test_with_empty_manifest_yaml
    mktmpdir do |path|
      dir1 = (path / "dir1")
      dir1.mkdir
      (dir1 / 'before.rbs').write(<<~RBS)
        class Foo
        end
      RBS
      (dir1 / 'manifest.yaml').write(<<~RBS)
        # empty
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        class Foo
        end
      RBS
      (dir2 / 'manifest.yaml').write(<<~RBS)
        # empty
      RBS

      diff = Diff.new(
        type_name: TypeName("::Foo"),
        library_options: RBS::CLI::LibraryOptions.new,
        before_path: [dir1],
        after_path: [dir2],
        detail: true,
      )
      assert_equal [], diff.each_diff.to_a
    end
  end
end
