require 'rbs'
require "optparse"

wait = false
duration = 3

args = ARGV.dup

OptionParser.new do |opts|
  opts.banner = "Usage: profile-parse.rb [options] FILE"

  opts.on("--wait", "Wait for enter before starting") do
    wait = true
  end
  opts.on("--duration=NUMBER", "Repeat parsing for <NUMBER> seconds") do |number|
    duration = number.to_i
  end
end.parse!(args)

if wait
  puts "⏯️ Waiting for enter to continue at #{Process.pid}..."
  STDIN.gets  
end

file = args.shift or raise "No file path is given"
sig = File.read(file)

puts "Parsing #{file} -- #{sig.bytesize} bytes"

started_at = Time.now
count = 0

loop do
  count += 1
  RBS::Parser.parse_signature(sig)
  break if (Time.now - started_at) > duration
end

puts "✅ Done #{count} loop(s)"