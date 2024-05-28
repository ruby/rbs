require_relative './utils'

require 'benchmark/ips'

tmpdir = prepare_collection!

Benchmark.ips do |x|
  x.time = 10

  x.report("new_env") do
    new_env
  end

  x.report("new_rails_env") do
    new_rails_env(tmpdir)
  end
end
