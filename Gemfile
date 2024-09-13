source "https://rubygems.org"

# Specify your gem's dependencies in rbs.gemspec
gemspec

# Development dependencies
gem "rake"
gem "rake-compiler"
gem "test-unit"
gem "rspec"
gem "rubocop"
gem "rubocop-rubycw"
gem "rubocop-on-rbs" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.1')
gem "json"
gem "json-schema"
gem "goodcheck"
gem "dbm"
gem 'digest'
gem 'tempfile'
gem "rdoc"
gem "bigdecimal"
gem "abbrev"
gem "base64"
gem "mutex_m"
gem "nkf"
gem "fileutils"
gem "raap"

# Performance profiling and benchmarking
gem 'stackprof'
gem 'memory_profiler'
gem 'benchmark-ips'

# Test gems
gem "rbs-amber", path: "test/assets/test-gem"

# Bundled gems
gem "net-smtp"
gem 'csv'

group :minitest do
  gem "minitest"
end

group :typecheck_test do
  gem "steep", "~> 1.7.1", require: false
end
