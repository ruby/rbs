# frozen_string_literal: true

require "benchmark/ips"
require_relative "../lib/rbs"

# Collect Ruby source files to parse
sources = Dir.glob(File.join(__dir__, "../lib/**/*.rb")).map do |path|
  [path, File.read(path)]
end

puts "Benchmarking prototype generation (#{sources.size} files, #{sources.sum { |_, s| s.size }} bytes total)"
puts

Benchmark.ips do |x|
  x.report("RB: RubyVM::AbstractSyntaxTree") do
    ENV.delete("RBS_RUBY_PARSER")
    sources.each do |_path, source|
      parser = RBS::Prototype::RB.new
      parser.parse(source)
      parser.decls
    end
  end

  x.report("RB: Prism") do
    ENV["RBS_RUBY_PARSER"] = "prism"
    sources.each do |_path, source|
      parser = RBS::Prototype::RB.new
      parser.parse(source)
      parser.decls
    end
  end

  x.compare!
ensure
  ENV.delete("RBS_RUBY_PARSER")
end
