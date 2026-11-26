source "https://rubygems.org"

# Specify your gem's dependencies in rbs.gemspec
gemspec

# Development dependencies
gem "rake"
gem "rake-compiler"
gem "test-unit"
gem "rspec"
gem "rubocop"
# regexp_parser 2.13.2 calls Ractor.make_shareable at load time, which trips a
# RUBY_ASSERT in Ruby 4.0.x (fixed in ruby/ruby master by [Bug #22460]).
# Remove this pin once the fix is backported to the ruby_4_0 branch.
gem "regexp_parser", "< 2.13.2"
gem "rubocop-rubycw"
gem "rubocop-on-rbs"
gem "json"
gem "json-schema"
gem 'digest'
gem 'tempfile'
gem "rdoc"
gem "fileutils"
gem "raap"
gem "extconf_compile_commands_json"
gem "irb"

group :libs do
  # Bundled gems required by tests
  gem "bigdecimal" # test/stdlib/json/JSONBigDecimal_test.rb
  gem "dbm" # test/stdlib/DBM_test.rb
  gem "mutex_m" # test/rbs/collection/config_test.rb expects the gem-bundled signatures to be found
end

group :profilers do
  # Performance profiling and benchmarking
  gem 'stackprof'
  gem 'memory_profiler'
  gem 'benchmark-ips'
end

# Test gems
gem "rbs-amber", path: "test/assets/test-gem"

# Bundled gems
gem "net-smtp"
gem 'csv'
gem 'ostruct'
gem 'pstore'
gem "timeout"

group :minitest do
  gem "minitest"
  gem "minitest-mock"
end

group :typecheck_test do
  gem "steep", require: false, git: "https://github.com/soutaro/steep.git"
end
