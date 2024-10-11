require "test_helper"

class RBS::AST::VisitorTest < Test::Unit::TestCase
  RBS_STRING = <<~RBS
    module Hello
      attr_reader name: String

      def hello: () -> void
    end
  RBS

  def test_visit
    visitor_class = Class.new(RBS::AST::Visitor) do
      attr_reader :nodes

      def initialize
        super()
        @nodes = []
      end

      def visit(node)
        @nodes << node
        super
      end
    end

    declarations = parse_rbs_string(RBS_STRING)
    visitor = visitor_class.new
    visitor.visit_all(declarations)

    assert_equal(
      [
        "RBS::AST::Declarations::Module",
        "RBS::AST::Members::AttrReader",
        "RBS::AST::Members::MethodDefinition"
      ],
      visitor.nodes.map(&:class).map(&:name)
    )
  end

  def test_visit_node
    visitor_class = Class.new(RBS::AST::Visitor) do
      attr_reader :nodes

      def initialize
        super()
        @nodes = []
      end

      def visit_member_method_definition(node)
        @nodes << node
      end
    end

    declarations = parse_rbs_string(RBS_STRING)
    visitor = visitor_class.new
    visitor.visit_all(declarations)

    assert_equal(["RBS::AST::Members::MethodDefinition"], visitor.nodes.map(&:class).map(&:name))
  end

  private

  def parse_rbs_string(rbs)
    rbs = RBS::Buffer.new(content: rbs, name: "-")
    _, _, declarations = RBS::Parser.parse_signature(rbs)
    declarations
  end
end
