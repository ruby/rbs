#!/usr/bin/env ruby

$LOAD_PATH << File.join(__dir__, "../lib")

require "set"

IS_LATEST_RUBY = Gem::Version.new(RUBY_VERSION).yield_self do |ruby_version|
  Gem::Version.new('3.3.0') <= ruby_version && ruby_version < Gem::Version.new('3.4.0')
end

unless IS_LATEST_RUBY
  unless ENV["CI"]
    STDERR.puts "⚠️⚠️⚠️⚠️ stdlib test assumes Ruby 3.3 but RUBY_VERSION==#{RUBY_VERSION} ⚠️⚠️⚠️⚠️"
  end
end

KNOWN_FAILS = %w(dbm mutex_m).map do |lib|
  /cannot load such file -- #{lib}/
end

ARGV.each do |arg|
  begin
    load arg
  rescue LoadError => exn
    if KNOWN_FAILS.any? {|pat| pat =~ exn.message }
      STDERR.puts "Loading #{arg} failed, ignoring it: #{exn.inspect}"
    else
      raise
    end
  end
end
