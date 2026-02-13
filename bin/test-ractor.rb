require "benchmark"

# Simulate parsing work
def simulate_parse(content)
  # Simulate some CPU work
  sum = 0
  content.each_byte { |b| sum += b }
  sleep(0.001)  # Simulate parsing time
  sum
end

class RactorParser
  def initialize(count)
    @count = count
  end

  def parse(file_data)
    # Create workers that process files and return results
    workers = @count.times.map do |i|
      Ractor.new(name: "worker-#{i}") do
        results = []
        loop do
          input = Ractor.receive
          break if input == :done
          
          path, content = input
          result = simulate_parse(content)
          results << [:success, path, result]
        end
        results  # Return all results when done
      end
    end

    # Distribute work to workers
    file_data.each_with_index do |data, index|
      worker_index = index % @count
      workers[worker_index].send(data)
    end

    # Send done signal to all workers
    workers.each { |w| w.send(:done) }

    # Collect results from all workers
    all_results = []
    workers.each do |worker|
      results = worker.value
      all_results.concat(results)
    end
    
    all_results
  end
end

class SingleParser
  def parse(file_data)
    results = []
    file_data.each do |path, content|
      result = simulate_parse(content)
      results << [:success, path, result]
    end
    results
  end
end

# Create test data
file_data = []
20.times do |i|
  content = "This is test file #{i} with some content " * 100
  file_data << ["file#{i}.rbs", content]
end

puts "Testing Ractor work distribution with #{file_data.size} files..."

single_parser = SingleParser.new
ractor_parser = RactorParser.new(4)

single_time = Benchmark.realtime { single_parser.parse(file_data) }
puts "Serial: #{single_time.round(3)}s"

ractor_time = Benchmark.realtime { ractor_parser.parse(file_data) }
puts "Ractor (4 workers): #{ractor_time.round(3)}s"
puts "Speedup: #{(single_time / ractor_time).round(2)}x"