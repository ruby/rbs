require "test_helper"

class Ruby::Signature::RuntimePrototypeTest < Minitest::Test
  Runtime = Ruby::Signature::Prototype::Runtime
  DefinitionBuilder = Ruby::Signature::DefinitionBuilder

  include TestHelper

  module TestTargets
    module Foo
      include Enumerable
    end

    class Test < String
      include Foo

      NAME = "Hello"

      def foo(foo, bar=1, *baz, a, b:, c: nil, **d)
      end

      alias bar foo

      private

      def a()
      end

      def self.baz(&block)
      end

      def self.b()
      end
    end
  end

  def test_1
    SignatureManager.new do |manager|
      manager.build do |env|
        p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::TestTargets::*"], env: env, merge: false)

        assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::TestTargets::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::TestTargets::Test < String
  include Foo

  def self.b: () -> untyped

  def self.baz: () { (*untyped) -> untyped } -> untyped

  public

  alias bar foo

  def foo: (untyped foo, ?untyped bar, *untyped baz, untyped a, b: untyped, ?c: untyped, **untyped) -> untyped

  private

  def a: () -> untyped
end

Ruby::Signature::RuntimePrototypeTest::TestTargets::Test::NAME: String
    EOF
      end
    end 
  end

  def test_merge_types
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Ruby::Signature::RuntimePrototypeTest::TestTargets::Test
  def self.baz: () -> void

  def foo: (String) -> Integer
         | (String, bool) { () -> void } -> [Symbol]

  def bar: () -> void
end
EOF

      manager.build do |env|
        p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::TestTargets::*"], env: env, merge: true)

        assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::TestTargets::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::TestTargets::Test < String
  include Foo

  def self.b: () -> untyped

  def self.baz: () -> void

  public

  alias bar foo

  def foo: (String) -> Integer
         | (String, bool) { () -> void } -> [Symbol]

  private

  def a: () -> untyped
end

Ruby::Signature::RuntimePrototypeTest::TestTargets::Test::NAME: String
        EOF
      end
    end
  end
end
