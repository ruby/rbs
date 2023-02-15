require_relative "test_helper"

class DataSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  testing "singleton(::Data)"

  def test_define
    assert_send_type(
      "(Symbol, Symbol) -> singleton(Data)",
      Data, :define, :foo, :bar
    )

    assert_send_type(
      "(Symbol, Symbol) { (singleton(Data)) -> nil } -> singleton(Data)",
      Data, :define, :foo, :bar, &-> (_) { nil }
    )
  end
end

class DataInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  testing "::Data"

  D = Data.define(:email, :name)

  def test_members
    data = D.new("soutaro@example.com", "soutaro")

    assert_send_type(
      "() -> Array[Symbol]",
      data, :members
    )
  end

  def test_with
    data = D.new("soutaro@example.com", "soutaro")

    assert_send_type(
      "(email: String) -> Data",
      data, :with, email: "test@example.com"
    )
  end
end
