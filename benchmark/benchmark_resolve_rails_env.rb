require_relative './utils'

require 'benchmark/ips'

# `resolve_type_names` absolutizes every type name in the environment. The
# first resolve must do that work, but long-running clients such as Steep
# re-resolve on every edit: they unload the edited source, re-add it, and
# resolve again. This benchmark reproduces that edit cycle -- unload one
# source, add it back, then resolve -- which is the path that benefits from
# reusing declarations whose type names did not change.

tmpdir = prepare_collection!

base_env = new_rails_env(tmpdir)
sample_source = base_env.each_rbs_source.first or raise

Benchmark.ips do |x|
  x.time = 10

  x.report("resolve_type_names") do
    env = base_env.unload([sample_source.buffer])
    env.add_source(sample_source)
    env.resolve_type_names
  end
end
