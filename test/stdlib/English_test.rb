require_relative "test_helper"
require "English"

class EnglishGlobalVariablesTest < Test::Unit::TestCase
  include TestHelper

  library "english"

  # Same as `GlobalVariablesTest#assert_global_type`, but the value is always given by the block,
  # because some of the variables (`$LAST_MATCH_INFO`, `$LAST_READ_LINE`, and those derived from
  # `$LAST_MATCH_INFO`) are local to the method frame.
  def assert_global_type(type, global_name)
    global = yield

    assert_type type, global

    entry = env.global_decls.fetch(global_name) { flunk "Cannot find RBS global declaration of `#{global_name}`" }
    assert_type entry.decl.type, global
  end

  def test_ERROR_INFO
    assert_global_type 'nil', :$ERROR_INFO do $ERROR_INFO end

    begin
      fail "oops"
    rescue
      assert_global_type 'Exception', :$ERROR_INFO do $ERROR_INFO end
    end
  end

  def test_ERROR_POSITION
    assert_global_type 'nil', :$ERROR_POSITION do $ERROR_POSITION end

    begin
      fail "oops"
    rescue
      assert_global_type 'Array[String]', :$ERROR_POSITION do $ERROR_POSITION end
    end
  end

  def test_FS
    # Don't test non-nil values as they're deprecated
    assert_global_type 'nil', :$FS do $FS end
    assert_global_type 'nil', :$FIELD_SEPARATOR do $FIELD_SEPARATOR end
  end

  def test_OFS
    # Don't test non-nil values as they're deprecated
    assert_global_type 'nil', :$OFS do $OFS end
    assert_global_type 'nil', :$OUTPUT_FIELD_SEPARATOR do $OUTPUT_FIELD_SEPARATOR end
  end

  def test_RS
    assert_global_type 'String', :$RS do $RS end
    assert_global_type 'String', :$INPUT_RECORD_SEPARATOR do $INPUT_RECORD_SEPARATOR end
  end

  def test_ORS
    # Don't test non-nil values as they're deprecated
    assert_global_type 'nil', :$ORS do $ORS end
    assert_global_type 'nil', :$OUTPUT_RECORD_SEPARATOR do $OUTPUT_RECORD_SEPARATOR end
  end

  def test_NR
    assert_global_type 'Integer', :$NR do $NR end
    assert_global_type 'Integer', :$INPUT_LINE_NUMBER do $INPUT_LINE_NUMBER end
  end

  def test_LAST_READ_LINE
    $_ = nil
    assert_global_type 'nil', :$LAST_READ_LINE do $LAST_READ_LINE end

    $_ = "line"
    assert_global_type 'String', :$LAST_READ_LINE do $LAST_READ_LINE end
  end

  def test_DEFAULT_OUTPUT
    assert_global_type 'IO', :$DEFAULT_OUTPUT do $DEFAULT_OUTPUT end
  end

  module ::RBS
    module Unnamed
      ARGFClass ||= ARGF.class
    end
  end

  def test_DEFAULT_INPUT
    assert_global_type '::RBS::Unnamed::ARGFClass', :$DEFAULT_INPUT do $DEFAULT_INPUT end
  end

  def test_PID
    assert_global_type 'Integer', :$PID do $PID end
    assert_global_type 'Integer', :$PROCESS_ID do $PROCESS_ID end
  end

  def test_CHILD_STATUS
    # `$?` is thread-local; running it in threads is the best way to have control over it.
    Thread.new do
      assert_global_type 'nil', :$CHILD_STATUS do $CHILD_STATUS end
    end.join

    Thread.new do
      system(RUBY_EXECUTABLE, '-v', out: File::NULL)
      assert_global_type 'Process::Status', :$CHILD_STATUS do $CHILD_STATUS end
    end.join
  end

  def test_ARGV
    assert_global_type 'Array[String]', :$ARGV do $ARGV end
  end

  def test_LAST_MATCH_INFO
    assert_global_type 'nil', :$LAST_MATCH_INFO do $LAST_MATCH_INFO end

    's' =~ /s/
    assert_global_type 'MatchData', :$LAST_MATCH_INFO do $LAST_MATCH_INFO end
  end

  def test_MATCH
    assert_global_type 'nil', :$MATCH do $MATCH end

    's' =~ /s/
    assert_global_type 'String', :$MATCH do $MATCH end
  end

  def test_PREMATCH
    assert_global_type 'nil', :$PREMATCH do $PREMATCH end

    's' =~ /s/
    assert_global_type 'String', :$PREMATCH do $PREMATCH end
  end

  def test_POSTMATCH
    assert_global_type 'nil', :$POSTMATCH do $POSTMATCH end

    's' =~ /s/
    assert_global_type 'String', :$POSTMATCH do $POSTMATCH end
  end

  def test_LAST_PAREN_MATCH
    assert_global_type 'nil', :$LAST_PAREN_MATCH do $LAST_PAREN_MATCH end

    's' =~ /(s)/
    assert_global_type 'String', :$LAST_PAREN_MATCH do $LAST_PAREN_MATCH end
  end
end
