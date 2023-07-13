require_relative "test_helper"

class GCTest < StdlibTest
  target GC

  include GC

  def test_garbage_collect
    garbage_collect
    garbage_collect(full_mark: true)
    garbage_collect(full_mark: false)
    garbage_collect(immediate_mark: true)
    garbage_collect(immediate_mark: false)
    garbage_collect(immediate_sweep: true)
    garbage_collect(immediate_sweep: false)
  end

  def test_start
    GC.start
    GC.start(full_mark: true)
    GC.start(full_mark: false)
    GC.start(immediate_mark: true)
    GC.start(immediate_mark: false)
    GC.start(immediate_sweep: true)
    GC.start(immediate_sweep: false)
  end

  def test_compact
    GC.compact
  end

  def test_verify_compaction_references
    GC.verify_compaction_references
  end

  def test_verify_internal_consistency
    GC.verify_internal_consistency
  end

  def test_latest_gc_info
    GC.latest_gc_info
    GC.latest_gc_info({})
    GC.latest_gc_info(:state)
  end

  def test_set_stress
    GC.stress = 0
    GC.stress = true
    GC.stress = false
  end
end


class GCSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::GC)"

  def test_total_time
    assert_send_type(
      "() -> Integer",
      GC, :total_time
    )
  end
end
