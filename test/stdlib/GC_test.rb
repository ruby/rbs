require_relative 'test_helper'

class GCSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::GC)"

  def test_INTERNAL_CONSTANTS
    assert_const_type 'Hash[Symbol, untyped]',
                      'GC::INTERNAL_CONSTANTS'
  end

  def test_OPTS
    assert_const_type 'Array[String]',
                      'GC::OPTS'
  end

  def test_count
    assert_send_type  '() -> Integer',
                      GC, :count
  end

  def test_disable
    was_disabled = GC.disable

    assert_send_type  '() -> bool',
                      GC, :disable
  ensure
    GC.enable unless was_disabled
  end

  def test_enable
    was_enabled = GC.enable

    assert_send_type  '() -> bool',
                      GC, :enable
  ensure
    GC.disable unless was_enabled
  end

  def test_start
    assert_send_type  '() -> nil',
                      GC, :start
    
    # Don't test all combinations of passing args or not, just use them all
    with_boolish do |boolish|
      assert_send_type  '(immediate_sweep: boolish, immediate_mark: boolish, full_mark: boolish) -> nil',
                        GC, :start, immediate_sweep: boolish, immediate_mark: boolish, full_mark: boolish
    end
  end

  def test_stat
    assert_send_type  '() -> Hash[Symbol, untyped]',
                      GC, :stat
    assert_send_type  '(Hash[Symbol, untyped]) -> Hash[Symbol, untyped]',
                      GC, :stat, {}
    assert_send_type  '(nil) -> Hash[Symbol, untyped]',
                      GC, :stat, nil
    assert_send_type  '(Symbol) -> Integer',
                      GC, :stat, :count
  end

  def test_stress_and_stress=
    old_stress = GC.stress

    assert_send_type  '() -> (Integer | bool)',
                      GC, :stress
    assert_send_type  '(Integer) -> Integer',
                      GC, :stress=, 0
    assert_send_type  '() -> Integer',
                      GC, :stress

    with true, false do |bool|
      assert_send_type  '(bool) -> bool',
                        GC, :stress=, bool
      assert_send_type  '() -> bool',
                        GC, :stress
    end
  ensure
    GC.stress = old_stress
  end

  def test_total_time
    assert_send_type  '() -> Integer',
                      GC, :total_time
  end

  def test_compact
    assert_send_type  '() -> GC::compact_info',
                      GC, :compact
  end

  def test_verify_compaction_references
    assert_send_type  '() -> GC::compact_info',
                      GC, :verify_compaction_references
  end

  def test_verify_internal_consistency
    assert_send_type  '() -> nil',
                      GC, :verify_internal_consistency
  end

  def test_latest_gc_info
    assert_send_type  '() -> Hash[Symbol, untyped]',
                      GC, :latest_gc_info
    assert_send_type  '(nil) -> Hash[Symbol, untyped]',
                      GC, :latest_gc_info, nil
    assert_send_type  '(Hash[Symbol, untyped]) -> Hash[Symbol, untyped]',
                      GC, :latest_gc_info, {}

    assert_send_type  '(Symbol) -> untyped',
                      GC, :latest_gc_info, :major_by
  end

  def test_auto_compact
    assert_send_type  '() -> bool',
                      GC, :auto_compact
  end

  def test_auto_compact=
    old = GC.auto_compact


    with_untyped do |untyped|
      assert_send_type  '[T] (T) -> T',
                        GC, :auto_compact=, untyped
    end
  ensure
    GC.auto_compact = old
  end

  def test_latest_compact_info
    assert_send_type  '() -> GC::compact_info',
                      GC, :latest_compact_info
  end

  def test_measure_total_time
    assert_send_type  '() -> bool',
                      GC, :measure_total_time
  end

  def test_measure_total_time=
    old = GC.measure_total_time

    with_untyped do |untyped|
      assert_send_type  '[T] (T) -> T',
                        GC, :measure_total_time=, untyped
    end
  ensure
    GC.measure_total_time = old
  end
end

class GCIncludeTest < Test::Unit::TestCase
  include TestHelper

  testing '::GC'

  class Foo
    extend GC
  end

  def test_garbage_collect
    assert_send_type  '() -> nil',
                      Foo, :garbage_collect
    
    # Don't test all combinations of passing args or not, just use them all
    with_boolish do |boolish|
      assert_send_type  '(immediate_sweep: boolish, immediate_mark: boolish, full_mark: boolish) -> nil',
                        Foo, :garbage_collect, immediate_sweep: boolish, immediate_mark: boolish, full_mark: boolish
    end
  end
end

class GC_ProfilerSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::GC::Profiler)'

  def test_clear
    assert_send_type  '() -> nil',
                      GC::Profiler, :clear
  end

  def test_enabled?
    assert_send_type  '() -> bool',
                      GC::Profiler, :enabled?
  end

  def test_enable_and_disable
    was_enabled = GC::Profiler.enabled?

    assert_send_type  '() -> nil',
                      GC::Profiler, :enable
    assert_send_type  '() -> nil',
                      GC::Profiler, :disable
  ensure
    GC::Profiler.enable if was_enabled
  end

  def test_raw_data
    was_enabled = GC::Profiler.enabled?
    GC::Profiler.disable

    assert_send_type  '() -> nil',
                      GC::Profiler, :raw_data

    GC::Profiler.enable
    GC.start
    assert_send_type  '() -> Array[Hash[Symbol, untyped]]',
                      GC::Profiler, :raw_data
  ensure
    GC::Profiler.enable if was_enabled
  end

  def test_report
    old_stdout = $stdout
    new_stdout = BlankSlate.new
    def new_stdout.write(x) = nil
    $stdout = new_stdout

    assert_send_type  '() -> nil',
                      GC::Profiler, :report

    assert_send_type  '(GC::Profiler::_Reporter) -> nil',
                      GC::Profiler, :report, Writer.new
  ensure
    $stdout = old_stdout
  end

  def test_result
    assert_send_type  '() -> String',
                      GC::Profiler, :result
  end

  def test_total_time
    assert_send_type  '() -> Float',
                      GC::Profiler, :total_time
  end
end
