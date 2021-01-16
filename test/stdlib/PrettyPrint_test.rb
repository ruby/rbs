require_relative "test_helper"
require "prettyprint"

class PrettyPrintSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "prettyprint"
  testing "singleton(::PrettyPrint)"

  def test_format
    assert_send_type  "(?untyped output, ?::Integer maxwidth, ?::String newline, ?untyped genspace) ?{ (::Integer) -> ::Integer } -> untyped",
                      PrettyPrint, :format
  end

  def test_new
    assert_send_type  "(?untyped output, ?::Integer maxwidth, ?::String newline) ?{ (::Integer) -> untyped } -> ::PrettyPrint",
                      PrettyPrint, :new
  end

  def test_singleline_format
    assert_send_type  "(?untyped output, ?::Integer? maxwidth, ?::String? newline, untyped? genspace) ?{ (::Integer) -> ::Integer } -> untyped",
                      PrettyPrint, :singleline_format
  end
end

class PrettyPrintTest < Test::Unit::TestCase
  include TypeAssertions

  library "prettyprint"
  testing "::PrettyPrint"

  def test_initialize
    assert_send_type  "(?untyped output, ?::Integer maxwidth, ?::String newline) ?{ (::Integer) -> untyped } -> void",
                      PrettyPrint.new, :initialize
  end

  def test_output
    assert_send_type  "() -> untyped",
                      PrettyPrint.new, :output
  end

  def test_maxwidth
    assert_send_type  "() -> ::Integer",
                      PrettyPrint.new, :maxwidth
  end

  def test_newline
    assert_send_type  "() -> ::String",
                      PrettyPrint.new, :newline
  end

  def test_genspace
    assert_send_type  "() -> untyped",
                      PrettyPrint.new, :genspace
  end

  def test_indent
    assert_send_type  "() -> ::Integer",
                      PrettyPrint.new, :indent
  end

  def test_group_queue
    assert_send_type  "() -> ::PrettyPrint::GroupQueue",
                      PrettyPrint.new, :group_queue
  end

  def test_current_group
    assert_send_type  "() -> ::PrettyPrint::Group",
                      PrettyPrint.new, :current_group
  end

  def test_break_outmost_groups
    assert_send_type  "() -> untyped",
                      PrettyPrint.new, :break_outmost_groups
  end

  def test_text
    assert_send_type  "(untyped obj, ?::Integer width) -> untyped",
                      PrettyPrint.new, :text
  end

  def test_fill_breakable
    assert_send_type  "(?::String sep, ?::Integer width) -> untyped",
                      PrettyPrint.new, :fill_breakable
  end

  def test_breakable
    assert_send_type  "(?::String sep, ?::Integer width) -> untyped",
                      PrettyPrint.new, :breakable
  end

  def test_group
    assert_send_type  "(?::Integer indent, ?::String open_obj, ?::String close_obj, ?untyped open_width, ?untyped close_width) { () -> untyped } -> untyped",
                      PrettyPrint.new, :group
  end

  def test_group_sub
    assert_send_type  "() { () -> untyped } -> untyped",
                      PrettyPrint.new, :group_sub
  end

  def test_nest
    assert_send_type  "(untyped indent) { () -> untyped } -> untyped",
                      PrettyPrint.new, :nest
  end

  def test_flush
    assert_send_type  "() -> untyped",
                      PrettyPrint.new, :flush
  end
end
