require_relative "test_helper"

class GCTest < StdlibTest
  target GC
  using hook.refinement

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

  if RUBY_27_OR_LATER
    def test_compact
      GC.compact
    end
  end

  def test_latest_gc_info
    GC.latest_gc_info
    GC.latest_gc_info({})
    GC.latest_gc_info(:state)
  end
end
