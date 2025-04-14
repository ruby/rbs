require "test_helper"

class RBS::BufferTest < Test::Unit::TestCase
  Buffer = RBS::Buffer

  def test_buffer
    buffer = Buffer.new(name: Pathname("foo.rbs"), content: <<-CONTENT)
123
abc
    CONTENT

    assert_equal ["123", "abc", ""], buffer.lines
    assert_equal [0...3, 4...7, 8...8], buffer.ranges

    assert_equal [1, 0], buffer.pos_to_loc(0)
    assert_equal [1, 1], buffer.pos_to_loc(1)
    assert_equal [1, 2], buffer.pos_to_loc(2)
    assert_equal [1, 3], buffer.pos_to_loc(3)
    assert_equal [2, 0], buffer.pos_to_loc(4)
    assert_equal [2, 1], buffer.pos_to_loc(5)
    assert_equal [2, 2], buffer.pos_to_loc(6)
    assert_equal [2, 3], buffer.pos_to_loc(7)
    assert_equal [3, 0], buffer.pos_to_loc(8)

    assert_equal 0, buffer.loc_to_pos([1, 0])
    assert_equal 1, buffer.loc_to_pos([1, 1])
    assert_equal 2, buffer.loc_to_pos([1, 2])
    assert_equal 3, buffer.loc_to_pos([1, 3])
    assert_equal 4, buffer.loc_to_pos([2, 0])
    assert_equal 5, buffer.loc_to_pos([2, 1])
    assert_equal 6, buffer.loc_to_pos([2, 2])
    assert_equal 7, buffer.loc_to_pos([2, 3])
    assert_equal 8, buffer.loc_to_pos([3, 0])

    assert_equal "123", buffer.content[buffer.loc_to_pos([1,0])...buffer.loc_to_pos([1,3])]
    assert_equal "123\n", buffer.content[buffer.loc_to_pos([1,0])...buffer.loc_to_pos([2,0])]

    assert_equal 8, buffer.last_position
  end

  def test_buffer_with_no_eol
    buffer = Buffer.new(name: Pathname("foo.rbs"), content: "123\nabc")

    assert_equal ["123", "abc"], buffer.lines
    assert_equal [0...3, 4...7], buffer.ranges

    assert_equal [1, 0], buffer.pos_to_loc(0)
    assert_equal [1, 1], buffer.pos_to_loc(1)
    assert_equal [1, 2], buffer.pos_to_loc(2)
    assert_equal [1, 3], buffer.pos_to_loc(3)
    assert_equal [2, 0], buffer.pos_to_loc(4)
    assert_equal [2, 1], buffer.pos_to_loc(5)
    assert_equal [2, 2], buffer.pos_to_loc(6)
    assert_equal [2, 3], buffer.pos_to_loc(7)

    assert_equal 0, buffer.loc_to_pos([1, 0])
    assert_equal 1, buffer.loc_to_pos([1, 1])
    assert_equal 2, buffer.loc_to_pos([1, 2])
    assert_equal 3, buffer.loc_to_pos([1, 3])
    assert_equal 4, buffer.loc_to_pos([2, 0])
    assert_equal 5, buffer.loc_to_pos([2, 1])
    assert_equal 6, buffer.loc_to_pos([2, 2])
    assert_equal 7, buffer.loc_to_pos([2, 3])

    assert_equal "123", buffer.content[buffer.loc_to_pos([1,0])...buffer.loc_to_pos([1,3])]
    assert_equal "123\n", buffer.content[buffer.loc_to_pos([1,0])...buffer.loc_to_pos([2,0])]

    assert_equal 7, buffer.last_position
  end

  def test_sub_buffer
    buffer = Buffer.new(name: Pathname("foo.rbs"), content: <<~CONTENT)
      123
      abc
    CONTENT

    buffer.sub_buffer(lines: [1...3, 5...7]).tap do |sub_buffer|
      assert_equal <<~CONTENT.chomp, sub_buffer.content
        23
        bc
      CONTENT

      assert_equal 1, sub_buffer.parent_position(0)
      assert_equal 2, sub_buffer.parent_position(1)
      assert_equal 3, sub_buffer.parent_position(2)
      assert_equal 5, sub_buffer.parent_position(3)
      assert_equal 6, sub_buffer.parent_position(4)
      assert_equal 7, sub_buffer.parent_position(5)

      assert_equal [1, 0], sub_buffer.pos_to_loc(0)
      assert_equal [1, 1], sub_buffer.pos_to_loc(1)
      assert_equal [1, 2], sub_buffer.pos_to_loc(2)
      assert_equal [2, 0], sub_buffer.pos_to_loc(3)
      assert_equal [2, 1], sub_buffer.pos_to_loc(4)
      assert_equal [2, 2], sub_buffer.pos_to_loc(5)
      assert_equal [3, 0], sub_buffer.pos_to_loc(6)
    end
  end
end
