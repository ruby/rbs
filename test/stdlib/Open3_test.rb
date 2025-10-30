require_relative "test_helper"

class Open3SingletonTest < Test::Unit::TestCase
  include TestHelper

  library "open3"
  testing "singleton(::Open3)"

  def test_capture2
    assert_send_type "(*::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2, 'echo "Foo"'
    assert_send_type "(*::String, binmode: boolish) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2, 'echo "Foo"', binmode: true
    assert_send_type "(*::String, stdin_data: ::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2, "#{RUBY_EXECUTABLE} -e 'puts STDIN.read'", stdin_data: 'Foo'
    assert_send_type "(::Hash[::String, ::String], *::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2, { 'FOO' => 'BAR' }, "echo $FOO"
  end

  def test_capture2e
    assert_send_type "(*::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, 'echo "Foo"'
    assert_send_type "(*::String, binmode: boolish) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, 'echo "Foo"', binmode: true
    assert_send_type "(*::String, stdin_data: ::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, "#{RUBY_EXECUTABLE} -e 'puts STDIN.read'", stdin_data: 'Foo'
    assert_send_type "(::Hash[::String, ::String], *::String) -> [ ::String, ::Process::Status ]",
                     Open3, :capture2e, { 'FOO' => 'BAR' }, "echo $FOO"
  end
end

class Open3InstanceTest < Test::Unit::TestCase
  include TestHelper

  library "open3"
  testing "::Open3"

  class CustomOpen3
    include Open3
  end

  def test_capture2
    assert_send_type "(*::String) -> [ ::String, ::Process::Status ]",
                     CustomOpen3.new, :capture2, 'echo "Foo"'
  end

  def test_capture2e
    assert_send_type "(*::String) -> [ ::String, ::Process::Status ]",
                     CustomOpen3.new, :capture2e, 'echo "Foo"'
  end
end
