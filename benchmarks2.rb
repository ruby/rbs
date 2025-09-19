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
  x.report("parsing") do
    files.each do |file, content|
      RBS::Parser.parse_signature(content)
    end
  end

  x.compare!
end
