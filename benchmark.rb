require "bundler/setup"

require 'rbs'
require 'benchmark/ips'

sig = Pathname('/Users/soutaro/Downloads/activerecord-generated.rbs').read
Benchmark.ips do |x|
  x.report("rbs v#{RBS::VERSION} parse activerecord-generated.rbs") do
    RBS::Parser.parse_signature(sig)
  end
end
