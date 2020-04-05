require_relative "test_helper"

class UnboundMethodTest < StdlibTest
  target UnboundMethod
  using hook.refinement

  class Foo
    def foo
    end

    def foo_with_args(*, **)
    end

    def foo_with_many_args(x, y=42, *other, k_x:, k_y: 42, **k_other, &b)
    end

    def foo_with_arg_and_rest(x, *)
    end
  end

  class Bar
    def foo
    end
  end

  def test_arity
    Foo.new.method(:foo).unbind.arity
  end

  def test_bind
    Foo.new.method(:foo).unbind.bind(Foo.new)
  end

  def test_name
    Foo.new.method(:foo).unbind.name
  end

  def test_owner
    Foo.new.method(:foo).unbind.owner
  end

  def test_parameters
    Foo.new.method(:foo).unbind.parameters
    Foo.new.method(:foo_with_args).unbind.parameters
    Foo.new.method(:foo_with_many_args).unbind.parameters
    Foo.new.method(:foo_with_arg_and_rest).unbind.parameters
  end

  def test_source_location
    Foo.new.method(:foo).unbind.source_location
    method(:puts).unbind.source_location
  end

  def test_super_method
    Foo.new.method(:foo).unbind.super_method
    Bar.new.method(:foo).unbind.super_method
  end

  def test_unbind
    Foo.new.method(:foo).unbind
  end
end
