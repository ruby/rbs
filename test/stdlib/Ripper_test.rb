require_relative "test_helper"

class RipperSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "ripper"
  testing "singleton(::Ripper)"

  def test_new
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno) -> ::Ripper",
                     Ripper, :new, "def a; end"
  end

  def test_dedent_string
    assert_send_type "(::String input, ::int width) -> ::Integer",
                     Ripper, :dedent_string, "", 0
  end

  def test_lex
    assert_send_type "(::String src, ?::String filename, ?::Integer lineno, ?raise_errors: ::boolish) -> ::Array[[ [ ::Integer, ::Integer ], ::Symbol, ::String, ::Ripper::Lexer::State ]]",
                     Ripper, :lex, "def a; end"
  end

  def test_lex_state_name
    assert_send_type "(::int) -> ::String",
                     Ripper, :lex_state_name, 1
  end

  def test_parse
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno) -> nil",
                     Ripper, :parse, "def a; end"
  end

  def test_sexp
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno, ?raise_errors: ::boolish) -> ::Array[untyped]",
                     Ripper, :sexp, "def a; end"
  end

  def test_sexp_raw
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno, ?raise_errors: ::boolish) -> ::Array[untyped]",
                     Ripper, :sexp_raw, "def a; end"
  end

  def test_slice
    assert_send_type "(::String src, ::String pattern, ?::Integer n) -> ::String?",
                     Ripper, :slice, "def a; end", ""
  end

  def test_token_match
    assert_send_type "(::String src, ::String pattern) -> ::Ripper::TokenPattern::MatchData?",
                     Ripper, :token_match, "def a; end", ""
  end

  def test_tokenize
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno, ?raise_errors: ::boolish) -> ::Array[::String]",
                     Ripper, :tokenize, "def a; end"
  end
end

class RipperTest < Test::Unit::TestCase
  include TypeAssertions

  library "ripper"
  testing "::Ripper"

  def test_warn
    assert_send_type "(untyped fmt, *untyped args) -> untyped",
                     Ripper.new("def a; end"), :warn, ""
  end

  def test_column
    assert_send_type "() -> ::Integer?",
                     Ripper.new("def a; end"), :column
  end

  def test_debug_output
    assert_send_type "() -> untyped",
                     Ripper.new("def a; end"), :debug_output
  end

  def test_debug_output=
    assert_send_type "(untyped) -> untyped",
                     Ripper.new("def a; end"), :debug_output=, true
  end

  def test_encoding
    assert_send_type "() -> ::Encoding",
                     Ripper.new("def a; end"), :encoding
  end

  def test_end_seen?
    assert_send_type "() -> bool",
                     Ripper.new("def a; end"), :end_seen?
  end

  def test_error?
    assert_send_type "() -> bool",
                     Ripper.new("def a; end"), :error?
  end

  def test_filename
    assert_send_type "() -> ::String",
                     Ripper.new("def a; end"), :filename
  end

  def test_lineno
    assert_send_type "() -> ::Integer?",
                     Ripper.new("def a; end"), :lineno
  end

  def test__dispatch_0
    assert_send_type "() -> void",
                     Ripper.new("def a; end"), :_dispatch_0
  end

  def test__dispatch_1
    assert_send_type "(untyped a) -> void",
                     Ripper.new("def a; end"), :_dispatch_1, ""
  end

  def test__dispatch_2
    assert_send_type "(untyped a, untyped b) -> void",
                     Ripper.new("def a; end"), :_dispatch_2, "", ""
  end

  def test__dispatch_3
    assert_send_type "(untyped a, untyped b, untyped c) -> void",
                     Ripper.new("def a; end"), :_dispatch_3, "", "", ""
  end

  def test__dispatch_4
    assert_send_type "(untyped a, untyped b, untyped c, untyped d) -> void",
                     Ripper.new("def a; end"), :_dispatch_4, "", "", "", ""
  end

  def test__dispatch_5
    assert_send_type "(untyped a, untyped b, untyped c, untyped d, untyped e) -> void",
                     Ripper.new("def a; end"), :_dispatch_5, "", "", "", "", ""
  end

  def test__dispatch_6
    assert_send_type "(untyped a, untyped b, untyped c, untyped d, untyped e, untyped f) -> void",
                     Ripper.new("def a; end"), :_dispatch_6, "", "", "", "", "", ""
  end

  def test__dispatch_7
    assert_send_type "(untyped a, untyped b, untyped c, untyped d, untyped e, untyped f, untyped g) -> void",
                     Ripper.new("def a; end"), :_dispatch_7, "", "", "", "", "", "", ""
  end

  def test_parse
    assert_send_type "() -> nil",
                     Ripper.new("def a; end"), :parse
  end

  def test_state
    assert_send_type "() -> ::Integer?",
                     Ripper.new("def a; end"), :state
  end

  def test_token
    assert_send_type "() -> ::String?",
                     Ripper.new("def a; end"), :token
  end

  def test_yydebug
    assert_send_type "() -> bool",
                     Ripper.new("def a; end"), :yydebug
  end

  def test_yydebug=
    assert_send_type "(bool) -> bool",
                     Ripper.new("def a; end"), :yydebug=, true
  end

  def test_compile_error
    assert_send_type "(untyped msg) -> untyped",
                     Ripper.new("def a; end"), :compile_error, ""
  end

  def test_dedent_string
    assert_send_type "(String input, Integer width) -> Integer",
                     Ripper.new("def a; end"), :dedent_string, "", 0
  end

  def test_warning
    assert_send_type "(untyped fmt, *untyped args) -> untyped",
                     Ripper.new("def a; end"), :warning, ""
  end
end

class Ripper::FilterSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "ripper"
  testing "singleton(::Ripper::Filter)"

  def test_new
    assert_send_type "(::File | ::Ripper::_Gets | ::String src, ?::String filename, ?::Integer lineno) -> ::Ripper::Filter",
                     Ripper::Filter, :new, "def a; end"
  end
end

class Ripper::FilterTest < Test::Unit::TestCase
  include TypeAssertions

  library "ripper"
  testing "::Ripper::Filter"

  def test_column
    assert_send_type "() -> ::Integer?",
                     Ripper::Filter.new("def a; end"), :column
  end

  def test_filename
    assert_send_type "() -> ::String",
                     Ripper::Filter.new("def a; end").tap(&:parse), :filename
  end

  def test_lineno
    assert_send_type "() -> ::Integer?",
                     Ripper::Filter.new("def a; end").tap(&:parse), :lineno
  end

  def test_parse
    assert_send_type "(?untyped init) -> untyped",
                     Ripper::Filter.new("def a; end"), :parse
  end

  def test_state
    assert_send_type "() -> untyped",
                     Ripper::Filter.new("def a; end").tap(&:parse), :state
  end
end
