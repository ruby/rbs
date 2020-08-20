require "test_helper"

class RBS::EnvironmentLoaderTest < Minitest::Test
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

  def with_signatures
    mktmpdir do |path|
      path.join("models").mkdir
      path.join("models/person.rbs").write(<<-EOF)
class Person
end
      EOF

      path.join("controllers").mkdir
      path.join("controllers/people_controller.rbs").write(<<-EOF)
class PeopleController
end

class Object
end
      EOF

      yield path
    end
  end

  def test_loading_builtin_and_library_and_directory
    with_signatures do |path|
      loader = EnvironmentLoader.new()

      loader.add(library: "pathname")
      loader.add(path: path)

      env = Environment.new
      loader.load(env: env)

      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :BasicObject }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Pathname }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Person }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :PeopleController }
    end
  end

  def test_loading_without_stdlib
    with_signatures do |path|
      loader = EnvironmentLoader.new()
      loader.no_builtin!

      env = Environment.new
      loader.load(env: env)

      refute env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :BasicObject }
      refute env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Pathname }
    end
  end

  def test_loading_gem
    with_signatures do |path|
      loader = EnvironmentLoader.new()

      # We have racc gem as development dependency

      loader.add(library: "racc")

      assert_equal 1, loader.paths.size
      loader.paths[0].tap do |path|
        assert_instance_of EnvironmentLoader::GemPath, path
        assert_nil path.version
        assert_match %r{racc-\d.\d.\d+/sig$}, path.path.to_s
      end
    end
  end

  def test_loading_unknown_library
    with_signatures do |path|
      loader = EnvironmentLoader.new()

      assert_raises EnvironmentLoader::UnknownLibraryNameError do
        loader.add(library: "no_such_library")
      end

      assert_raises EnvironmentLoader::UnknownLibraryNameError do
        loader.add(library: "racc:0.0.0")
      end
    end
  end

  def test_gem_path_vendored
    with_signatures do |path|
      gem_root = path + "gems"
      gem_root.mkdir

      vendor_racc_path = gem_root + "racc"
      vendor_racc_path.mkdir
      (vendor_racc_path + "racc.rbs").write <<-CONTENT
DUMMY: String
      CONTENT

      loader = EnvironmentLoader.new(gem_vendor_path: gem_root)

      loader.add(library: "racc:0.0.0")

      racc_path = loader.paths.find {|path| path.name == "racc" }
      assert_equal gem_root + "racc", racc_path.path
    end
  end

  def test_load_twice
    env = Environment.new

    with_signatures do |path|
      EnvironmentLoader.new().tap do |loader|
        loadeds = loader.load(env: env)

        loadeds.each do |(decl, file_path, lib_path)|
          assert_operator decl, :is_a?, Declarations::Base
          assert_instance_of Pathname, file_path
          assert_equal :stdlib, lib_path
        end
      end

      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :BasicObject }

      EnvironmentLoader.new().no_builtin!.tap do |loader|
        loader.add(library: "pathname")
        loadeds = loader.load(env: env)

        assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Pathname }

        loadeds.each do |(decl, file_path, lib_path)|
          assert_operator decl, :is_a?, Declarations::Base
          assert_instance_of Pathname, file_path
          assert_instance_of EnvironmentLoader::LibraryPath, lib_path
          assert_equal 'pathname', lib_path.name
        end
      end

      EnvironmentLoader.new.no_builtin!.tap do |loader|
        loader.add(path: path)
        loadeds = loader.load(env: env)

        assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :PeopleController }

        loadeds.each do |(decl, file_path, lib_path)|
          assert_operator decl, :is_a?, Declarations::Base
          assert_instance_of Pathname, file_path
          assert_instance_of Pathname, lib_path
          assert_equal path, lib_path
        end
      end
    end
  end
end
