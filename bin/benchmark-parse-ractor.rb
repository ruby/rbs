require "rbs"
require "benchmark/ips"
require "benchmark"
require "csv"
require "rbs/ractor_pool"

require "optparse"

Ractor.new{}

label = nil #: String?
num_ractors = 4 #: Integer
scale = 1 #: Integer
batch = 30 #: Integer

OptionParser.new do |opts|
  opts.banner = "Usage: benchmark-parse-ractor.rb [options] [file|directory]..."

  opts.on("--label=LABEL", "Set the benchmark label") do |v|
    label = v
  end

  opts.on("--ractors=N", Integer, "Number of ractors to use (default: 4)") do |v|
    num_ractors = v
  end

  opts.on("--scale=N", Integer, "Scale the number of files by N times (default: 1)") do |v|
    scale = v
  end
end.parse!(ARGV)

file_names = []
files = {} # Store buffers for serial benchmark

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
  files[file] = RBS::Buffer.new(content: content, name: Pathname(file)).finalize
end

def ractor_map(objects, num_ractors, &block)
  port = Ractor::Port.new

  block = Ractor.shareable_proc(&block)

  ractors = num_ractors.times.map do
    Ractor.new(port, block, name: "worker-#{_1}") do |port, block|
      results = []
      port << Ractor.current

      while obj = Ractor.receive
        if obj == :result
          break
        else
          results << block[obj]
          port << Ractor.current
        end
      end

      results
    end
  end

  t = Thread.new do
    objects.each do |obj|
      ractor = port.receive
      ractor.send(obj)
    end

    ractors.each do |ractor|
      ractor.send(:result)
    end
  end

  t.join

  results = []

  ractors.each do |ractor|
    results.concat(ractor.value)
  end

  results
end

def single_parse(files)
  files.map do |buffer|
    RBS::Parser.parse_signature(buffer)
  end
end

bufs = files.values.dup
bufs = bufs * scale
bufs.freeze

puts "Benchmarking with #{bufs.size} files (scale=#{scale})"

Benchmark.ips do |x|
  x.report("serial") do
    buf, dirs, decls = single_parse(bufs)
    RBS::Source::RBS.new(buf, dirs, decls)
  end

  x.report("ractor_map(..., #{num_ractors})") do
    ractor_map(bufs, num_ractors) do |buf|
      buf, dirs, decls = RBS::Parser.parse_signature(buf)
      RBS::Source::RBS.new(buf, dirs, decls)
    end
  end

  # x.report("RactorPool.map(..., #{num_ractors})") do
  #   RBS::RactorPool.map(bufs, num_ractors) do |buf|
  #     buf, dirs, decls = RBS::Parser.parse_signature(buf)
  #     RBS::Source::RBS.new(buf, dirs, decls)
  #   end
  # end
end

