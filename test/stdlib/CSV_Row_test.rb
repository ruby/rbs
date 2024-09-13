# frozen_string_literal: true

require_relative "test_helper"
require "csv"

class CSV::RowSingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'csv'
  testing "singleton(::CSV::Row)"

  def test_initialize
    assert_send_type "(Array[String] headers, Array[String] fields, ?header_row: bool) -> void",
                     CSV::Row, :new, ["header1", "header2"], ["row1_1", "row1_2"], header_row: true
    assert_send_type "(Array[String] headers, Array[String] fields) -> void",
                     CSV::Row, :new, ["header1", "header2"], ["row1_1", "row1_2"]
    assert_send_type "(Array[Symbol] headers, Array[Symbol] fields) -> void",
                     CSV::Row, :new, [:header1, :header2], [:row_1, :row_2]
    assert_send_type "(Array[Integer] headers, Array[Integer] fields) -> void",
                     CSV::Row, :new, [1, 2], [1, 2]
  end
end
