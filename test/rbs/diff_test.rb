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
        end
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        module Bar
          def bar: () -> void
        end

        module Baz
          def baz: (Integer) -> Integer?
        end

        class Foo
          include Bar
          extend Baz
          alias quux bar
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
        ["def self.baz: () -> (::Integer | ::String)", "def self.baz: (::Integer) -> ::Integer?"]
      ], results
    end
  end
end
