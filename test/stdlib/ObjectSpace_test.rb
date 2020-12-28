require_relative "test_helper"

class ObjectSpaceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::ObjectSpace)"

  def test__id2ref
    assert_send_type "(Integer) -> top",
                     ObjectSpace, :_id2ref, 198
  end

  def test_count_objects
    assert_send_type "() -> Hash[Symbol, Integer]",
                     ObjectSpace, :count_objects
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
                     ObjectSpace, :count_objects, {}
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
                     ObjectSpace, :count_objects, { TOTAL: 0 }
  end

  def test_define_finalizer
    assert_send_type "(top, ^(Integer) -> void) -> [Integer, Proc]",
                     ObjectSpace, :define_finalizer, "abc", ->(id) { "id: #{id}" }
    assert_send_type "(top) { (Integer) -> void } -> [Integer, Proc]",
                     ObjectSpace, :define_finalizer, "abc" do |id| "id: #{id}" end
  end

  def test_each_object
    klass = Class.new
    klass.new

    # NOTE: Commented out because they're too slow.
    # assert_send_type "() -> Enumerator[top, Integer]",
    #                  ObjectSpace, :each_object
    # assert_send_type "() { (top) -> void } -> Integer",
    #                  ObjectSpace, :each_object do |obj| obj.to_s end

    assert_send_type "(Module) -> Enumerator[top, Integer]",
                     ObjectSpace, :each_object, klass
    assert_send_type "(Module) { (top) -> void } -> Integer",
                     ObjectSpace, :each_object, klass do |obj| obj.to_s end
  end

  def test_garbage_collect
    assert_send_type "() -> void",
                     ObjectSpace, :garbage_collect
    assert_send_type "(full_mark: bool, immediate_mark: bool, immediate_sweep: bool) -> void",
                     ObjectSpace, :garbage_collect, full_mark: false, immediate_mark: false, immediate_sweep: false
  end

  def test_undefine_finalizer
    assert_send_type "(String) -> String",
                     ObjectSpace, :undefine_finalizer, "abc"
    assert_send_type "(Array) -> Array",
                     ObjectSpace, :undefine_finalizer, []
  end
end
