require_relative "test_helper"
require 'objspace'

class ObjectSpaceTest < Test::Unit::TestCase
  include TypeAssertions

  library "objspace"
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

  def test_allocation_class_path
    ObjectSpace::trace_object_allocations do
      assert_send_type "(untyped) -> String",
        ObjectSpace, :allocation_class_path, "abc"
    end
  end

  def test_allocation_generation
    ObjectSpace::trace_object_allocations do
      assert_send_type "(untyped) -> Integer",
        ObjectSpace, :allocation_generation, Object.new
      assert_send_type "(untyped) -> nil",
        ObjectSpace, :allocation_generation, nil
    end
  end

  def test_allocation_method_id
    ObjectSpace::trace_object_allocations do
      assert_send_type "(untyped) -> Symbol",
        ObjectSpace, :allocation_method_id, Object.new
    end
  end

  def test_allocation_sourcefile
    ObjectSpace::trace_object_allocations do
      assert_send_type "(untyped) -> String",
        ObjectSpace, :allocation_sourcefile, Object.new
    end
  end

  def test_allocation_sourceline
    ObjectSpace::trace_object_allocations do
      assert_send_type "(untyped) -> Integer",
        ObjectSpace, :allocation_sourceline, Object.new
    end
  end

  def test_count_imemo_objects
    assert_send_type "() -> Hash[Symbol, Integer]",
      ObjectSpace, :count_imemo_objects
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_imemo_objects, {}
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_imemo_objects, { TOTAL: 0 }
  end

  def test_count_nodes
    ObjectSpace::trace_object_allocations do
      assert_send_type "() -> Hash[Symbol, Integer]",
        ObjectSpace, :count_nodes
      assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
        ObjectSpace, :count_nodes, {}
      assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
        ObjectSpace, :count_nodes, { TOTAL: 0 }
    end
  end

  def test_count_objects_size
    assert_send_type "() -> Hash[Symbol, Integer]",
      ObjectSpace, :count_objects_size
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_objects_size, {}
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_objects_size, { TOTAL: 0 }
  end

  def test_count_symbols
    assert_send_type "() -> Hash[Symbol, Integer]",
      ObjectSpace, :count_symbols
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_symbols, {}
    assert_send_type "(Hash[Symbol, Integer]) -> Hash[Symbol, Integer]",
      ObjectSpace, :count_symbols, { TOTAL: 0 }
  end

  def test_count_tdata_objects
    assert_send_type "() -> Hash[untyped, Integer]",
      ObjectSpace, :count_tdata_objects
    assert_send_type "(Hash[untyped, Integer]) -> Hash[untyped, Integer]",
      ObjectSpace, :count_tdata_objects, {}
    assert_send_type "(Hash[untyped, Integer]) -> Hash[untyped, Integer]",
      ObjectSpace, :count_tdata_objects, { TOTAL: 0 }
  end

  def test_dump
    assert_send_type "(untyped obj, ?output: Symbol) -> String",
      ObjectSpace, :dump, Object.new
    assert_send_type "(untyped obj, ?output: Symbol) -> File",
      ObjectSpace, :dump, Object.new, output: :file
    assert_send_type "(untyped obj, ?output: Symbol) -> nil",
      ObjectSpace, :dump, Object.new, output: :stdout
  end

  def test_dump_all
    # NOTE: Commented out because they're too slow with ruby 2.7
    # because dump_all in 2.7 doesn't have since params to control the number of objects
    #assert_send_type "(?output: Symbol, ?full: bool,  ?since: (Integer|nil)) -> File",
      #ObjectSpace, :dump_all
    #assert_send_type "(?output: Symbol, ?full: bool,  ?since: (Integer|nil)) -> String",
      #ObjectSpace, :dump_all, output: :string
    #assert_send_type "(?output: Symbol, ?full: bool,  ?since: (Integer|nil)) -> nil",
      #ObjectSpace, :dump_all, output: :stdout
  end

  def test_internal_class_of
    assert_send_type "(String) -> singleton(String)",
      ObjectSpace, :internal_class_of, "dummy"
  end

  def test_internal_super_of
    assert_send_type "(singleton(String)) -> untyped",
      ObjectSpace, :internal_super_of, String
  end

  def test_memsize_of
    assert_send_type "(untyped) -> Integer",
      ObjectSpace, :memsize_of, "dummy"
  end

  def test_memsize_of_all
    assert_send_type "() -> Integer",
      ObjectSpace, :memsize_of_all

    assert_send_type "(Class) -> Integer",
      ObjectSpace, :memsize_of_all, Symbol
  end

  def test_reachable_objects_from
    assert_send_type "(untyped) -> [untyped]",
      ObjectSpace, :reachable_objects_from, "dummy"
    assert_send_type "(untyped) -> [untyped]",
      ObjectSpace, :reachable_objects_from, ["dummy", "dummy2"]
    assert_send_type "(untyped) -> nil",
      ObjectSpace, :reachable_objects_from, nil
  end

  def test_reachable_objects_from_root
    assert_send_type "() -> Hash[String, untyped]",
      ObjectSpace, :reachable_objects_from_root
  end

  def test_trace_object_allocations
    assert_send_type "() { (untyped) -> untyped } -> untyped",
      ObjectSpace, :trace_object_allocations do Object.new end
  end

  def test_trace_object_allocations_clear
    assert_send_type "() -> void",
      ObjectSpace, :trace_object_allocations_clear
  end

  def test_trace_object_allocations_debug_start
    assert_send_type "() -> void",
      ObjectSpace, :trace_object_allocations_debug_start
  end

  def test_trace_object_allocations_start
    assert_send_type "() -> void",
      ObjectSpace, :trace_object_allocations_start
  end

  def test_trace_object_allocations_stop
    assert_send_type "() -> void",
      ObjectSpace, :trace_object_allocations_stop
  end
end
