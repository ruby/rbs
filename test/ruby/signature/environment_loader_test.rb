require "test_helper"

class Ruby::Signature::EnvironmentLoaderTest < Minitest::Test
  Environment = Ruby::Signature::Environment
  EnvironmentLoader = Ruby::Signature::EnvironmentLoader
  Declarations = Ruby::Signature::AST::Declarations

  def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end

  def with_signatures
    mktmpdir do |path|
      path.join("models").mkdir
      path.join("models/person.rbi").write(<<-EOF)
class Person
end
      EOF

      path.join("controllers").mkdir
      path.join("controllers/people_controller.rbi").write(<<-EOF)
class PeopleController
end
      EOF

      yield path
    end
  end

  def test_loading_builtin_and_library_and_directory
    with_signatures do |path|
      env = Environment.new
      loader = EnvironmentLoader.new(env: env)

      loader.add(library: "pathname")
      loader.add(path: path)
      loader.load

      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :BasicObject }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Pathname }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Person }
      assert env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :PeopleController }
    end
  end

  def test_loading_without_stdlib
    with_signatures do |path|
      env = Environment.new
      loader = EnvironmentLoader.new(env: env, stdlib_root: nil)

      loader.load

      refute env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :BasicObject }
      refute env.declarations.any? {|decl| decl.is_a?(Declarations::Class) && decl.name.name == :Pathname }
    end
  end

  def test_loading_unknown_library
    with_signatures do |path|
      env = Environment.new
      loader = EnvironmentLoader.new(env: env)

      loader.add(library: "no_such_library")

      assert_raises do
        loader.load
      end
    end
  end
end
