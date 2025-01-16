require "test_helper"

class RBS::InlineParserTest < Test::Unit::TestCase
  def parse_ruby(source)
    [
      RBS::Buffer.new(name: "test.rb", content: source),
      Prism.parse(source)
    ]
  end

  def test_parse
    buffer, result = parse_ruby(<<~RUBY)
      class Foo
        def foo = 123
      end

      module Bar
        def self.bar = 123
      end

      class <<self
      end
    RUBY

    ret = RBS::InlineParser.parse(buffer, result)

    pp ret
  end
end
