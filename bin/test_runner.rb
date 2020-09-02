#!/usr/bin/env ruby

$LOAD_PATH << File.join(__dir__, "../lib")

STDLIB_TEST = Gem::Version.new(RUBY_VERSION).yield_self do |ruby_version|
  Gem::Version.new('2.7.0') <= ruby_version &&
    ruby_version <= Gem::Version.new('2.8.0')
end

unless STDLIB_TEST
  unless ENV["FORCE_STDLIB_TEST"]
    STDERR.puts "🚨🚨🚨 stdlib test requires Ruby 2.7 or later but RUBY_VERSION==#{RUBY_VERSION}, exiting... 🚨🚨🚨"
    exit
  end
end

ARGV.each do |arg|
  load arg
end
