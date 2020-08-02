require "test_helper"

class ValidatorTest < Minitest::Test
  include TestHelper

  Environment = RBS::Environment
  Namespace = RBS::Namespace
  InvalidTypeApplicationError = RBS::InvalidTypeApplicationError

  def test_validate
    SignatureManager.new do |manager|
      manager.add_file("foo.rbs", <<-EOF)
class Array[A]
end

class String::Foo
end

class Foo
end

type Foo::Bar::Baz::t = Integer

type ty = String | Integer
      EOF

      manager.build do |env|
        root = [Namespace.root]

        resolver = RBS::TypeNameResolver.from_env(env)
        validator = RBS::Validator.new(env: env, resolver: resolver)

        validator.validate_type(parse_type("::Foo"), context: root)
        validator.validate_type(parse_type("::String::Foo"), context: root)

        validator.validate_type(parse_type("Array[String]"), context: root)

        assert_raises InvalidTypeApplicationError do
          validator.validate_type(parse_type("Array"), context: root)
        end

        assert_raises InvalidTypeApplicationError do
          validator.validate_type(parse_type("Array[1,2,3]"), context: root)
        end

        validator.validate_type(parse_type("::ty"), context: root)

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("::ty2"), context: root)
        end

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("catcat"), context: root)
        end

        assert_raises RBS::NoTypeFoundError do
          validator.validate_type(parse_type("::_NoSuchInterface"), context: root)
        end
      end
    end
  end
end
