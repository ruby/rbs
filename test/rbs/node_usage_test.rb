require "test_helper"

class RBS::NodeUsageTest < Test::Unit::TestCase
  include RBS::Prototype

  def parse(string)
    RubyVM::AbstractSyntaxTree.parse(string)
  end

  def test_conditional
    NodeUsage.new(parse(<<~RB))
      def block
        yield
      end

      foo && bar || baz

      1&.+(2)

      begin
        bar
      end while baz

      a ||= b
      a += 123

      _x = 1
      @y = 2
      Z = 3
      Z::Z1 = 4

      _x, _y, _z = foo

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
