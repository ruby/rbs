require_relative "test_helper"
require "benchmark"

class BenchmarkTest < StdlibTest
  target Benchmark
  library "benchmark"

  using hook.refinement

  include Benchmark

  def test_benchmark
    n = 50
    Benchmark.benchmark(CAPTION, 7, FORMAT, ">total:", ">avg:") do |x|
      tf = x.report("for:")   { for i in 1..n; a = "1"; end }
      tt = x.report("times:") { n.times do   ; a = "1"; end }
      tu = x.report("upto:")  { 1.upto(n) do ; a = "1"; end }
      [tf+tt+tu, (tf+tt+tu)/3]
    end
  end
end
