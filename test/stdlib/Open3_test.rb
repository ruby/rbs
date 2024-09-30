require_relative "test_helper"

class Open3SingletonTest < Test::Unit::TestCase
  include TestHelper

  library "open3"
  testing "singleton(::Open3)"

  def test_capture2e
    assert_send_type "(*::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, 'echo "Foo"'
    assert_send_type "(*::String, binmode: boolish) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, 'echo "Foo"', binmode: true
    assert_send_type "(*::String, stdin_data: ::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, "#{RUBY_EXECUTABLE} -e 'puts STDIN.read'", stdin_data: 'Foo'
  end
end
