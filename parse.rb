# require "bundler/setup"

require 'rbs'
# require 'benchmark/ips'

if (opt = ARGV[0]) == "--wait"
  ARGV.shift
  puts "⏯️ Waiting for enter to continue at #{Process.pid}..."
  STDIN.gets
end

file = ARGV.shift
sig = File.read(file)

puts "#{file} -- #{sig.bytesize} bytes"

started_at = Time.now
secs = 3

loop do
  RBS::Parser.parse_signature(sig)
  break if (Time.now - started_at) > secs
end