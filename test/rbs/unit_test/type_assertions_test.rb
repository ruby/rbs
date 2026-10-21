require "test_helper"
require "rbs/unit_test"

class RBS::UnitTest::TypeAssertionsTest < Test::Unit::TestCase
  include RBS::UnitTest::TypeAssertions

  class Foo
    def self.make_correct
      new
    end

    def self.make_wrong
      Foo.new
    end

    def copy_correct
      dup
    end

    def copy_wrong
      Foo.new
    end
  end

  class SubFoo < Foo
  end

  SIGNATURE = <<~RBS
    module RBS
      module UnitTest
        class TypeAssertionsTest
          class Foo
            def self.make_correct: () -> instance
            def self.make_wrong: () -> instance

            def copy_correct: () -> self
            def copy_wrong: () -> self
          end

          class SubFoo < Foo
          end
        end
      end
    end
  RBS

  def self.env
    @env ||= begin
      env = RBS::Environment.from_loader(RBS::EnvironmentLoader.new)
      buffer = RBS::Buffer.new(name: "foo.rbs", content: SIGNATURE)
      _, directives, decls = RBS::Parser.parse_signature(buffer)
      env.add_source(RBS::Source::RBS.new(buffer, directives, decls))
      env.resolve_type_names
    end
  end

  def test_singleton_instance_type_on_subclass_receiver
    testing "singleton(::RBS::UnitTest::TypeAssertionsTest::Foo)" do
      assert_send_type "() -> RBS::UnitTest::TypeAssertionsTest::SubFoo", SubFoo, :make_correct

      assert_raise Test::Unit::AssertionFailedError do
        assert_send_type "() -> RBS::UnitTest::TypeAssertionsTest::Foo", SubFoo, :make_wrong
      end
    end
  end

  def test_error_on_subclass_receiver
    testing "::RBS::UnitTest::TypeAssertionsTest::Foo" do
      error = assert_raise Test::Unit::AssertionFailedError do
        assert_send_type "() -> Integer", SubFoo.new, :copy_wrong
      end
      # The `testing` target is the subject of the error, and the receiver class is noted
      assert_include error.message, "[RBS::UnitTest::TypeAssertionsTest::Foo#copy_wrong] ReturnTypeError: expected `Integer` but returns"
      assert_include error.message, "(receiver: RBS::UnitTest::TypeAssertionsTest::SubFoo)"
    end

    testing "singleton(::RBS::UnitTest::TypeAssertionsTest::Foo)" do
      error = assert_raise Test::Unit::AssertionFailedError do
        assert_send_type "() -> Integer", SubFoo, :make_wrong
      end
      assert_include error.message, "[RBS::UnitTest::TypeAssertionsTest::Foo.make_wrong] ReturnTypeError: expected `Integer` but returns"
      assert_include error.message, "(receiver: RBS::UnitTest::TypeAssertionsTest::SubFoo)"
    end
  end

  def test_instance_self_type_on_subclass_receiver
    testing "::RBS::UnitTest::TypeAssertionsTest::Foo" do
      assert_send_type "() -> RBS::UnitTest::TypeAssertionsTest::SubFoo", SubFoo.new, :copy_correct

      assert_raise Test::Unit::AssertionFailedError do
        assert_send_type "() -> RBS::UnitTest::TypeAssertionsTest::Foo", SubFoo.new, :copy_wrong
      end
    end
  end
end
