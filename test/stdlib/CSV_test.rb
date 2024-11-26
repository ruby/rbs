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
    assert_send_type "(String path, headers: :first_row) { (CSV::Row) -> void } -> void",
                     CSV, :foreach, path, headers: :first_row, &csv_row_array_block
    assert_send_type "(String path, headers: Array[untyped]) { (CSV::Row) -> void } -> void",
                     CSV, :foreach, path, headers: ["name"], &csv_row_array_block
    assert_send_type "(String path, headers: String) { (CSV::Row) -> void } -> void",
                     CSV, :foreach, path, headers: "name", &csv_row_array_block

    assert_send_type "(String path, **untyped) -> Enumerator[Array[String?], void]",
                     CSV, :foreach, path, encoding: 'UTF-8'
    assert_send_type "(String path, headers: bool) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: true
    assert_send_type "(String path, headers: :first_row) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: :first_row
    assert_send_type "(String path, headers: Array[untyped]) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: ["name"]
    assert_send_type "(String path, headers: String) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: "name"
    assert_send_type "(String path, headers: bool, **untyped) -> Enumerator[CSV::Row, void]",
                     CSV, :foreach, path, headers: true, encoding: 'UTF-8'
  end

  def test_read
    tmpdir = Dir.mktmpdir
    path = File.join(tmpdir, "example.csv")
    File.write(path, "a,b,c\n1,2,3\n")

    assert_send_type "(String path, headers: true) -> CSV::Table[CSV::Row]",
                     CSV, :read, path, headers: true
    assert_send_type "(IO path, headers: true) -> CSV::Table[CSV::Row]",
                     CSV, :read, File.open(path), headers: true
    assert_send_type "(String path, headers: :first_row) -> CSV::Table[CSV::Row]",
                     CSV, :read, path, headers: :first_row
    assert_send_type "(IO path, headers: :first_row) -> CSV::Table[CSV::Row]",
                     CSV, :read, File.open(path), headers: :first_row
    assert_send_type "(String path, headers: Array[String]) -> CSV::Table[CSV::Row]",
                     CSV, :read, path, headers: %w[foo bar baz]
    assert_send_type "(IO path, headers: Array[String]) -> CSV::Table[CSV::Row]",
                     CSV, :read, File.open(path), headers: %w[foo bar baz]
    assert_send_type "(String path, headers: String) -> CSV::Table[CSV::Row]",
                     CSV, :read, path, headers: "foo,bar,baz"
    assert_send_type "(IO path, headers: String) -> CSV::Table[CSV::Row]",
                     CSV, :read, File.open(path), headers: "foo,bar,baz"

    assert_send_type "(String path) -> Array[Array[String?]]",
                     CSV, :read, path
    assert_send_type "(IO path) -> Array[Array[String?]]",
                     CSV, :read, File.open(path)
  end
end

class CSVTest < Test::Unit::TestCase
  include TestHelper

  library "csv"
  testing "CSV"

  def test_headers
    csv = CSV.new("header1,header2\nrow1_1,row1_2")
    assert_send_type "() -> nil",
                     csv, :headers

    csv = CSV.new("header1,header2\nrow1_1,row1_2", headers: true)
    assert_send_type "() -> true",
                     csv, :headers
    csv.read
    assert_send_type "() -> Array[String]",
                     csv, :headers
  end
end

class CSVArrayTest < Test::Unit::TestCase
  include TestHelper

  library "csv"
  testing "Array[untyped]"

  def test_to_csv_with_array
    assert_send_type "() -> String",
                     [1, 2, 3], :to_csv
    assert_send_type "(**untyped) -> String",
                     [1, 2, 3], :to_csv, col_sep: '\t'
  end
end

class CSVStringTest < Test::Unit::TestCase
  include TestHelper

  library "csv"
  testing "String"

  def test_parse_csv_with_string
    assert_send_type "() -> Array[String?]",
                     "1,2,3", :parse_csv
    assert_send_type "(**untyped) -> Array[String?]",
                     "1,2,3", :parse_csv, col_sep: '\t'
  end
end
