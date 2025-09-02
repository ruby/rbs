require "rbs"
require "benchmark/ips"
require "csv"

results = []

ARGV.each do |file|
  GC.start
  
  STDERR.puts "Benchmarking with #{file}..."
  content = File.read(file)

  benchmark = Benchmark.ips do |x|
    x.report(file) do
      RBS::Parser.parse_signature(content)
    end

    x.quiet = true
  end

  results << {
    file: file,
    size: content.bytesize,
    ips: benchmark.entries[0].ips,
    sd: benchmark.entries[0].ips_sd
  }
end

puts CSV.generate {|csv|
  csv << ["File", "Size", "IPS", "SD"]
  results.each do |result|
    csv << [result[:file], result[:size], result[:ips], result[:sd]]
  end
}
