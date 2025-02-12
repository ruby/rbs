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

  def test_line_start?
    comments = Prism.parse_comments(<<~RUBY)
      # 123
      #   123
    RUBY

    block = CommentBlock.new(Pathname("a.rb"), comments)

    assert_equal 0, block.line_start?(0)
    assert_nil block.line_start?(1)
    assert_equal 6, block.line_start?(4)
    assert_equal 6, block.line_start?(5)
    assert_equal 6, block.line_start?(6)
    assert_nil block.line_start?(7)
    assert_nil block.line_start?(9)
  end
end
