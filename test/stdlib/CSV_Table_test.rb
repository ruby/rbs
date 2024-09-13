# frozen_string_literal: true

require_relative "test_helper"
require "csv"

class CSV::TableInstanceTest < Test::Unit::TestCase
  include TestHelper

  library 'csv'
  testing "CSV::Table[CSV::Row]"

  def test_each
    table = CSV::Table.new([
      CSV::Row.new([], []),
      CSV::Row.new([], []),
      CSV::Row.new([], [])
    ])

    assert_send_type "() -> Enumerator[CSV::Row, void]",
                     table, :each
    assert_send_type "() { (CSV::Row) -> void } -> CSV::Table",
                     table, :each do end
  end
end
