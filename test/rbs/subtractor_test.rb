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
    RBS

    env = to_env(<<~RBS)
      interface _I
        def x: () -> String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      interface _I
        def y: () -> untyped
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
      end
    RBS

    env = to_env(<<~RBS)
      class C
        def a: () -> Integer
        def b=: (String) -> String
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
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

  def test_public_and_private
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

    assert_subtracted <<~RBS, subtracted
      class C
        public
        private
      end
    RBS
  end

  def test_mixin
    decls = to_decls(<<~RBS)
      class C
        include M1
        prepend M2
        extend M3
      end
    RBS

    env = to_env(<<~RBS)
      class C
        include M1
        prepend M2
        extend M3
      end
    RBS

    subtracted = RBS::Subtractor.new(decls, env).call

    assert_subtracted <<~RBS, subtracted
      class C
        include M1
        prepend M2
        extend M3
      end
    RBS
  end

  private def to_decls(rbs)
    # It ignores directives, is it ok?
    RBS::Parser.parse_signature(rbs).last
  end

  private def to_env(rbs)
    RBS::Environment.new.tap do |env|
      to_decls(rbs).each do |decl|
        env << decl
      end
    end
  end

  private def assert_subtracted(expected, subtracted)
    io = StringIO.new
    RBS::Writer.new(out: io).write(subtracted)

    assert_equal expected, io.string
  end
end
