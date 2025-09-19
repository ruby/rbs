require "rbs"
require "benchmark/ips"
require "csv"
require "pathname"

files = {}
ARGV.each do |file|
  content = File.read(file)
  files[file] = RBS::Buffer.new(content: content, name: Pathname(file))
end

puts "Benchmarking parsing #{files.size} files..."

Benchmark.ips do |x|
  x.report("batch parsing") do
    RBS::Parser._parse_signatures(files)
  end

  x.compare!
end
