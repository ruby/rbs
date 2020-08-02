require "test_helper"

class RBS::CommentTest < Minitest::Test
  include TestHelper

  def test_concat
    buffer = RBS::Buffer.new(name: Pathname("foo.rbs"), content: "")

    comment = RBS::AST::Comment.new(
      string: 'foo',
      location: RBS::Location.new(buffer: buffer, start_pos: 0, end_pos: 3)
    )
    
    comment.concat(
      string: 'bar',
      location: RBS::Location.new(buffer: buffer, start_pos: 4, end_pos: 7)
    )
    
    assert_equal "foobar", comment.string
    assert_equal 0, comment.location.start_pos
    assert_equal 7, comment.location.end_pos
  end
end
