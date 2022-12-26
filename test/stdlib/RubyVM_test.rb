require_relative "test_helper"

class RubyVM::AbstractSyntaxTreeSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::RubyVM::AbstractSyntaxTree)"

  def test_parse
    assert_send_type "(::String string, ?keep_script_lines: bool, ?error_tolerant: bool, ?keep_tokens: bool) -> ::RubyVM::AbstractSyntaxTree::Node",
                     RubyVM::AbstractSyntaxTree, :parse, "1 + 2"
  end

  def test_parse_file
    assert_send_type "(::String | ::_ToPath string, ?keep_script_lines: bool, ?error_tolerant: bool, ?keep_tokens: bool) -> ::RubyVM::AbstractSyntaxTree::Node",
                     RubyVM::AbstractSyntaxTree, :parse_file, __FILE__
  end

  def test_of
    assert_send_type "(::Proc | ::Method | ::UnboundMethod body, ?keep_script_lines: bool, ?error_tolerant: bool, ?keep_tokens: bool) -> ::RubyVM::AbstractSyntaxTree::Node?",
                     RubyVM::AbstractSyntaxTree, :of, method(:test_of)
  end

  if RUBY_VERSION >= '3.2'
    def test_node_id_for_backtrace_location
      assert_send_type "(::Thread::Backtrace::Location backtrace_location) -> ::Integer",
                      RubyVM::AbstractSyntaxTree, :node_id_for_backtrace_location, caller_locations[0]
    end
  end
end

class RubyVM::AbstractSyntaxTree::NodeTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::RubyVM::AbstractSyntaxTree::Node"

  def test_type
    assert_send_type "() -> ::Symbol",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :type
  end

  def test_first_lineno
    assert_send_type "() -> ::Integer",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :first_lineno
  end

  def test_first_column
    assert_send_type "() -> ::Integer",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :first_column
  end

  def test_last_lineno
    assert_send_type "() -> ::Integer",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :last_lineno
  end

  def test_last_column
    assert_send_type "() -> ::Integer",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :last_column
  end

  if RUBY_VERSION >= '3.2'
    def test_tokens
      assert_send_type "() -> ::Array[[ ::Integer, ::Symbol, ::String, [ ::Integer, ::Integer, ::Integer, ::Integer ] ]]?",
                      RubyVM::AbstractSyntaxTree.parse("1 + 2", keep_tokens: true), :tokens
    end

    def test_all_tokens
      assert_send_type "() -> ::Array[[ ::Integer, ::Symbol, ::String, [ ::Integer, ::Integer, ::Integer, ::Integer ] ]]?",
                      RubyVM::AbstractSyntaxTree.parse("1 + 2", keep_tokens: true), :all_tokens
    end
  end

  def test_children
    assert_send_type "() -> ::Array[untyped]",
                     RubyVM::AbstractSyntaxTree.parse("1 + 2"), :children
  end
end
