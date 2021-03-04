require_relative "test_helper"

class ThreadSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Thread)"

  def test_new
    assert_send_type  "() { () -> untyped } -> Thread",
                      Thread, :new do 1 end
    assert_send_type  "(Integer, nil) { (Integer, nil) -> untyped } -> Thread",
                      Thread, :new, 1, nil do |a, b| [a, b] end

    a_proc = proc { "do something..." }
    assert_send_type  "() { () -> untyped } -> Thread",
                      Thread, :new, &a_proc
  end
end
