require "test_helper"

class RBS::RewriterTest < Test::Unit::TestCase
  def make_location(buffer, start_pos, end_pos)
    RBS::Location.new(buffer, start_pos, end_pos)
  end

  def test_no_rewrites
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    assert_equal rbs, rewriter.string
  end

  def test_single_rewrite
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9) # "Foo"
    rewriter.rewrite(loc, "Bar")

    assert_equal <<~RBS, rewriter.string
      class Bar
      end
    RBS
  end

  def test_multiple_non_overlapping_rewrites
    rbs = <<~RBS
      class Foo
        def bar: () -> String
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc_name = make_location(buffer, 6, 9) # "Foo"
    loc_method = make_location(buffer, 16, 19) # "bar"
    rewriter.rewrite(loc_name, "Baz")
    rewriter.rewrite(loc_method, "qux")

    assert_equal <<~RBS, rewriter.string
      class Baz
        def qux: () -> String
      end
    RBS
  end

  def test_rewrite_with_different_length
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9) # "Foo"
    rewriter.rewrite(loc, "LongerName")

    assert_equal <<~RBS, rewriter.string
      class LongerName
      end
    RBS
  end

  def test_rewrite_deletion
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 5, 9) # " Foo"
    rewriter.rewrite(loc, "")

    assert_equal <<~RBS, rewriter.string
      class
      end
    RBS
  end

  def test_rewrite_insertion
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 9, 9) # empty range at end of "Foo"
    rewriter.rewrite(loc, "[A]")

    assert_equal <<~RBS, rewriter.string
      class Foo[A]
      end
    RBS
  end

  def test_overlapping_rewrites_raises
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
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
    rbs = <<~RBS
      class Foo
      end
    RBS
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    loc = make_location(buffer, 6, 9)
    result = rewriter.rewrite(loc, "Bar")

    assert_same rewriter, result
  end

  def test_replace_comment_single_line
    rbs = <<~RBS
      # Hello
      class Foo
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.replace_comment(decls[0].comment, content: "Goodbye\n")

    assert_equal <<~RBS, rewriter.string
      # Goodbye
      class Foo
      end
    RBS
  end

  def test_replace_comment_multi_line
    rbs = <<~RBS
      # Hello
      # World
      class Foo
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.replace_comment(decls[0].comment, content: "Goodbye\nUniverse\n")

    assert_equal <<~RBS, rewriter.string
      # Goodbye
      # Universe
      class Foo
      end
    RBS
  end

  def test_replace_comment_with_empty_line
    rbs = <<~RBS
      # Hello
      #
      # World
      class Foo
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.replace_comment(decls[0].comment, content: "Goodbye\n\nUniverse\n")

    assert_equal <<~RBS, rewriter.string
      # Goodbye
      #
      # Universe
      class Foo
      end
    RBS
  end

  def test_replace_comment_indented
    rbs = <<~RBS
      class Foo
        # Hello
        # World
        def bar: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.replace_comment(decls[0].members[0].comment, content: "Goodbye\nUniverse\n")

    assert_equal <<~RBS, rewriter.string
      class Foo
        # Goodbye
        # Universe
        def bar: () -> void
      end
    RBS
  end

  def test_replace_comment_with_annotation
    rbs = <<~RBS
      class Foo
        # Hello
        %a{deprecated}
        def foo: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.replace_comment(decls[0].members[0].comment, content: "Goodbye\n")

    assert_equal <<~RBS, rewriter.string
      class Foo
        # Goodbye
        %a{deprecated}
        def foo: () -> void
      end
    RBS
  end

  def test_delete_comment
    rbs = <<~RBS
      # Hello
      class Foo
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.delete_comment(decls[0].comment)

    assert_equal <<~RBS, rewriter.string
      class Foo
      end
    RBS
  end

  def test_delete_comment_indented
    rbs = <<~RBS
      class Foo
        # Hello
        # World
        def bar: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.delete_comment(decls[0].members[0].comment)

    assert_equal <<~RBS, rewriter.string
      class Foo
        def bar: () -> void
      end
    RBS
  end

  def test_delete_comment_with_annotation
    rbs = <<~RBS
      class Foo
        # Hello
        %a{deprecated}
        def foo: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.delete_comment(decls[0].members[0].comment)

    assert_equal <<~RBS, rewriter.string
      class Foo
        %a{deprecated}
        def foo: () -> void
      end
    RBS
  end

  def test_add_comment
    rbs = <<~RBS
      class Foo
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.add_comment(decls[0].location, content: "New comment\n")

    assert_equal <<~RBS, rewriter.string
      # New comment
      class Foo
      end
    RBS
  end

  def test_add_comment_indented
    rbs = <<~RBS
      class Foo
        def bar: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.add_comment(decls[0].members[0].location, content: "New comment\nSecond line\n")

    assert_equal <<~RBS, rewriter.string
      class Foo
        # New comment
        # Second line
        def bar: () -> void
      end
    RBS
  end

  def test_add_comment_with_annotation
    rbs = <<~RBS
      class Foo
        %a{deprecated}
        def foo: () -> void
      end
    RBS
    _, _, decls = RBS::Parser.parse_signature(rbs)
    member = decls[0].members[0]
    buffer = RBS::Buffer.new(name: Pathname("test.rbs"), content: rbs)
    rewriter = RBS::Rewriter.new(buffer)

    rewriter.add_comment(member.annotations[0].location, member.location, content: "This is foo\n")

    assert_equal <<~RBS, rewriter.string
      class Foo
        # This is foo
        %a{deprecated}
        def foo: () -> void
      end
    RBS
  end
end
