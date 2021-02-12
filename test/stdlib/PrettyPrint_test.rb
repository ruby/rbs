require_relative "test_helper"
require "prettyprint"

class PrettyPrintSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "prettyprint"
  testing "singleton(::PrettyPrint)"

  def test_format
    assert_send_type  "() { (PrettyPrint) -> String } -> String",
                      PrettyPrint, :format do "" end
    assert_send_type  "(String) { (PrettyPrint) -> String } -> String",
                      PrettyPrint, :format, "out" do "" end
    assert_send_type  "(Array[Integer]) { (PrettyPrint) -> String } -> Array[Integer]",
                      PrettyPrint, :format, [1, 2, 3] do "" end
    assert_send_type  "(String, Integer) { (PrettyPrint) -> String } -> String",
                      PrettyPrint, :format, "test", 25 do "" end
    assert_send_type  "(String, Integer, String, Proc) { (PrettyPrint) -> String } -> String",
                      PrettyPrint, :format, "test", 25, "\n\n", lambda {|n| "  " * n}  do "" end
  end

  def test_new
    assert_send_type  "() -> ::PrettyPrint",
                      PrettyPrint, :new
    assert_send_type  "(String) -> ::PrettyPrint",
                      PrettyPrint, :new, "test"
    assert_send_type  "(String, Integer) -> ::PrettyPrint",
                      PrettyPrint, :new, "test", 25
    assert_send_type  "(String, Integer, String) -> ::PrettyPrint",
                      PrettyPrint, :new, "test", 25, "\n\n"
    assert_send_type  "(Array[String], Integer, String) -> ::PrettyPrint",
                      PrettyPrint, :new, ["test", "long"], 25, "\n"
  end

  def test_singleline_format
    assert_send_type  "() { (PrettyPrint::SingleLine) -> String } -> String",
                      PrettyPrint, :singleline_format do "" end
    assert_send_type  "(String) { (PrettyPrint::SingleLine) -> String } -> String",
                      PrettyPrint, :singleline_format, "out" do "" end
    assert_send_type  "(Array[Integer]) { (PrettyPrint::SingleLine) -> String } -> Array[Integer]",
                      PrettyPrint, :singleline_format, [1, 2, 3] do "" end
    assert_send_type  "(String, Integer) { (PrettyPrint::SingleLine) -> String } -> String",
                      PrettyPrint, :singleline_format, "test", 25 do "" end
    assert_send_type  "(String, Integer, String, Proc) { (PrettyPrint::SingleLine) -> String } -> String",
                      PrettyPrint, :singleline_format, "test", 25, "\n\n", lambda {|n| "  " * n}  do "" end
  end
end

class PrettyPrintTest < Test::Unit::TestCase
  include TypeAssertions

  library "prettyprint"
  testing "::PrettyPrint"

  def initialize_with_block
    PrettyPrint.new(["first", "second"], 25, "\n") { |n| " " * 2 * n }
  end

  def test_output
    assert_send_type  "() -> String",
                      PrettyPrint.new("text"), :output
    assert_send_type  "() -> Array[Integer]",
                      PrettyPrint.new([1,2,3]), :output
    assert_send_type  "() -> Array[String]",
                      PrettyPrint.new(["test", "test_one"]), :output
    assert_send_type  "() -> Array[String]",
                      initialize_with_block, :output
  end

  def test_maxwidth
    assert_send_type  "() -> Integer",
                      PrettyPrint.new(""), :maxwidth
    assert_send_type  "() -> Integer",
                      PrettyPrint.new("", 20), :maxwidth
    assert_send_type  "() -> Integer",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :maxwidth
    assert_send_type  "() -> Integer",
                      initialize_with_block, :maxwidth
  end

  def test_newline
    assert_send_type  "() -> String",
                      PrettyPrint.new(""), :newline
    assert_send_type  "() -> String",
                      PrettyPrint.new("", 20), :newline
    assert_send_type  "() -> String",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :newline
    assert_send_type  "() -> String",
                      initialize_with_block, :newline
  end

  def test_genspace
    assert_send_type  "() -> Proc",
                      PrettyPrint.new(""), :genspace
    assert_send_type  "() -> Proc",
                      PrettyPrint.new("", 20), :genspace
    assert_send_type  "() -> Proc",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :genspace
    assert_send_type  "() -> Proc",
                      initialize_with_block, :genspace
  end

  def test_indent
    assert_send_type  "() -> Integer",
                      PrettyPrint.new(""), :indent
    assert_send_type  "() -> Integer",
                      PrettyPrint.new("", 20), :indent
    assert_send_type  "() -> Integer",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :indent
    assert_send_type  "() -> Integer",
                      initialize_with_block, :indent
  end

  def test_group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      PrettyPrint.new(""), :group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      PrettyPrint.new("", 20), :group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      initialize_with_block, :group_queue
  end

  def test_current_group
    assert_send_type  "() -> ::PrettyPrint::Group",
                      PrettyPrint.new, :current_group
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      PrettyPrint.new("", 20), :group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :group_queue
    assert_send_type  "() -> PrettyPrint::GroupQueue",
                      initialize_with_block, :group_queue
  end

  def test_break_outmost_groups
    assert_send_type  "() -> untyped",
                      PrettyPrint.new, :break_outmost_groups
    assert_send_type  "() -> untyped",
                      PrettyPrint.new("", 20), :break_outmost_groups
    assert_send_type  "() -> untyped",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :break_outmost_groups
    assert_send_type  "() -> untyped",
                      initialize_with_block, :break_outmost_groups
  end

  def test_text
    assert_send_type  "(String) -> void",
                      PrettyPrint.new, :text, "text"
    assert_send_type  "(String, Integer) -> void",
                      PrettyPrint.new, :text, "text", 85
    assert_send_type  "(String) -> untyped",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :text, "text"
    assert_send_type  "(String, Integer) -> untyped",
                      initialize_with_block, :text, "text", 85
  end

  def test_fill_breakable
    assert_send_type  "() -> void",
                      PrettyPrint.new, :fill_breakable
    assert_send_type  "() -> void",
                      PrettyPrint.new, :fill_breakable
    assert_send_type  "(String) -> void",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :fill_breakable, "\n"
    assert_send_type  "(String, Integer) -> void",
                      initialize_with_block, :fill_breakable, "\n\n", 85
  end

  def test_breakable
    assert_send_type  "() -> void",
                      PrettyPrint.new, :breakable
    assert_send_type  "() -> void",
                      PrettyPrint.new, :breakable
    assert_send_type  "(String) -> void",
                      PrettyPrint.new(["first", "second"], 25, "\n"), :breakable, "\n"
    assert_send_type  "(String, Integer) -> void",
                      initialize_with_block, :breakable, "\n\n", 85
  end

  def test_group
    assert_send_type  "() { () -> untyped } -> Integer",
                      PrettyPrint.new, :group do true end
    assert_send_type  "(Integer) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10 do true end
    assert_send_type  "(Integer, String) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10, "text" do true end
    assert_send_type  "(Integer, String, String) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10, "open", "close" do true end
    assert_send_type  "(Integer, String, String, Integer) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10, "open", "close", 25 do true end
    assert_send_type  "(Integer, String, String, Integer, Integer) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10, "open", "close", 25, 25 do true end
    assert_send_type  "(Integer, String, String, Integer, Integer) { () -> untyped } -> Integer",
                      PrettyPrint.new, :group, 10, "open", "close", 25, 25 do true end
  end

  def test_group_sub
    assert_send_type  "() { () -> untyped } -> untyped",
                      PrettyPrint.new, :group_sub do true end
    assert_send_type  "() { () -> untyped } -> untyped",
                      PrettyPrint.new, :group_sub do "" end
  end

  def test_nest
    assert_send_type  "(Integer) { () -> untyped } -> untyped",
                      PrettyPrint.new, :nest, 25 do true end
    assert_send_type  "(Integer) { () -> untyped } -> untyped",
                      PrettyPrint.new, :nest, 25 do "" end
  end

  def test_flush
    assert_send_type  "() -> Integer",
                      PrettyPrint.new, :flush
    assert_send_type  "() -> Integer",
                      initialize_with_block, :flush
  end
end
