require "test_helper"

class RBS::AST::Ruby::CommentBlockTest < Test::Unit::TestCase
  include TestHelper

  include RBS::AST::Ruby

  def parse_comments(source)
    buffer = RBS::Buffer.new(name: Pathname("a.rb"), content: source)
    [buffer, Prism.parse_comments(source)]
  end

  def test__buffer__single_line
    buffer, comments = parse_comments(<<~RUBY)
      # Hello, world!
    RUBY

    block = CommentBlock.new(buffer, comments)

    assert_equal "Hello, world!", block.comment_buffer.content
    assert_equal [[comments[0], 2]], block.offsets
  end

  def test__buffer__multi_line_prefix
    buffer, comments = parse_comments(<<~RUBY)
      # Hello, world!
      # This is the second line.
    RUBY

    block = CommentBlock.new(buffer, comments)

    assert_equal "Hello, world!\nThis is the second line.", block.comment_buffer.content
    assert_equal [[comments[0], 2], [comments[1], 2]], block.offsets
  end

  def test__buffer__multi_line_prefix_inconsistent
    buffer, comments = parse_comments(<<~RUBY)
      # Hello, world!
      #  This is the second line.
      #This is the third line.
    RUBY

    block = CommentBlock.new(buffer, comments)

    assert_equal "Hello, world!\n This is the second line.\nThis is the third line.", block.comment_buffer.content
    assert_equal [[comments[0], 2], [comments[1], 2], [comments[2], 1]], block.offsets
  end

  def test__buffer__multi_line_prefix_header_line
    buffer, comments = parse_comments(<<~RUBY)
      ####
      # Hello, world!
      # This is the second line.
    RUBY

    block = CommentBlock.new(buffer, comments)

    assert_equal "###\nHello, world!\nThis is the second line.", block.comment_buffer.content
    assert_equal [[comments[0], 1], [comments[1], 2], [comments[2], 2]], block.offsets
  end

  def test_build
    buffer, comments = parse_comments(<<~RUBY)
      # Comment1
      # Comment2

      # Comment3
      foo() # Comment4
            # Comment5

      bar() # Comment6
      baz() # Comment7
    RUBY

    blocks = CommentBlock.build(buffer, comments)

    assert_equal 5, blocks.size

    assert_equal <<~COMMENT.chomp, blocks[0].comment_buffer.content
      Comment1
      Comment2
    COMMENT
    assert_equal <<~COMMENT.chomp, blocks[1].comment_buffer.content
      Comment3
    COMMENT
    assert_equal <<~COMMENT.chomp, blocks[2].comment_buffer.content
      Comment4
      Comment5
    COMMENT
    assert_equal <<~COMMENT.chomp, blocks[3].comment_buffer.content
      Comment6
    COMMENT
    assert_equal <<~COMMENT.chomp, blocks[4].comment_buffer.content
      Comment7
    COMMENT
  end

  def test_each_paragraph
    buffer, comments = parse_comments(<<~RUBY)
      # Line 1
      #
      # @rbs skip -- 1
      # @rbs skip --
      #   2
      #   3
      #
      #   4
      #
      # Line 2
      # Line 3
      #
      # @rbs skipppp
      #
      # Line 4
    RUBY

    block = CommentBlock.new(buffer, comments)

    paragraphs = block.each_paragraph([]).to_a

    paragraphs[0].tap do |paragraph|
      assert_instance_of RBS::Location, paragraph
      assert_equal "Line 1\n", paragraph.source
    end
    paragraphs[1].tap do |paragraph|
      assert_instance_of RBS::AST::Ruby::Annotation::SkipAnnotation, paragraph
      assert_equal "@rbs skip -- 1", paragraph.location.source
    end
    paragraphs[2].tap do |paragraph|
      assert_instance_of RBS::AST::Ruby::Annotation::SkipAnnotation, paragraph
      assert_equal "@rbs skip --\n  2\n  3\n\n  4", paragraph.location.source
    end
    paragraphs[3].tap do |paragraph|
      assert_instance_of RBS::Location, paragraph
      assert_equal "\nLine 2\nLine 3\n", paragraph.source
    end
    paragraphs[4].tap do |paragraph|
      assert_instance_of RBS::AST::Ruby::CommentBlock::AnnotationSyntaxError, paragraph
      assert_equal "@rbs skipppp", paragraph.location.source
    end
    paragraphs[5].tap do |paragraph|
      assert_instance_of RBS::Location, paragraph
      assert_equal "\nLine 4", paragraph.source
    end
  end

  def test_each_paragraph_colon
    buffer, comments = parse_comments(<<~RUBY)
      # : Foo
      #
      #: %a{foo}
      #  () -> Bar
      #
      # Bar
    RUBY

    block = CommentBlock.new(buffer, comments)

    paragraphs = block.each_paragraph([]).to_a

    paragraphs[0].tap do |paragraph|
      assert_instance_of RBS::Location, paragraph
      assert_equal ": Foo\n", paragraph.source
    end
    paragraphs[1].tap do |paragraph|
      assert_instance_of RBS::AST::Ruby::Annotation::ColonMethodTypeAnnotation, paragraph
      assert_equal ": %a{foo}\n () -> Bar", paragraph.location.source
    end
    paragraphs[2].tap do |paragraph|
      assert_instance_of RBS::Location, paragraph
      assert_equal "\nBar", paragraph.source
    end
  end

  def test_trailing_annotation
    buffer, comments = parse_comments(<<~RUBY)
      foo #: String

      foo #[String]

      foo #: String[

      foo # This is some comment

      #: String
    RUBY

    blocks = CommentBlock.build(buffer, comments)

    blocks[0].trailing_annotation([]).tap do |annotation|
      assert_instance_of RBS::AST::Ruby::Annotation::NodeTypeAssertion, annotation
    end

    blocks[1].trailing_annotation([]).tap do |annotation|
      assert_instance_of RBS::AST::Ruby::Annotation::NodeApplication, annotation
    end

    blocks[2].trailing_annotation([]).tap do |annotation|
      assert_instance_of CommentBlock::AnnotationSyntaxError, annotation
    end

    blocks[3].trailing_annotation([]).tap do |annotation|
      assert_nil annotation
    end

    blocks[4].trailing_annotation([]).tap do |annotation|
      assert_nil annotation
    end
  end
end
