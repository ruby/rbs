require "test_helper"

begin
  require "rubocop"
rescue LoadError
  # rubocop is a development dependency; skip when running without bundler.
  return
end

require_relative "../../rubocop/stdlib_test_non_type_assertion"

class StdlibTestNonTypeAssertionTest < Test::Unit::TestCase
  ROOT = File.expand_path("../..", __dir__)

  def offenses(source, path: "test/stdlib/Foo_test.rb")
    path = File.join(ROOT, path)
    config = RuboCop::ConfigStore.new.for_file(path)
    cop = RuboCop::Cop::StdlibTest::NonTypeAssertion.new(config)
    processed_source = RuboCop::ProcessedSource.new(source.dup,RUBY_VERSION.to_f, path)
    processed_source.config = config
    processed_source.registry = RuboCop::Cop::Registry.new([cop.class])

    team = RuboCop::Cop::Team.new([cop], config, raise_error: true)
    team.investigate(processed_source).offenses.map {|offense| [offense.line, offense.location.source] }
  end

  def test_value_assertions
    assert_equal [[2, "assert_equal"], [3, "assert_nil"], [4, "assert_raises"], [5, "assert"], [6, "refute"]], offenses(<<~RUBY)
      def test_foo
        assert_equal 3, 1 + 2
        assert_nil foo
        assert_raises(ArgumentError) { foo(1) }
        assert foo
        refute foo
      end
    RUBY
  end

  def test_method_reference
    assert_equal [[1, ":assert"]], offenses(<<~RUBY)
      assert_fn = method(:assert)
      assert_type_fn = method(:assert_type)
    RUBY
  end

  def test_type_assertions
    assert_equal [], offenses(<<~RUBY)
      def test_foo
        assert_send_type "(Integer) -> Integer", 1, :+, 2
        assert_send_type_error "() -> bot", ArgumentError, foo, :bar
        refute_send_type "() -> String", foo, :bar
        assert_const_type "Integer", "Foo::BAR"
        assert_visibility :private, :foo
        assert_type "Integer", eval("1")
      end
    RUBY
  end

  def test_local_helper
    assert_equal [[3, "assert_equal"]], offenses(<<~RUBY)
      def assert_foo(value)
        assert_send_type "() -> Integer", value, :foo
        assert_equal 1, value.foo
      end

      def test_foo
        assert_foo bar
      end
    RUBY
  end

  def test_receiver
    assert_equal [], offenses(<<~RUBY)
      foo.assert_equal 1, 2
    RUBY
  end

  def test_outside_stdlib_test
    source = "assert_equal 1, 2\n"

    assert_equal [], offenses(source, path: "test/rbs/foo_test.rb")
    assert_equal [], offenses(source, path: "test/stdlib/test_helper.rb")
    assert_equal [], offenses(source, path: "test/stdlib/constant_drift_test.rb")
    assert_equal [[1, "assert_equal"]], offenses(source, path: "test/stdlib/uri/foo_test.rb")
  end
end
