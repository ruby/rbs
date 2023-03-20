require "test_helper"

class RBS::SubtractorTest < Test::Unit::TestCase
  def test_call_constant
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

  def to_decls(rbs)
    # It ignores directives, is it ok?
    RBS::Parser.parse_signature(rbs).last
  end

  def to_env(rbs)
    RBS::Environment.new.tap do |env|
      to_decls(rbs).each do |decl|
        env << decl
      end
    end
  end

  def assert_subtracted(expected, subtracted)
    io = StringIO.new
    RBS::Writer.new(out: io).write(subtracted)

    assert_equal expected, io.string
  end
end
