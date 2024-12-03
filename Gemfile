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
gem 'digest'
gem 'tempfile'
gem "rdoc"
gem "fileutils"
gem "raap"

group :libs do
  # Libraries required for stdlib test
  gem "abbrev"
  gem "base64"
  gem "bigdecimal"
  gem "dbm"
  gem "mutex_m"
  gem "nkf"
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

group :minitest do
  gem "minitest"
end

group :typecheck_test do
  gem "steep", "~> 1.8.0.pre", require: false
end
