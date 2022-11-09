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
gem "json"
gem "json-schema"
gem 'stackprof'
gem "goodcheck"
gem "dbm"
gem 'digest'
gem 'tempfile'
gem "prime"
gem "rdoc"

# Test gems
path "test/assets/test-gem" do
  gem "rbs-amber"
  gem "rbs-load_implicit_false"
  gem "rbs-depends_on_load_implicit_false"
end

group :ide, optional: true do
  gem "ruby-debug-ide"
  gem "debase", ">= 0.2.5.beta2"
end

group :minitest do
  gem "minitest"
end
