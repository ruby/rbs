require_relative "test_helper"

class FiberSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Fiber)"

  def test_aref
    assert_send_type(
      "(Symbol, Integer) -> Integer",
      Fiber, :[]=, :key, 123
    )

    assert_send_type(
      "(Symbol) -> Integer",
      Fiber, :[], :key
    )
  end

  def test_blocking?
    assert_send_type "() -> 1",
                     Fiber, :blocking?
  end

  def test_current
    assert_send_type "() -> Fiber",
                     Fiber, :current
  end

  def test_current_scheduler
    assert_send_type "() -> untyped",
                     Fiber, :current_scheduler
  end

  def test_scheduler
    assert_send_type "() -> untyped",
                     Fiber, :scheduler
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

  def test_new
    assert_send_type  "() { () -> void } -> Fiber",
                      Fiber, :new do 42 end
    assert_send_type  "(blocking: String) { () -> void } -> Fiber",
                      Fiber, :new, blocking: "false" do 42 end
    assert_send_type  "(storage: Hash[untyped, untyped]) { () -> void } -> Fiber",
                      Fiber, :new, storage: {} do 42 end
    assert_send_type  "(storage: true) { () -> void } -> Fiber",
                      Fiber, :new, storage: true do 42 end
    assert_send_type  "(storage: nil) { () -> void } -> Fiber",
                      Fiber, :new, storage: nil do 42 end
  end
end

class FiberTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Fiber"

  def test_alive?
    f = Fiber.new {}
    assert_send_type "() -> true",
                     f, :alive?
    f.resume
    assert_send_type "() -> false",
                     f, :alive?
  end

  def test_backtrace
    f = Fiber.new {
      1.tap do
        2.tap do
          3.tap do
            Fiber.yield
          end
        end
      end
    }

    assert_send_type "() -> []",
                     f, :backtrace

    f.resume

    assert_send_type "() -> Array[String]",
                     f, :backtrace

    assert_send_type "(Integer) -> Array[String]",
                     f, :backtrace, 0

    assert_send_type "(Integer, Integer) -> Array[String]",
                     f, :backtrace, 0, 1

    assert_send_type "(Range[Integer]) -> Array[String]",
                     f, :backtrace, 0..1

    f.resume

    assert_send_type "() -> ([] | nil)",
                     f, :backtrace
  end

  def test_backtrace_locations
    f = Fiber.new {
      1.tap do
        2.tap do
          3.tap do
            Fiber.yield
          end
        end
      end
    }

    assert_send_type "() -> []",
                     f, :backtrace_locations

    f.resume

    assert_send_type "() -> Array[Thread::Backtrace::Location]",
                     f, :backtrace_locations

    assert_send_type "(Integer) -> Array[Thread::Backtrace::Location]",
                     f, :backtrace_locations, 0

    assert_send_type "(Integer, Integer) -> Array[Thread::Backtrace::Location]",
                     f, :backtrace_locations, 0, 1

    assert_send_type "(Range[Integer]) -> Array[Thread::Backtrace::Location]",
                     f, :backtrace_locations, 0..1

    f.resume

    assert_send_type "() -> ([] | nil)",
                     f, :backtrace_locations
  end

  def test_blocking?
    f = Fiber.new() {}

    assert_send_type "() -> false",
                      f, :blocking?

    g = Fiber.new(blocking: true) {}

    assert_send_type "() -> true",
                      g, :blocking?
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

  def test_transfer
    f = Fiber.new{}
    assert_send_type '() -> untyped',
                     f, :transfer
    f = Fiber.new{}
    assert_send_type '(untyped) -> untyped',
                     f, :transfer, 1
    f = Fiber.new{}
    assert_send_type '(untyped, untyped) -> untyped',
                     f, :transfer, 1, 'foo'
  end
end
