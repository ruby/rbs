require_relative './utils'

tmpdir = prepare_collection!

require 'memory_profiler'

env = nil

r = MemoryProfiler.report do
  env = new_rails_env(tmpdir)
end

r.pretty_print
