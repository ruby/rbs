require_relative "test_helper"

WARNING_CATEGORIES = %i[deprecated experimental]
WARNING_CATEGORIES << :performance if RUBY_VERSION >= '3.3'

class WarningSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Warning)"

  def test_aref
    WARNING_CATEGORIES.each do |category|
      assert_send_type "(#{category.inspect}) -> bool",
          Warning, :[], category
    end

    refute_send_type "(Symbol) -> bool",
        Warning, :[], :unknown_category

    refute_send_type "(_ToSym) -> bool",
        Warning, :[], ToSym.new(WARNING_CATEGORIES.first)
  end

  def test_aset
    WARNING_CATEGORIES.each do |category|
      assert_send_type "(#{category.inspect}, Rational) -> Rational",
          Warning, :[]=, category, 1r
    end

    refute_send_type "(Symbol, Rational) -> Rational",
        Warning, :[]=, :unknown_category, 1r

    refute_send_type "(_ToSym, Rational) -> Rational",
        Warning, :[]=, ToSym.new(WARNING_CATEGORIES.first), 1r
  end
end

class WarningTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Warning"

  class TestClass
    include Warning
  end

  def test_warn
    old_stderr = $stderr
    $stderr = StringIO.new

    assert_send_type "(::String) -> nil",
        Warning, :warn, 'message'

    refute_send_type "(::_ToStr) -> nil",
        Warning, :warn, ToStr.new

    assert_send_type "(::String) -> nil",
        TestClass.new, :warn, 'message'

    omit_if(RUBY_VERSION < "3.0")

    WARNING_CATEGORIES.each do |category|
      assert_send_type "(::String, category: #{category.inspect}) -> nil",
          Warning, :warn, 'message', category: category
    end

    assert_send_type "(::String, category: nil) -> nil",
        Warning, :warn, 'message', category: nil

    refute_send_type "(::String, category: _ToSym) -> nil",
        Warning, :warn, 'message', category: ToSym.new(WARNING_CATEGORIES.first)

    refute_send_type "(::String, category: ::Symbol) -> nil",
        Warning, :warn, 'message', category: :unknown_category
  ensure
    $stderr = old_stderr
  end
end
