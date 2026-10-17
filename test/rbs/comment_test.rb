require "test_helper"

class RBS::CommentTest < Test::Unit::TestCase
  include RBS

  def test_new_with_string
    comment = AST::Comment.new(string: "Hello\n", location: nil)

    assert_equal "Hello\n", comment.string
    assert_equal AST::Comment.new(string: "Hello\n", location: nil), comment
  end

  def test_new_without_string_requires_location
    assert_raises(RuntimeError) do
      AST::Comment.new(location: nil).string
    end
  end

  def test_string_from_location
    buffer = Buffer.new(name: Pathname("a.rbs"), content: "  # foo\n  #bar\n  #\nclass Foo end\n")
    location = Location.new(buffer, 2, 17)

    comment = AST::Comment.new(location: location)

    assert_equal "foo\nbar\n\n", comment.string
    assert_equal AST::Comment.new(string: "foo\nbar\n\n", location: nil), comment
  end
end
