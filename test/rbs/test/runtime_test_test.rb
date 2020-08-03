require "test_helper"
require "rbs/test"
require "logger"

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')

class RBS::Test::RuntimeTestTest < Minitest::Test
  include TestHelper

  def test_runtime_success
    output = assert_test_success()
    assert_match "Setting up hooks for ::Hello", output
    refute_match "No type checker was installed!", output
  end

  def test_runtime_test_with_sample_size
    assert_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => '30'})
    assert_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => '100'})
    assert_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => 'ALL'})
  end

  def test_runtime_test_error_with_invalid_sample_size
    string_err_msg = refute_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => 'yes'})
    assert_match(/E, .+ ERROR -- rbs: Sample size should be a positive integer: `.+`\n/, string_err_msg)

    zero_err_msg = refute_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => '0'})
    assert_match(/E, .+ ERROR -- rbs: Sample size should be a positive integer: `.+`\n/, zero_err_msg)

    negative_err_msg = refute_test_success(other_env: {"RBS_TEST_SAMPLE_SIZE" => '-1'})
    assert_match(/E, .+ ERROR -- rbs: Sample size should be a positive integer: `.+`\n/, negative_err_msg)
  end

  def run_runtime_test(other_env:)
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
RUBY

        env = {
          "BUNDLE_GEMFILE" => File.join(__dir__, "../../../Gemfile"),
          "RBS_TEST_TARGET" => "::Hello",
          "RBS_TEST_OPT" => "-I./foo.rbs"
        }
        _out, err, status = Open3.capture3(env.merge(other_env), "ruby", "-rbundler/setup", "-rrbs/test/setup", "sample.rb", chdir: path.to_s)

        return [err, status]
      end
    end
  end

  def assert_test_success(other_env: {})
    err, status = run_runtime_test(other_env: other_env)
    assert_operator status, :success?
    err
  end

  def refute_test_success(other_env: {})
    err, status = run_runtime_test(other_env: other_env)
    refute_operator status, :success?
    err
  end

  def test_test_target
    output = refute_test_success(other_env: { "RBS_TEST_TARGET" => nil })
    assert_match "rbs/test/setup handles the following environment variables:", output
  end

  def test_no_test_install
    output = assert_test_success(other_env: { "RBS_TEST_TARGET" => "NO_SUCH_CLASS" })
    refute_match "Setting up hooks for ::Hello", output
    assert_match "No type checker was installed!", output
  end
end
