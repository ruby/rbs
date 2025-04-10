# frozen_string_literal: true

require "test_helper"

class RBS::SubtractorTest < Test::Unit::TestCase
  def test_constants
    decls = to_decls(<<~RBS)
      C1: untyped
      C2: untyped

      class X
        C3: untyped
        C4: untyped
      end
    RBS

    env = to_env(<<~RBS)
      C1: String

      class X
        C3: Integer
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      C2: untyped

      class X
        C4: untyped
      end
    RBS
  end

  def test_constants_duplicated_with_class
    decls = to_decls(<<~RBS)
      C1: untyped
      C2: untyped
      C3: untyped
      C4: untyped
      C5: untyped
    RBS

    env = to_env(<<~RBS)
      class C1
      end

      module C2
      end

      class C3 = String
      module C4 = Enumerable
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      C5: untyped
    RBS
  end

  def test_duplicated_class
    decls = to_decls(<<~RBS)
      class C1
        def x: () -> void
      end

      class C2
        def x: () -> void
      end

      class C3
        def x: () -> void
      end

      class C4
        def x: () -> void
      end

      class C5
        def x: () -> void
      end
    RBS

    env = to_env(<<~RBS)
      class C1 = String

      module C2
      end

      module C3 = Enumerable
      C4: String
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C5
        def x: () -> void
      end
    RBS
  end

  def test_duplicated_module
    decls = to_decls(<<~RBS)
      module M1
        def x: () -> void
      end

      module M2
        def x: () -> void
      end

      module M3
        def x: () -> void
      end

      module M4
        def x: () -> void
      end

      module M5
        def x: () -> void
      end
    RBS

    env = to_env(<<~RBS)
      module M1 = Enumerable

      class M2
      end

      class M3 = String
      M4: String
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      module M5
        def x: () -> void
      end
    RBS
  end

  def test_globals
    decls = to_decls(<<~RBS)
      $a: untyped
      $b: untyped
    RBS

    env = to_env(<<~RBS)
      $a: String
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      $b: untyped
    RBS
  end

  def test_type_aliases
    decls = to_decls(<<~RBS)
      type a = untyped
      type b = untyped
      class C
        type a = untyped
        type b = untyped
      end
    RBS

    env = to_env(<<~RBS)
      type a = String
      class C
        type b = Integer
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      type b = untyped
      class C
        type a = untyped
      end
    RBS
  end

  def test_class_aliases
    decls = to_decls(<<~RBS)
      class A = X
      class B = X
      class C = X
      class N
        class A = X
        class B = X
        class C = X
      end
    RBS

    env = to_env(<<~RBS)
      class A = Y
      class B end
      class N
        class A = Y
        class B end
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C = X
      class N
        class C = X
      end
    RBS
  end

  def test_module_aliases
    decls = to_decls(<<~RBS)
      module A = X
      module B = X
      module C = X
      module N
        module A = X
        module B = X
        module C = X
      end
    RBS

    env = to_env(<<~RBS)
      module A = Y
      module B end
      module N
        module A = Y
        module B end
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      module C = X
      module N
        module C = X
      end
    RBS
  end

  def test_methods_in_class
    decls = to_decls(<<~RBS)
      class C
        def x: () -> untyped
        def y: () -> untyped
        def self.x: () -> untyped
        def self.y: () -> untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        def x: () -> String
        def self.y: () -> Integer
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        def y: () -> untyped
        def self.x: () -> untyped
      end
    RBS
  end

  def test_methods_in_module
    decls = to_decls(<<~RBS)
      module M
        def x: () -> untyped
        def y: () -> untyped
        def self.x: () -> untyped
        def self.y: () -> untyped
      end
    RBS

    env = to_env(<<~RBS)
      module M
        def x: () -> String
        def self.y: () -> Integer
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      module M
        def y: () -> untyped

        def self.x: () -> untyped
      end
    RBS
  end

  def test_methods_in_interface
    decls = to_decls(<<~RBS)
      interface _I
        def x: () -> untyped
        def y: () -> untyped
      end

      interface _I2
        def x: () -> untyped
      end
    RBS

    env = to_env(<<~RBS)
      interface _I
        def x: () -> String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      interface _I2
        def x: () -> untyped
      end
    RBS
  end

  def test_methods_alias
    decls = to_decls(<<~RBS)
      class C
        def x: () -> untyped
        def y: () -> untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        alias x y
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        def y: () -> untyped
      end
    RBS
  end

  def test_methods_attr
    decls = to_decls(<<~RBS)
      class C
        def x: () -> untyped
        def y=: () -> untyped
        def z: () -> untyped
        def z=: () -> untyped
        def a: () -> untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        attr_reader x: String
        attr_writer y: Integer
        attr_accessor z: Symbol
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        def a: () -> untyped
      end
    RBS
  end

  def test_alias
    decls = to_decls(<<~RBS)
      class C
        def x: () -> untyped
        alias y x

        def self.a: () -> untyped
        alias self.b self.a
      end
    RBS

    env = to_env(<<~RBS)
      class C
        def y: () -> String
        def self.b: () -> String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        def x: () -> untyped

        def self.a: () -> untyped
      end
    RBS
  end

  def test_attr
    decls = to_decls(<<~RBS)
      class C
        attr_reader a: untyped
        attr_writer b: untyped
        attr_writer c: untyped
        attr_accessor d: untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        def a: () -> Integer
        def b=: (String) -> String
        def c: (String) -> String
        def d: (String) -> String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        attr_writer c: untyped
      end
    RBS
  end

  def test_ivar
    decls = to_decls(<<~RBS)
      class C
        @v1: untyped
        @v2: untyped
        @v3: untyped
        @v4: untyped
        @v5: untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        @v1: String
        attr_reader v2: String
        attr_reader v3 (): String
        attr_reader foo (@v4): String
        self.@v5: Integer
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        @v3: untyped

        @v5: untyped
      end
    RBS
  end

  def test_cvar
    decls = to_decls(<<~RBS)
      class C
        @@v1: untyped
        @@v2: untyped
        @@v3: untyped
      end
    RBS

    env = to_env(<<~RBS)
      class C
        @@v1: String
        @v2: String
        self.@v3: String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        @@v2: untyped
        @@v3: untyped
      end
    RBS
  end

  def test_empty_public_and_private
    decls = to_decls(<<~RBS)
      class C
        public
        private
      end
    RBS

    env = to_env(<<~RBS)
      class C
        public
        private
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted "", subtracted
  end

  def test_public_and_private
    decls = to_decls(<<~RBS)
      class C
        public
        public
        def a: () -> Integer
        private
        private
        def b: () -> Integer
        public
        private
      end
    RBS

    env = to_env(<<~RBS)
      class C
        public
        private
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        public
        def a: () -> Integer

        private
        def b: () -> Integer
      end
    RBS
  end

  def test_mixin
    decls = to_decls(<<~RBS)
      class C
        include M1
        prepend M2
        extend M3
        include M4

        class C2
          include M5
          include M6
          include M7
        end
      end
    RBS

    env = to_env(<<~RBS)
      class C
        include M1
        prepend M2
        extend M3
        extend M4

        class C2
          include ::M5
          include C2::M6
          include C::C2::M7
        end
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        include M4
      end
    RBS
  end

  def test_nonexist_class
    decls = to_decls(<<~RBS)
      class C
        def x: () -> void
      end

      interface _I
        def x: () -> void
      end
    RBS

    env = to_env(<<~RBS)
      class X
        def x: () -> void
      end

      interface _IX
        def x: () -> void
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        def x: () -> void
      end

      interface _I
        def x: () -> void
      end
    RBS
  end

  def test_empty_class_module
    decls = to_decls(<<~RBS)
      class C1
        def x: () -> void
      end

      class C2
      end

      module M1
        def x: () -> void
      end

      module M2
      end
    RBS

    env = to_env(<<~RBS)
      class C1
        def x: () -> void
      end

      module M1
        def x: () -> void
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C2
      end

      module M2
      end
    RBS
  end

  private def to_decls(rbs)
    # It ignores directives, is it ok?
    _, _, decls = RBS::Parser.parse_signature(rbs)
    decls
  end

  private def to_env(rbs)
    RBS::Environment.new.tap do |env|
      buf, dirs, decls = RBS::Parser.parse_signature(rbs)
      source = RBS::Source::RBS.new(buf, dirs, decls)
      env.add_source(source)
    end
  end

  private def assert_subtracted(expected, subtracted)
    io = StringIO.new
    RBS::Writer.new(out: io).write(subtracted)

    assert_equal expected, io.string
  end
end
