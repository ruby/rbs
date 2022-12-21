require "test_helper"

class RBS::NodeUsageTest < Test::Unit::TestCase
  include RBS::Prototype

  def parse(string)
    RubyVM::AbstractSyntaxTree.parse(string)
  end

  def test_conditional
    usage = NodeUsage.new(parse(<<~RB))
      if block
        yield
      end

      foo && bar || baz

      1&.+(2)

      begin
        bar
      end while baz

      a ||= b
      a += 123

      x = 1
      @y = 2
      Z = 3
      Z::Z1 = 4

      x, y, z = foo

      puts unless foo

      case
      when foo
      else
        hello
      end

      [
        (foo(); bar; baz)
      ]
    RB
  end
end
