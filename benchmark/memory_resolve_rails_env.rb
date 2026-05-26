require_relative './utils'

require 'memory_profiler'

# See benchmark_resolve_type_names.rb for the scenario. Here we profile the
# allocations of a single edit-cycle resolve: one source is unloaded and added
# back (not profiled), then `resolve_type_names` is profiled on its own.

tmpdir = prepare_collection!

base_env = new_rails_env(tmpdir)
sample_source = base_env.each_rbs_source.first or raise

env = base_env.unload([sample_source.buffer])
env.add_source(sample_source)

_ = resolved = nil

r = MemoryProfiler.report do
  resolved = env.resolve_type_names
end

r.pretty_print
