require "rbs"
require "benchmark/ips"
require "benchmark"
require "csv"
require "rbs/ractor_pool"

require "optparse"

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

  opts.on("--batch=N", Integer, "Number of files to send per ractor (default: 30)") do |v|
    batch = v
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

# # class RactorParser
# #   attr_reader :workers

# #   attr_reader :result_port, :queue_port

# #   def initialize(count)
# #     @count = count

# #     @result_port = Ractor::Port.new()
# #     @queue_port = Ractor::Port.new()

# #     @workers = count.times.map do |i|
# #       Ractor.new(result_port, queue_port, name: "worker-#{i}") do |result_port, queue_port|
# #         while buffer = Ractor.receive
# #           case buffer
# #           when :start
# #             queue_port << Ractor.current
# #           else
# #             # ms = Benchmark.realtime do
# #             buffer.each do |buf|
# #               result = RBS::Parser.parse_signature(buf)
# #             # out_port << [Ractor.current, result]
# #             # out_port << [Ractor.current, result]
# #             # Ractor.shareable?(result) or raise "Parsing result of #{buffer.name} is not shareable"
# #             # Ractor.make_shareable(result) or raise
# #               result_port << result
# #             end
# #             # end

# #             # puts "[#{Ractor.current.name}] Parsed #{buffer.size} files in #{(ms * 1000).round} ms"
# #             queue_port << Ractor.current
# #             # out_port.send([Ractor.current, buffer], move: true)
# #             # out_port.send([Ractor.current, Ractor.make_shareable(result)], move: false)
# #           end
# #         end
# #       end
# #     end
# #   end

#   def parse(buffers, batch)
#     results = []

#     workers.each do |worker|
#       worker.send :start
#     end

#     input_thread = Thread.new do
#       buffers.each_slice(batch) do |bufs|
#         ractor = queue_port.receive
#         ractor.send bufs
#       end
#     end

#     while buffers.size > results.size
#       sig = result_port.receive
#       results << sig
#     end

#     input_thread.join

#     results
#   end
# end

class SingleParser
  def parse(files)
    files.map do |buffer|
      RBS::Parser.parse_signature(buffer)
    end
  end
end

bufs = files.values.dup
bufs = bufs * scale
bufs.freeze

puts "Benchmarking with #{bufs.size} files (scale=#{scale})"

Benchmark.ips do |x|
  single = SingleParser.new

  (2..10).reverse_each do |i|
    x.report("map #{i} ractors") do
      RBS::RactorPool.map(bufs, i) { RBS::Parser.parse_signature(_1) }
    end
    x.report("each #{i} ractors") do
      pool = RBS::RactorPool.new(i) { RBS::Parser.parse_signature(_1) }
      pool.each(bufs) { nil }
    end
  end

  # (2..10).reverse_each do |i|
  # end

  x.report("serial") do
    single.parse(bufs)
  end
end

