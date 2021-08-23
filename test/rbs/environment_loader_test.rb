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
      loader.add(library: "set")

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Set")
    end
  end

  def test_loading_library_from_gem_repo
    mktmpdir do |path|
      (path + "gems/gem1/1.2.3").mkpath
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

      assert_equal 1, loaded.count {|decl, _, _| decl.name == TypeName("Person") }
    end
  end

  def test_loading_from_gem
    omit unless has_gem?("rbs-amber")

    mktmpdir do |path|
      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "rbs-amber", version: nil)

      env = Environment.new
      loader.load(env: env)

      assert_operator env.class_decls, :key?, TypeName("::Amber")
    end
  end

  def test_loading_from_gem_and_repo
    omit unless has_gem?("rbs-amber")

    mktmpdir do |path|
      (path + "gems/rbs-amber/1.2.3").mkpath
      write_signatures(path: path + "gems/rbs-amber/1.2.3")

      repo = RBS::Repository.new()
      repo.add(path + "gems")

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "rbs-amber", version: nil)

      env = Environment.new
      loader.load(env: env)

      # repo takes precedence over sig/ in gem package
      # in order to override RBS in gem package
      refute_operator env.class_decls, :key?, TypeName("::Amber")
      assert_operator env.class_decls, :key?, TypeName("::Person")
      assert_operator env.class_decls, :key?, TypeName("::PeopleController")
    end
  end

  def test_loading_from_gem_without_rbs
    omit if skip_minitest?

    mktmpdir do |path|
      repo = RBS::Repository.new()

      loader = EnvironmentLoader.new(repository: repo)
      loader.add(library: "minitest", version: nil)

      env = Environment.new

      assert_raises EnvironmentLoader::UnknownLibraryError do
        loader.load(env: env)
      end
    end
  end
end
