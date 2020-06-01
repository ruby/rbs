require_relative "test_helper"
require "rbs/test/test_helper"

class FiberSingletonTest < Minitest::Test
  include RBS::Test::TypeAssertions

  testing "singleton(::Fiber)"

  def test_new
    assert_send_type "() { () -> untyped }-> Fiber",
                     Fiber, :new do 42 end
  end

  def test_yield
    Fiber.new do
      assert_send_type "() -> untyped",
                       Fiber, :yield
    end.resume

    Fiber.new do
      assert_send_type "(untyped) -> untyped",
                       Fiber, :yield, 42
    end.resume

    Fiber.new do
      assert_send_type "(untyped, untyped) -> untyped",
                       Fiber, :yield, 42, '42'
    end.resume
  end
end

class FiberTest < Minitest::Test
  include RBS::Test::TypeAssertions

  testing "::Fiber"

  def test_resume
    f = Fiber.new do
      loop { Fiber.yield }
    end

    assert_send_type "() -> untyped",
                     f, :resume
    assert_send_type "(untyped) -> untyped",
                     f, :resume, 10
    assert_send_type "(untyped, untyped) -> untyped",
                     f, :resume, 10, :foo
  end

  def test_raise
    f = Fiber.new do
      Fiber.yield
    rescue
      retry
    end
    f.resume

    assert_send_type "() -> untyped",
                     f, :raise
    assert_send_type "(String) -> untyped",
                     f, :raise, "Error!"
    assert_send_type "(ToStr) -> untyped",
                     f, :raise, ToStr.new('Error!')
    assert_send_type "(singleton(StandardError)) -> untyped",
                     f, :raise, StandardError
    assert_send_type "(StandardError) -> untyped",
                     f, :raise, StandardError.new('Error!')
    assert_send_type "(singleton(StandardError), String) -> untyped",
                     f, :raise, StandardError, 'Error!'
    assert_send_type "(singleton(StandardError), String, Array[String]) -> untyped",
                     f, :raise, StandardError, 'Error!', caller
  end
end
