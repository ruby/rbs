require "test_helper"

class RBS::EnvironmentLoaderTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  Declarations = RBS::AST::Declarations
  TypeName = RBS::TypeName
  Namespace = RBS::Namespace

  def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end

  def write_signatures(path:)
    path.join("models").mkdir
    path.join("models/person.rbs").write(<<-RBS)
class Person
end
    RBS

    path.join("controllers").mkdir
    path.join("controllers/people_controller.rbs").write(<<-RBS)
class PeopleController
end
    RBS

    path.join("_private").mkdir
    path.join("_private/person.rbs").write(<<-RBS)
class Person::Internal
end
    RBS
  end

  def test_loading_empty
    loader = EnvironmentLoader.new

    env = Environment.new
    loaded = loader.load(env: env)

    assert loaded.all? {|_, _, path_type| path_type == :core }
  end

  def test_loading_no_core
    loader = EnvironmentLoader.new(core_root: nil)

    env = Environment.new()
    loaded = loader.load(env: env)

    assert_empty loaded
  end

  def test_loading_dir
    mktmpdir do |path|
      write_signatures(path: path)

      loader = EnvironmentLoader.new
      loader.add(path: path)

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Person")
      assert_operator env.class_decls, :key?, TypeName("::PeopleController")
      assert_operator env.class_decls, :key?, TypeName("::Person::Internal")
    end
  end

  def test_loading_stdlib
    mktmpdir do |path|
      loader = EnvironmentLoader.new
      loader.add(library: "uri")

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::URI")
    end
  end

  def test_loading_rubygems
    RBS.logger_output = io = StringIO.new
    mktmpdir do |path|
      loader = EnvironmentLoader.new
      loader.add(library: "rubygems")

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Gem")
      assert io.string.include?('`rubygems` has been moved to core library')
    end
  ensure
    RBS.logger_output = nil
  end

  def test_loading_library_from_gem_repo
    mktmpdir do |path|
      (path + "gems").mkdir
      (path + "gems/gem1").mkdir
      (path + "gems/gem1/1.2.3").mkdir

      write_signatures(path: path + "gems/gem1/1.2.3")

      repo = RBS::Repository.new()
      repo.add(path + "gems")

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "gem1", version: "1.2.3")

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Person")
      assert_operator env.class_decls, :key?, TypeName("::PeopleController")
      refute_operator env.class_decls, :key?, TypeName("::Person::Internal")
    end
  end

  def test_loading_unknown_library
    repo = RBS::Repository.new()

    loader = EnvironmentLoader.new(repository: repo)
    loader.add(library: "gem1", version: "1.2.3")

    env = Environment.new

    assert_raises EnvironmentLoader::UnknownLibraryError do
      loader.load(env: env)
    end
  end

  def test_loading_twice
    mktmpdir do |path|
      write_signatures(path: path)

      loader = EnvironmentLoader.new
      loader.add(path: path)
      loader.add(path: path + "models")

      env = Environment.new
      loaded = loader.load(env: env)

      assert_equal 1, loaded.count {|decl, _, _| decl.respond_to?(:name) && decl.name == TypeName("Person") }
    end
  end

  def test_loading_from_gem
    omit "Test gem `rbs-amber` is unavailable" unless has_gem?("rbs-amber")

    mktmpdir do |path|
      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "rbs-amber", version: nil)

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Amber")
    end
  end

  def test_loading_from_gem_without_rbs
    omit if skip_minitest?

    mktmpdir do |path|
      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "non_existent_gems", version: nil)

      env = Environment.new

      assert_raises EnvironmentLoader::UnknownLibraryError do
        loader.load(env: env)
      end
    end
  end

  def test_loading_dependencies
    mktmpdir do |path|
      loader = EnvironmentLoader.new
      loader.add(library: "psych")

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Psych")
      assert_operator env.class_decls, :key?, TypeName("::DBM")
      assert_operator env.class_decls, :key?, TypeName("::PStore")
    end
  end

  def test_loading_from_rbs_collection
    mktmpdir do |path|
      lockfile_path = path.join('rbs_collection.lock.yaml')
      lockfile_path.write(<<~YAML)
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: '.gem_rbs_collection'
        gems:
          - name: ast
            version: "2.4"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: StringIO.new).install_from_lockfile
      lock = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lockfile_path, data: YAML.load_file(lockfile_path))

      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)
      loader.add_collection(lock)

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::AST")
      assert_operator env.class_decls, :key?, TypeName("::Rainbow")
      assert repo.dirs.include? lock.fullpath
    end
  end

  def test_loading_from_rbs_collection__gem_version_mismatch
    omit "Test gem `rbs-amber` is unavailable" unless has_gem?("rbs-amber")
    
    mktmpdir do |path|
      lockfile_path = path.join('rbs_collection.lock.yaml')
      lockfile_path.write(<<~YAML)
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: '.gem_rbs_collection'
        gems:
          - name: rbs-amber
            version: "1.1"
            source:
              type: "rubygems"
      YAML
      RBS::Collection::Installer.new(lockfile_path: lockfile_path, stdout: StringIO.new).install_from_lockfile
      lock = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lockfile_path, data: YAML.load_file(lockfile_path))

      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)

      io = StringIO.new
      old_output = RBS.logger_output
      RBS.logger_output = io
      begin
        loader.add_collection(lock)
        env = Environment.new
        loader.load(env: env)
      ensure
        RBS.logger_output = old_output
      end

      assert_operator(
        io.string,
        :include?,
        "Loading type definition from gem `rbs-amber-1.0.0` because locked version `1.1` is unavailable. Try `rbs collection update` to fix the (potential) issue."
      )
    end
  end

  def test_loading_from_rbs_collection_git_source_without_install
    mktmpdir do |path|
      lockfile_path = path.join('rbs_collection.lock.yaml')
      lockfile_path.write(<<~YAML)
        sources:
          - name: ruby/gem_rbs_collection
            remote: https://github.com/ruby/gem_rbs_collection.git
            revision: b4d3b346d9657543099a35a1fd20347e75b8c523
            repo_dir: gems
        path: '.gem_rbs_collection'
        gems:
          - name: ast
            version: "2.4"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
          - name: rainbow
            version: "3.0"
            source:
              name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
              type: git
      YAML
      lock = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lockfile_path, data: YAML.load_file(lockfile_path.to_s))

      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)

      assert_raises RBS::Collection::Config::CollectionNotAvailable do
        loader.add_collection(lock)
      end
    end
  end

  def test_loading_from_rbs_collection_local_source_without_install
    mktmpdir do |path|
      lockfile_path = path.join('rbs_collection.lock.yaml')
      lockfile_path.write(<<~YAML)
        sources:
          - type: local
            name: the local source
            path: path/to/local/source
        path: '.gem_rbs_collection'
        gems:
          - name: ast
            version: "2.4"
            source:
              type: local
              name: the local source
              path: path/to/local/source
      YAML
      lock = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path: lockfile_path, data: YAML.load_file(lockfile_path.to_s))

      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)

      assert_raises RBS::Collection::Config::CollectionNotAvailable do
        loader.add_collection(lock)
      end
    end
  end
end
