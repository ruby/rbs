require_relative './utils'

require 'memory_profiler'

_ = env = nil

r = MemoryProfiler.report do
  env = new_env
end

r.pretty_print
