require "test_helper"

class Ruby::Signature::RuntimePrototypeTest < Minitest::Test
  Runtime = Ruby::Signature::Prototype::Runtime
  DefinitionBuilder = Ruby::Signature::DefinitionBuilder

  include TestHelper

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

  def test_1
    p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::*"], env: nil, missing_only: false, merge: false)

    assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::Test < String
  include Foo

  def self.b: () -> untyped

  def self.baz: () { (*untyped) -> untyped } -> untyped

  public

  alias bar foo

  def foo: (untyped foo, ?untyped bar, *untyped baz, untyped a, b: untyped, ?c: untyped, **untyped) -> untyped

  private

  def a: () -> untyped
end

Ruby::Signature::RuntimePrototypeTest::Test::NAME: String
    EOF
  end

  def test_missing_only
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Ruby::Signature::RuntimePrototypeTest::Test
  def self.baz: () -> void

  def foo: () -> void

  def bar: () -> void
end
EOF

      manager.build do |env|
        p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::*"], env: env, missing_only: true, merge: false)

        assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::Test < String
  include Foo

  def self.b: () -> untyped

  private

  def a: () -> untyped
end

Ruby::Signature::RuntimePrototypeTest::Test::NAME: String
        EOF
      end
    end
  end

  def test_merge_types
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Ruby::Signature::RuntimePrototypeTest::Test
  def self.baz: () -> void

  def foo: (String) -> Integer
         | (String, bool) { () -> void } -> [Symbol]

  def bar: () -> void
end
EOF

      manager.build do |env|
        p = Runtime.new(patterns: ["Ruby::Signature::RuntimePrototypeTest::*"], env: env, missing_only: false, merge: true)

        assert_write p.decls, <<-EOF
module Ruby::Signature::RuntimePrototypeTest::Foo
  include Enumerable
end

class Ruby::Signature::RuntimePrototypeTest::Test < String
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

Ruby::Signature::RuntimePrototypeTest::Test::NAME: String
        EOF
      end
    end
  end
end
