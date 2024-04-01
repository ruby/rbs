require "rbs"
require 'tmpdir'

def prepare_collection!
  tmpdir = Pathname(Dir.mktmpdir)
  at_exit { tmpdir.rmtree }

  tmpdir.join('Gemfile').write(<<~RUBY)
    source "https://rubygems.org"
    gem 'rails'
  RUBY
  Bundler.with_original_env do
    system('bundle', 'lock', chdir: tmpdir.to_s)
    system('rbs', 'collection', 'init', chdir: tmpdir.to_s)
    system('rbs', 'collection', 'install', chdir: tmpdir.to_s)
  end

  tmpdir
end

def new_env
  loader = RBS::EnvironmentLoader.new()
  yield loader if block_given?
  RBS::Environment.from_loader(loader).resolve_type_names
end

def new_rails_env(collection_dir)
  new_env do |loader|
    lock_path = collection_dir.join('rbs_collection.lock.yaml')
    lock = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lock_path, data: YAML.load_file(lock_path.to_s))
    loader.add_collection(lock)
  end
end
