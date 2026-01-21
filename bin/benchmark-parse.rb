require "rbs"
require "benchmark/ips"
require "csv"

require "optparse"

label = nil #: String?

OptionParser.new do |opts|
  opts.banner = "Usage: benchmark-parse.rb [options] [file|directory]..."

  opts.on("--label=LABEL", "Set the benchmark label") do |v|
    label = v
  end
end.parse!(ARGV)

file_names = []
files = {}
ARGV.each do |file|
  path = Pathname(file)
  if path.directory?
    Pathname.glob(path.join("**", "*.rbs")).each do |p|
      file_names << p.to_s
    end
  else
    file_names << path.to_s
  end
end

file_names.uniq.each do |file|
  content = File.read(file)
  files[file] = RBS::Buffer.new(content: content, name: Pathname(file))
end

puts "Benchmarking RBS(#{RBS::VERSION} in #{Bundler.default_gemfile.basename}#{label ? " (#{label})" : ""}) parsing with #{files.size} files..."

result = Benchmark.ips do |x|
  x.report("parsing") do
    files.each do |file, content|
      RBS::Parser.parse_signature(content)
    end
  end

  x.quiet = true
end

entry = result.entries[0]
puts "✅ #{"%0.3f" % entry.ips} i/s (±#{"%0.3f" % entry.error_percentage}%)"
