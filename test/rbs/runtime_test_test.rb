require "test_helper"

require "rbs/test"
require "logger"

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')

class RBS::RuntimeTestTest < Minitest::Test
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
RUBY

        env = {
          "RBS_TEST_TARGET" => "Hello",
          "BUNDLE_GEMFILE" => File.join(__dir__, "../../Gemfile"),
          "RBS_TEST_OPT" => "-I./foo.rbs"
        }
        out, status = Open3.capture2e(env, "ruby", "-rbundler/setup", "-rrbs/test/setup", "sample.rb", chdir: path.to_s)

        assert_operator status, :success?
        assert_match /Setting up hooks for Hello$/, out
      end
    end
  end
end
