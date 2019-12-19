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
end
