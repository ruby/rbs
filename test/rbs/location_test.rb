require "test_helper"

class RBS::LocationTest < Test::Unit::TestCase
  Buffer = RBS::Buffer
  Location = RBS::Location

  def test_location_source
    Location.new(buffer, 0, 4).yield_self do |location|
      assert_equal 0, location.start_pos
      assert_equal 4, location.end_pos
      assert_equal 1, location.start_line
      assert_equal 0, location.start_column
      assert_equal 2, location.end_line
      assert_equal 0, location.end_column
      assert_equal "123\n", location.source
    end

    Location.new(buffer, 4, 8).yield_self do |location|
      assert_equal 2, location.start_line
      assert_equal 0, location.start_column
      assert_equal 3, location.end_line
      assert_equal 0, location.end_column
      assert_equal "abc\n", location.source
    end
  end

  def test_location_child
    Location.new(buffer, 0, 8).yield_self do |location|
      location.add_optional_child(:num, 0...2)
      location.add_optional_child(:hira, nil)
      location.add_required_child(:alpha, 4...7)

      assert_equal "12", location[:num].source
      assert_nil location[:hira]
      assert_equal "abc", location[:alpha].source

      assert_equal [:num, :hira].sort, location.each_optional_key.to_a.sort
      assert_equal [:alpha], location.each_required_key.to_a
    end
  end

  def test_location_initialize_copy
    loc = Location.new(buffer, 0, 8)
    loc.add_optional_child(:num, 0...2)
    loc.add_required_child(:alpha, 4...7)
    assert_equal loc, loc.dup
    assert_equal loc[:num], loc.dup[:num]
    assert_equal loc[:alpha], loc.dup[:alpha]
  end

  def test_location_aref
    loc_without_child = Location.new(buffer, 0, 8)
    assert_raise RuntimeError do
      loc_without_child[:not_exist]
    end
    loc = Location.new(buffer, 0, 8)
    loc.add_optional_child(:num, 0...2)
    loc.add_required_child(:alpha, 4...7)
    assert_equal "12", loc[:num].source
    assert_equal "abc", loc[:alpha].source
  end

  def test_location_start_pos
    loc = Location.new(buffer, 0, 8)
    assert_equal 0, loc.start_pos
  end

  def test_location_end_pos
    loc = Location.new(buffer, 0, 8)
    assert_equal 8, loc.end_pos
  end

  def test_location_to_s
    loc = Location.new(buffer, 0, 7)
    assert_equal "foo.rbs:1:0...2:3", loc.to_s
  end

  def test_location_inspect
    content = ''
    loc = Location.new(Buffer.new(name: "trivia.rbs", content: content), 0, content.length)
    assert_include loc.inspect, "source=\"\""

    content = "\n"
    loc = Location.new(Buffer.new(name: "trivia.rbs", content: content), 0, content.length)
    assert_include loc.inspect, "source=\"\\n\""

    content = "class Foo\n  def foo: () -> void\nend\n"
    loc = Location.new(Buffer.new(name: "foo.rbs", content: content), 0, content.length)
    assert_include loc.inspect, "source=\"class Foo\""
  end

  def test_sub_buffer_location
    buffer = buffer()
    # 01
    # bc
    buffer = buffer.sub_buffer(lines: [0...2, 5...7])

    loc = Location.new(buffer, 0, 5)

    # Raw positions
    assert_equal 0, loc._start_pos
    assert_equal 5, loc._end_pos

    # Absolute positions
    assert_equal 0, loc.start_pos
    assert_equal 7, loc.end_pos
    assert_equal [1, 0], loc.start_loc
    assert_equal [2, 3], loc.end_loc

    assert_equal "123\nabc", loc.source

    loc.add_optional_child(:opt, 0...2)
    loc[:opt].tap do |loc|
      assert_equal 0, loc.start_pos
      assert_equal 2, loc.end_pos
      assert_equal "12", loc.source
    end

    loc.add_required_child(:req, 1...4)
    loc[:req].tap do |loc|
      assert_equal 1, loc.start_pos
      assert_equal 6, loc.end_pos
      assert_equal "23\nab", loc.source
    end
  end

  def test_sub_buffer_local_location
    buffer = buffer()
    # 01
    # bc
    buffer = buffer.sub_buffer(lines: [0...2, 5...7])

    loc = Location.new(buffer, 0, 5)
    loc.add_optional_child(:opt, 0...2)
    loc.add_required_child(:req, 1...4)

    loc = loc.local_location

    # Raw positions
    assert_equal 0, loc._start_pos
    assert_equal 5, loc._end_pos

    # Absolute positions in sub buffer
    assert_equal 0, loc.start_pos
    assert_equal 5, loc.end_pos
    assert_equal [1, 0], loc.start_loc
    assert_equal [2, 2], loc.end_loc

    assert_equal "12\nbc", loc.source

    loc[:opt].tap do |loc|
      assert_equal 0, loc.start_pos
      assert_equal 2, loc.end_pos
      assert_equal "12", loc.source
    end

    loc[:req].tap do |loc|
      assert_equal 1, loc.start_pos
      assert_equal 4, loc.end_pos
      assert_equal "2\nb", loc.source
    end
  end

  private

  def buffer(content: nil)
    content ||= <<~CONTENT
      123
      abc
    CONTENT
    Buffer.new(name: Pathname("foo.rbs"), content: content)
  end
end
