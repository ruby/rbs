# frozen_string_literal: true

require_relative "test_helper"
require "csv"

class CSVSingletonTest < Test::Unit::TestCase
  include TestHelper

  library 'csv'
  testing "singleton(::CSV)"

  def test_foreach
    tmpdir = Dir.mktmpdir
    path = File.join(tmpdir, "example.csv")
    File.write(path, "a,b,c\n1,2,3\n")

    string_array_block = ->(row) { row.size }
    assert_send_type "(String path) { (Array[String?]) -> void } -> void",
                     CSV, :foreach, path, &string_array_block
    assert_send_type "(IO path) { (Array[String?]) -> void } -> void",
                     CSV, :foreach, File.open(path), &string_array_block

    csv_row_array_block = ->(row) { row.fields }
    assert_send_type "(String path, headers: true) { (CSV::Row) -> void } -> void",
                     CSV, :foreach, path, headers: true, &csv_row_array_block
    assert_send_type "(String path, headers: false) { (Array[String?]) -> void } -> void",
                     CSV, :foreach, path, headers: false, &string_array_block
    assert_send_type "(IO path, headers: bool) { (CSV::Row) -> void } -> void",
                     CSV, :foreach, File.open(path), headers: true, &csv_row_array_block

    assert_send_type "(String path, **untyped) -> Enumerator[Array[String?], void]",
                     CSV, :foreach, path, encoding: 'UTF-8'
    assert_send_type "(String path, headers: bool) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: true
    assert_send_type "(String path, headers: bool, **untyped) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: true, encoding: 'UTF-8'
  end
end
