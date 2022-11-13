require "test_helper"

class RBS::LocationTest < Test::Unit::TestCase
  Buffer = RBS::Buffer
  Location = RBS::Location

  def test_location_source
    buffer = Buffer.new(name: Pathname("foo.rbs"), content: <<-CONTENT)
123
abc
    CONTENT

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
    buffer = Buffer.new(name: Pathname("foo.rbs"), content: <<-CONTENT)
123
abc
    CONTENT

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
end
