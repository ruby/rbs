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

  def test_popen3
    assert_send_type "(::String) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     Open3, :popen3, 'echo "Foo"'
    assert_send_type "(::String, unsetenv_others: bool) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     Open3, :popen3, 'env', unsetenv_others: true
    assert_send_type "(::String, close_others: bool) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     Open3, :popen3, 'env', close_others: true
    assert_send_type "(::String, chdir: ::String) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     Open3, :popen3, 'echo "Foo"', chdir: '.'
    assert_send_type "(::Hash[::String, ::String], ::String) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     Open3, :popen3, { 'FOO' => 'BAR' }, "echo $FOO"

    assert_send_type "(::String) { (::IO, ::IO, ::IO, ::Process::Waiter) -> [::IO, ::IO, ::IO, ::Process::Waiter] } -> [::IO, ::IO, ::IO, ::Process::Waiter]",
                     Open3, :popen3, 'echo "Foo"' do |*args| args end
    assert_send_type "(::Hash[::String, ::String], ::String) { (::IO, ::IO, ::IO, ::Process::Waiter) -> [::IO, ::IO, ::IO, ::Process::Waiter] } -> [::IO, ::IO, ::IO, ::Process::Waiter]",
                     Open3, :popen3, { 'FOO' => 'BAR' }, 'echo $FOO' do |*args| args end
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

  def test_popen3
    assert_send_type "(::String) -> [ ::IO, ::IO, ::IO, ::Process::Waiter ]",
                     CustomOpen3.new, :popen3, 'echo "Foo"'
  end
end
