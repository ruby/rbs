require "test_helper"

class RBS::AST::Ruby::CommentBlockTest < Test::Unit::TestCase
  include TestHelper

  include RBS::AST::Ruby

  def test__buffer__single_line
    comments = Prism.parse_comments(<<~RUBY)
      # Hello, world!
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal "Hello, world!", block.comment_buffer.content
    assert_equal [[comments[0], 2, 0, 13]], block.offsets
  end

  def test__buffer__multi_line_prefix
    comments = Prism.parse_comments(<<~RUBY)
      # Hello, world!
      # This is the second line.
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal "Hello, world!\nThis is the second line.", block.comment_buffer.content
    assert_equal [[comments[0], 2, 0, 13], [comments[1], 2, 14, 38]], block.offsets
  end

  def test__buffer__multi_line_prefix_inconsistent
    comments = Prism.parse_comments(<<~RUBY)
      # Hello, world!
      #  This is the second line.
      #This is the third line.
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal "Hello, world!\n This is the second line.\nThis is the third line.", block.comment_buffer.content
    assert_equal [[comments[0], 2, 0, 13], [comments[1], 2, 14, 39], [comments[2], 1, 40, 63]], block.offsets
  end

  def test__buffer__multi_line_prefix_header_line
    comments = Prism.parse_comments(<<~RUBY)
      ####
      # Hello, world!
      # This is the second line.
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal "##\nHello, world!\nThis is the second line.", block.comment_buffer.content
    assert_equal [[comments[0], 2, 0, 2], [comments[1], 2, 3, 16], [comments[2], 2, 17, 41]], block.offsets
  end

  def test_translate_comment_position
    comments = Prism.parse_comments(<<~RUBY)
      # Hello, world!
      # This is the second line.
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal [0, 2], block.translate_comment_position(0)
    assert_equal [0, 3], block.translate_comment_position(1)
    assert_equal [0, 14], block.translate_comment_position(12)
    assert_equal [0, 15], block.translate_comment_position(13)
    assert_equal [1, 2], block.translate_comment_position(14)
    assert_equal [1, 25], block.translate_comment_position(37)
    assert_equal [1, 26], block.translate_comment_position(38)
    assert_nil block.translate_comment_position(39)
  end

  def test_translate_comment_location
    comments = Prism.parse_comments(<<~RUBY)
      # Hello, world!
      # More lines,
      # we have.
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    RBS::Location.new(block.comment_buffer, 0, 4).tap do |loc|
      assert_equal [[comments[0], 2, 6]], block.translate_comment_location(loc)
    end

    RBS::Location.new(block.comment_buffer, 1, 1).tap do |loc|
      assert_equal [[comments[0], 3, 3]], block.translate_comment_location(loc)
    end

    RBS::Location.new(block.comment_buffer, 7, 18).tap do |loc|
      assert_equal [[comments[0], 9, 15], [comments[1], 2, 6]], block.translate_comment_location(loc)
    end

    RBS::Location.new(block.comment_buffer, 7, 28).tap do |loc|
      assert_equal [[comments[0], 9, 15], [comments[1], 2, 13], [comments[2], 2, 4]], block.translate_comment_location(loc)
    end
  end

  def test_build
    comments = Prism.parse_comments(<<~RUBY)
      # Comment1
      # Comment2

      # Comment3
      foo() # Comment4
            # Comment5

      bar() # Comment6
      baz() # Comment7
    RUBY

    blocks = CommentBlock.build(Pathname("a.rb"), comments)

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
    comments = Prism.parse_comments(<<~RUBY)
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

    block = CommentBlock.new(Pathname("a.rb"), comments)

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
    comments = Prism.parse_comments(<<~RUBY)
      # : Foo
      #
      #: %a{foo}
      #  () -> Bar
      #
      # Bar
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

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
    comments = Prism.parse_comments(<<~RUBY)
      foo #: String

      foo #[String]

      foo #: String[

      foo # This is some comment

      #: String
    RUBY

    blocks = CommentBlock.build(Pathname("a.rb"), comments)

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
