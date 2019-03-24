require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

rule ".rb" => ".y" do |t|
  sh "racc -v -o #{t.name} #{t.source}"
end

task :parser => "lib/ruby/signature/parser.rb"
task :test => :parser
task :build => :parser

CLEAN.include("lib/ruby/signature/parser.rb")
