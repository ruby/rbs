require_relative "../test_helper"

class RBS::RequireTest < Test::Unit::TestCase
  # Regression test for https://github.com/ruby/rbs/issues/3027
  #
  # `Kernel#Pathname` is defined by `pathname`, not by the `Pathname` class itself.
  # RBS calls `Pathname(...)` while loading `RBS::EnvironmentLoader`, so loading RBS
  # must not depend on another library having loaded `pathname` first -- nor skip
  # loading it just because the `Pathname` constant happens to be defined already.
  def test_require_rbs_with_pathname_constant_defined
    script = <<~RUBY
      class Pathname
      end

      require "rbs"

      puts RBS::EnvironmentLoader::DEFAULT_CORE_ROOT
      puts RBS::Repository::DEFAULT_STDLIB_ROOT
      puts RBS::Collection::Config::PATH
    RUBY

    load_path = $LOAD_PATH.flat_map {|path| ["-I", path] }
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, *load_path, "-e", script)

    assert_predicate status, :success?, stderr
    assert_equal 3, stdout.lines.size, stdout
  end
end
