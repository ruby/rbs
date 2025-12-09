require_relative "test_helper"

class RactorSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Ractor)"

  def test_aref
    if_ruby("3.4"...) do
      assert_send_type(
        "(Symbol) -> untyped",
        Ractor, :[], :foo
      )
    end
  end

  def test_arefeq
    if_ruby("3.4"...) do
      assert_send_type(
        "(Symbol, Integer) -> Integer",
        Ractor, :[]=, :foo, 1
      )
    end
  end

  def test_count
    assert_send_type "() -> Integer",
                     Ractor, :count
  end

  def test_current
    assert_send_type "() -> Ractor",
                     Ractor, :current
  end

  def test_main
    assert_send_type "() -> Ractor",
                     Ractor, :main
  end

  def test_main?
    if_ruby("3.4"...) do
      assert_send_type "() -> bool", Ractor, :main?
    end
  end

  def test_make_shareable
    assert_send_type "(String) -> String",
                     Ractor, :make_shareable, 'foo'
    assert_send_type "(String, copy: true) -> String",
                     Ractor, :make_shareable, 'foo', copy: true
    assert_send_type "(String, copy: false) -> String",
                     Ractor, :make_shareable, 'foo', copy: false
    assert_send_type "(String, copy: nil) -> String",
                     Ractor, :make_shareable, 'foo', copy: nil
  end

  def test_new
    # TODO: it raises an error because the proc is not isolated
    # assert_send_type '() { () -> untyped } -> Ractor',
    #                  Ractor, :new do end
  end

  def test_receive
    Ractor.current.send 42
    assert_send_type "() -> Integer",
                     Ractor, :receive
  end

  def test_recv
    Ractor.current.send 42
    assert_send_type "() -> Integer",
                     Ractor, :recv
  end

  def test_shareable?
    assert_send_type "(untyped) -> true",
                     Ractor, :shareable?, 42
    assert_send_type "(untyped) -> false",
                     Ractor, :shareable?, []
  end

  def test_store_if_absent
    assert_send_type(
      "(Symbol) { (nil) -> true } -> true",
      Ractor, :store_if_absent, :test_store_if_absent, &->(_x) { true }
    )
  end
end

class RactorInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Ractor"

  def test_inspect
    assert_send_type "() -> String",
                     Ractor.current, :inspect
  end

  def test_join
    ractor = Ractor.new { }

    assert_send_type(
      "() -> ::Ractor",
      ractor, :join
    )
  end

  def test_name
    unnamed = Ractor.new {}
    named = Ractor.new(name: 'foo') {}
    assert_send_type "() -> nil",
                     unnamed, :name
    assert_send_type "() -> String",
                     named, :name
  end

  def test_send
    r = Ractor.new { sleep }

    assert_send_type "(Integer) -> Ractor",
                     r, :send, 42
    assert_send_type "(Integer, move: true) -> Ractor",
                     r, :send, 42, move: true
    assert_send_type "(Integer, move: nil) -> Ractor",
                     r, :send, 42, move: nil
  end

  def test_to_s
    assert_send_type "() -> String",
                     Ractor.current, :to_s
  end

  def test_value
    ractor = Ractor.new { 123 }

    assert_send_type(
      "() -> ::Integer",
      ractor, :value
    )
  end
end
