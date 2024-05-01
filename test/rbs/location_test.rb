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

  private

  def buffer(content: nil)
    content ||= <<~CONTENT
      123
      abc
    CONTENT
    Buffer.new(name: Pathname("foo.rbs"), content: content)
  end
end
