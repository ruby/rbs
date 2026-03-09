require_relative 'test_helper'

class GlobalVariablesTest < Test::Unit::TestCase
  include TestHelper
  def assert_global_type(type, global_name)
    # The block is to allow for access to regex globals, which aren't technically global variables.
    # I wish there was a `global_variable_get`; alas, `eval`.
    global = block_given? ? yield : eval(global_name.to_s, nil, $0, $.)

    typecheck = RBS::Test::TypeCheck.new(
      self_class: global.class,
      builder: builder,
      sample_size: 100,
      unchecked_classes: []
    )

    value_type =
      case type
      when String
        RBS::Parser.parse_type(type, variables: []) || raise
      else
        type
      end

    assert typecheck.value(global, value_type), "`#{global_name}` (#{global.inspect}) must be compatible with given type `#{value_type}`"
  end

  def test_gvar_exclaimation
    assert_global_type 'nil', :$!

    begin
      fail "oops"
    rescue
      assert_global_type 'Exception', :$!
    end
  end

  def test_gvar_double_quote
    test_gvar_LOADED_FEATURES(gvar: :$")
  end

  def test_gvar_dollar
    assert_global_type 'Integer', :$$
  end

  def test_gvar_ampersand
    assert_global_type 'nil', :$& do $& end

    's' =~ /s/
    assert_global_type 'String', :$& do $& end
  end

  def test_gvar_single_quote
    assert_global_type 'nil', :$' do $' end

    's' =~ /s/
    assert_global_type 'String', :$' do $' end
  end

  def test_gvar_asterisk
    assert_global_type 'Array[String]', :$*
  end

  def test_gvar_plus
    assert_global_type 'nil', :$+ do $+ end

    's' =~ /(s)/
    assert_global_type 'String', :$+ do $+ end
  end

  def test_gvar_comma
    # Don't test other `$,`s as they're deprecated
    assert_global_type 'nil', :$, # TODO: do we want to add tests for strings?
  end

  def test_gvar_hyphen_0
    test_gvar_forward_slash(gvar: :$-0)
  end

  def test_gvar_hyphen_F
    test_gvar_semicolon(gvar: :$-F)
  end

  def test_gvar_hyphen_I
    test_gvar_LOAD_PATH(gvar: :$-I)
  end

  def test_gvar_hyphen_W
    old = $VERBOSE

    $VERBOSE = nil
    assert_global_type '0', :$-W

    $VERBOSE = false
    assert_global_type '1', :$-W

    $VERBOSE = true
    assert_global_type '2', :$-W

    $VERBOSE = :hello
    assert_global_type '2', :$-W
  ensure
    $VERBOSE = old
  end

  def test_gvar_hyphen_a
    assert_global_type 'bool', :$-a
  end

  def test_gvar_hyphen_d
    test_gvar_DEBUG(gvar: :$-d)
  end

  def test_gvar_hyphen_v
    test_gvar_VERBOSE(gvar: :$-v)
  end

  def test_gvar_hyphen_w
    test_gvar_VERBOSE(gvar: :$-w)
  end

  def test_gvar_period
    old_lineno = $.

    assert_global_type 'Integer', :$.

    $. = ToInt.new(123)
    assert_global_type '123', :$.
  ensure
    $. = old_lineno
  end

  def test_gvar_forward_slash(gvar: :$/)
    # Don't test other `$/`s as they're deprecated
    assert_global_type 'String', gvar
  end

  def test_gvar_0
    test_gvar_PROGRAM_NAME(gvar: :$0)
  end

  def test_gvar_1_2_3_4_5_6_7_8_9
    assert_global_type 'nil', :$1 do $1 end
    assert_global_type 'nil', :$2 do $2 end
    assert_global_type 'nil', :$3 do $3 end
    assert_global_type 'nil', :$4 do $4 end
    assert_global_type 'nil', :$5 do $5 end
    assert_global_type 'nil', :$6 do $6 end
    assert_global_type 'nil', :$7 do $7 end
    assert_global_type 'nil', :$8 do $8 end
    assert_global_type 'nil', :$9 do $9 end

    '123456789' =~ /(1)(2)(3)(4)(5)(6)(7)(8)(9)/

    assert_global_type 'String', :$1 do $1 end
    assert_global_type 'String', :$2 do $2 end
    assert_global_type 'String', :$3 do $3 end
    assert_global_type 'String', :$4 do $4 end
    assert_global_type 'String', :$5 do $5 end
    assert_global_type 'String', :$6 do $6 end
    assert_global_type 'String', :$7 do $7 end
    assert_global_type 'String', :$8 do $8 end
    assert_global_type 'String', :$9 do $9 end
  end

  def test_gvar_colon
    test_gvar_LOAD_PATH(gvar: :$:)
  end

  def test_gvar_semicolon(gvar: :$;)
    # Don't test other `$;`s as they're deprecated
    assert_global_type 'nil', gvar
  end

  module ::RBS
    module Unnamed
      ARGFClass ||= ARGF.class
    end
  end
  def test_gvar_lessthan
    # The actual tests are done in `ARGF_test.rb`
    assert_global_type '::RBS::Unnamed::ARGFClass', :$<
  end

  def test_gvar_equals
    old_deprecated = Warning[:deprecated]
    Warning[:deprecated] = false

    # `$=` is warned on with `:deprecated` (with `-v`) even if we're just accessing it.
    assert_global_type 'false', :$=
  ensure
    Warning[:deprecated] = old_deprecated
  end

  def test_gvar_gretterthan
    test_gvar_stdout(gvar: :$>)
  end

  def test_gvar_question
    # `$?` is thread-local, and there's no way to ensure that it wasn't set ahead-of-time; running
    # it in threads is the best way to have control over it.
    Thread.new do
      assert_global_type 'nil', :$?
    end.join

    Thread.new do
      system(RUBY_EXECUTABLE, '-v')
      assert_global_type 'Process::Status', :$?
    end.join
  end

  def test_gvar_atsign
    assert_global_type 'nil', :$@

    begin
      fail "oops"
    rescue
      assert_global_type 'Array[String]', :$@
    end
  end

  def test_gvar_DEBUG(gvar: :$DEBUG)
    orig_debug = $DEBUG

    # We have to test this way because otherwise we get a stack overflow, due to it being used
    # internally.
    $DEBUG = false
    with_boolish do |boolish|
      begin
        $DEBUG = boolish
        value = $DEBUG
      ensure
        $DEBUG = false
      end

      assert_type 'boolish', eval(gvar.to_s)
    end
  ensure
    $DEBUG = orig_debug
  end

  def test_gvar_FILENAME
    old_argv = $*.dup

    $*.replace [__FILE__]
    assert_global_type 'String', :$FILENAME

    $*.clear
    assert_global_type 'String', :$FILENAME
  ensure
    $*.replace old_argv
  end

  def test_gvar_LOADED_FEATURES(gvar: :$LOADED_FEATURES)
    assert_global_type 'Array[String]', gvar
  end

  def test_gvar_LOAD_PATH(gvar: :$LOAD_PATH)
    assert_global_type 'Array[String] & _LoadPathAPI', gvar

    # Since we cant test the "`$LOAD_PATH` class" (which doesn't exist; the `resolve_feature_path`
    # is a singleton method), we can't use `assert_send_type` and must use `assert_type`.
    loadpath = eval(gvar.to_s)

    with_path 'erb' do |path|
      assert_type '[:rb | :so, String]', loadpath.resolve_feature_path(path)
    end

    with_path '__RBS_not-a-real-gem' do |path|
      assert_type 'nil', loadpath.resolve_feature_path(path)
    end
  end

  def test_gvar_PROGRAM_NAME(gvar: :$PROGRAM_NAME)
    assert_global_type 'String', gvar
  end

  def test_gvar_VERBOSE(gvar: :$VERBOSE)
    orig_verbose = $VERBOSE

    $VERBOSE = nil
    assert_global_type 'nil', gvar

    $VERBOSE = false
    assert_global_type 'false', gvar

    $VERBOSE = true
    assert_global_type 'true', gvar

    $VERBOSE = :hello
    assert_global_type 'true', gvar

  ensure
    $VERBOSE = orig_verbose
  end

  def test_gvar_backwards_slash
    # Don't test other `$\`s as they're deprecated
    assert_global_type 'nil', $\
  end

  def test_gvar_underscore
    # Technically, `$_` can be assigned to whatever type you want. However, all builtin methods
    # make sure to have it assigned to a `String` or `nil` (and that's the most useful variant of
    # it), so it's been typechecked to just be `String?`.
    # Also, it's a method-local variable, so no need to reset it.

    $_ = nil
    assert_global_type 'nil', :$_ do $_ end

    $_ = "string!"
    assert_global_type 'String', :$_ do $_ end
  end

  def test_gvar_grave
    assert_global_type 'nil', :$` do $` end

    's' =~ /s/
    assert_global_type 'String', :$` do $` end
  end

  def test_gvar_stderr
    assert_global_type 'IO', :$stderr
  end

  def test_gvar_stdout(gvar: :$stdout)
    assert_global_type 'IO', gvar
  end

  def test_gvar_stdin
    assert_global_type 'IO', :$stdin
  end

  def test_gvar_tilde
    assert_global_type 'nil', :$~ do $~ end

    's' =~ /s/
    assert_global_type 'MatchData' , :$~ do $~ end
  end

end
