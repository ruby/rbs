require "test_helper"

class RBS::RewriterTest < Test::Unit::TestCase
  def make_location(buffer, start_pos, end_pos)
    RBS::Location.new(buffer, start_pos, end_pos)
  end

  def test_no_rewrites
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    assert_equal "class Foo\nend\n", rewriter.string
  end

  def test_single_rewrite
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9) # "Foo"
    rewriter.rewrite(loc, "Bar")

    assert_equal "class Bar\nend\n", rewriter.string
  end

  def test_multiple_non_overlapping_rewrites
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\n  def bar: () -> String\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc_name = make_location(buffer, 6, 9) # "Foo"
    loc_method = make_location(buffer, 16, 19) # "bar"
    rewriter.rewrite(loc_name, "Baz")
    rewriter.rewrite(loc_method, "qux")

    assert_equal "class Baz\n  def qux: () -> String\nend\n", rewriter.string
  end

  def test_rewrite_with_different_length
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9) # "Foo"
    rewriter.rewrite(loc, "LongerName")

    assert_equal "class LongerName\nend\n", rewriter.string
  end

  def test_rewrite_deletion
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 5, 9) # " Foo"
    rewriter.rewrite(loc, "")

    assert_equal "class\nend\n", rewriter.string
  end

  def test_rewrite_insertion
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 9, 9) # empty range at end of "Foo"
    rewriter.rewrite(loc, "[A]")

    assert_equal "class Foo[A]\nend\n", rewriter.string
  end

  def test_overlapping_rewrites_raises
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc1 = make_location(buffer, 0, 9)  # "class Foo"
    loc2 = make_location(buffer, 6, 13) # "Foo\nend"
    rewriter.rewrite(loc1, "module Bar")

    assert_raise(RuntimeError) { rewriter.rewrite(loc2, "Baz") }
  end

  def test_non_toplevel_buffer_raises
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "hello\nworld\n")
    sub = buffer.sub_buffer(lines: [0...5])

    assert_raise(RuntimeError) { RBS::Rewriter.new(sub) }
  end

  def test_rewrite_returns_self
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: "class Foo\nend\n")
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9)
    result = rewriter.rewrite(loc, "Bar")

    assert_same rewriter, result
  end
end
