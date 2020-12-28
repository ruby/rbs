require "test_helper"

require "rbs/test"
require "logger"

return unless Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')

class RBS::Test::HookTest < Test::Unit::TestCase
  class Example
    def hello(x, y)
      raise "Aborting" if y == 0
      x + y
    end

    def world(x, y = 1)
      y.times do
        yield x
      end

      :world
    end

    def self.foo(x:, **y)
      x
    end

    def +(other)
      :plus
    end
  end

  def setup
    super

    RBS::Test.reset_suffix()
  end

  def test_hook_operator
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |name, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_instance_method(
      Example,
      :+,
      key: key
    )

    _ = Example.new + 30

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t
      assert_equal :+, t.method_name
      assert_operator t.method_call, :return?
      assert_equal [30], t.method_call.arguments
      assert_equal :plus, t.method_call.return_value
    end
  end

  def test_hook_no_block_no_exn
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |name, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_instance_method(
      Example,
      :hello,
      key: key
    )

    Example.new.hello(1, 2)

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t
      assert_equal :hello, t.method_name
      assert_operator t.method_call, :return?
      assert_equal [1,2], t.method_call.arguments
      assert_equal 3, t.method_call.return_value
    end
  end

  def test_hook_no_block_exn
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |name, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_instance_method(
      Example,
      :hello,
      key: key
    )

    assert_raises RuntimeError do
      Example.new.hello(1, 0)
    end

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t
      assert_equal :hello, t.method_name
      assert_equal [1, 0], t.method_call.arguments
      assert_operator t.method_call, :exception?
      assert_instance_of RuntimeError, t.method_call.exception
      assert_equal "Aborting", t.method_call.exception.message
    end
  end

  def test_hook_with_block
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |name, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_instance_method(
      Example,
      :world,
      key: key
    )

    Example.new.world(1, 2) do |x|
      :world
    end

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t

      assert_equal :world, t.method_name

      assert_operator t.method_call, :return?
      assert_equal [1,2], t.method_call.arguments
      assert_equal :world, t.method_call.return_value

      assert_equal 2, t.block_calls.size

      assert_equal [1], t.block_calls[0].arguments
      assert_equal :world, t.block_calls[1].return_value
    end
  end

  def test_hook_with_block_raise
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |name, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_instance_method(
      Example,
      :world,
      key: key
    )

    assert_raises RuntimeError do
      Example.new.world(1, 2) do |x|
        raise "from block"
      end
    end

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t

      assert_equal :world, t.method_name

      assert_equal [1,2], t.method_call.arguments
      assert_instance_of RuntimeError, t.method_call.exception

      assert_equal 1, t.block_calls.size

      assert_equal [1], t.block_calls[0].arguments
      assert_instance_of RuntimeError, t.block_calls[0].exception
    end
  end

  def test_hook_singleton_method
    key = SecureRandom.hex(10)

    traces = []
    RBS::Test::Observer.register(key) do |object, trace|
      traces << trace
    end

    RBS::Test::Hook.hook_singleton_method(
      Example,
      :foo,
      key: key
    )

    Example.foo(x: "x", hello: :world) do
      :bar
    end

    traces[0].tap do |t|
      assert_instance_of RBS::Test::CallTrace, t

      assert_equal :foo, t.method_name

      assert_operator t.method_call, :return?
      assert_equal [{ x: "x", hello: :world }], t.method_call.arguments
      assert_equal "x", t.method_call.return_value
      assert_operator t, :block_given
      assert_empty t.block_calls
    end
  end
end
