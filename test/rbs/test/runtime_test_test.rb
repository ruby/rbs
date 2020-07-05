require "test_helper"

require "rbs/test"
require "logger"

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')

class RBS::Test::RuntimeTestTest < Minitest::Test
  include TestHelper

  def test_runtime_test
    SignatureManager.new(system_builtin: true) do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  attr_reader x: Integer
  attr_reader y: Integer

  def initialize: (x: Integer, y: Integer) -> void

  def move: (?x: Integer, ?y: Integer) -> void
end
EOF
      manager.build do |env, path|
        (path + "sample.rb").write(<<RUBY)
class Hello
  attr_reader :x, :y

  def initialize(x:, y:)
    @x = x
    @y = y
  end

  def move(x: 0, y: 0)
    @x += x
    @y += y
  end
end

hello = Hello.new(x: 0, y: 10)
hello.move(y: -10)
hello.move(10, -20)
RUBY

        env = {
          "BUNDLE_GEMFILE" => File.join(__dir__, "../../../Gemfile"),
          "RBS_TEST_TARGET" => "::Hello",
          "RBS_TEST_OPT" => "-I./foo.rbs"
        }
        _out, err, status = Open3.capture3(env, "ruby", "-rbundler/setup", "-rrbs/test/setup", "sample.rb", chdir: path.to_s)

        # STDOUT.puts _out
        # STDERR.puts err

        refute_operator status, :success?
        assert_match(/Setting up hooks for ::Hello$/, err)
        assert_match(/TypeError: \[Hello#move\] ArgumentError:/, err)
      end
    end
  end
end
