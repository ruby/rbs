require_relative "test_helper"

class IOSingletonTest < Minitest::Test
  include TypeAssertions

  testing "singleton(::IO)"

  def test_binread
    assert_send_type "(String) -> String",
                     IO, :binread, __FILE__
    assert_send_type "(String, Integer) -> String",
                     IO, :binread, __FILE__, 3
    assert_send_type "(String, Integer, Integer) -> String",
                     IO, :binread, __FILE__, 3, 0
  end

  def test_binwrite
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "some_file")
      content = "foo"

      assert_send_type "(String, String) -> Integer",
                       IO, :binwrite, filename, content
      assert_send_type "(String, String, Integer) -> Integer",
                       IO, :binwrite, filename, content, 0
      assert_send_type "(String, String, mode: String) -> Integer",
                       IO, :binwrite, filename, content, mode: "a"
      assert_send_type "(String, String, Integer, mode: String) -> Integer",
                       IO, :binwrite, filename, content, 0, mode: "a"
    end
  end
end
