require_relative "test_helper"
require "optparse"

class OptionParserSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library "optparse"
  testing "singleton(::OptionParser)"

  def test_accept
    assert_send_type "(Class t) -> void", OptionParser, :accept, Class.new
    assert_send_type "(Class t, Regexp pat) -> void", OptionParser, :accept, Class.new, /xxx/
    assert_send_type "(Class t) { (*untyped) -> untyped } -> void", OptionParser, :accept, Class.new do end
  end

  def test_getopts
    assert_send_type "(*String) -> Hash[String, untyped]", OptionParser, :getopts, "ab:", "foo", "bar:", "zot:Z;zot option"
    assert_send_type "(Array[String], *String) -> Hash[String, untyped]", OptionParser, :getopts, ['-a'], "ab:", "foo", "bar:", "zot:Z;zot option"
  end

  def test_inc
    assert_send_type "(Integer) -> Integer", OptionParser, :inc, 1
    assert_send_type "(Integer) -> nil", OptionParser, :inc, 0
    assert_send_type "(nil) -> Integer", OptionParser, :inc, nil
    assert_send_type "(nil, Integer) -> Integer", OptionParser, :inc, nil, 10
  end

  def test_reject
    assert_send_type '(Class) -> void', OptionParser, :reject, Class.new
  end

  def test_top
    assert_send_type '() -> OptionParser::List', OptionParser, :top
  end

  def test_new
    assert_send_type "() -> OptionParser", OptionParser, :new
    assert_send_type "() { (OptionParser) -> void } -> OptionParser", OptionParser, :new do end
    assert_send_type "(String) -> OptionParser", OptionParser, :new, 'banner'
    assert_send_type "(String, Integer) -> OptionParser", OptionParser, :new, 'banner', 42
    assert_send_type "(String, Integer, String) -> OptionParser", OptionParser, :new, 'banner', 42, '  '
  end
end

class OptionParserTest < Test::Unit::TestCase
  include TypeAssertions
  library "optparse"
  testing "::OptionParser"

  def test_accept
    assert_send_type "(Class t) -> void", opt, :accept, Class.new
    assert_send_type "(Class t, Regexp pat) -> void", opt, :accept, Class.new, /xxx/
    assert_send_type "(Class t) { (*untyped) -> untyped } -> void", opt, :accept, Class.new do end
  end

  def test_banner
    assert_send_type "() -> String", opt, :banner
  end

  def test_banner=
    assert_send_type "(String) -> String", opt, :banner=, 'foo'
  end

  def test_default_argv
    assert_send_type "() -> Array[String]", opt, :default_argv
  end

  def test_default_argv=
    assert_send_type "(Array[String]) -> Array[String]", opt, :default_argv=, ['a', 'b', 'c']
  end

  def test_define
    assert_send_type "(*String) -> void", opt, :define, '-a'
    assert_send_type "(String, Class) -> void", opt, :define, '-a', Array
    assert_send_type "(String, Class, String) -> void", opt, :define, '-a', Array, 'description'
    assert_send_type "(String, Array[String]) -> void", opt, :define, '-a', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> void", opt, :define, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> void", opt, :define, '-a', /foo/
    assert_send_type "(*String, Proc) -> void", opt, :define, '-a', proc {}
  end

  def test_define_head
    assert_send_type "(*String) -> void", opt, :define_head, '-a'
    assert_send_type "(String, Class) -> void", opt, :define_head, '-a', Array
    assert_send_type "(String, Class, String) -> void", opt, :define_head, '-a', Array, 'description'
    assert_send_type "(String, Array[String]) -> void", opt, :define_head, '-a', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> void", opt, :define_head, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> void", opt, :define_head, '-a', /foo/
    assert_send_type "(*String, Proc) -> void", opt, :define_head, '-a', proc {}
  end

  def test_define_tail
    assert_send_type "(*String) -> void", opt, :define_tail, '-a'
    assert_send_type "(String, Class) -> void", opt, :define_tail, '-a', Array
    assert_send_type "(String, Class, String) -> void", opt, :define_tail, '-a', Array, 'description'
    assert_send_type "(String, Array[String]) -> void", opt, :define_tail, '-a', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> void", opt, :define_tail, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> void", opt, :define_tail, '-a', /foo/
    assert_send_type "(*String, Proc) -> void", opt, :define_tail, '-a', proc {}
  end

  def test_environment
    env = ENV.to_h
    assert_send_type '(String) -> nil', opt, :environment, 'not-exist-env'
    ENV['FOOBAROPT'] = '--foo v'
    assert_send_type '(String) -> Array[String]', opt, :environment, 'FOOBAROPT'
  ensure
    ENV.replace(env) if env
  end

  def test_getopts
    assert_send_type "(*String) -> Hash[String, untyped]", opt, :getopts, "ab:", "foo", "bar:", "zot:Z;zot option"
    assert_send_type "(Array[String], *String) -> Hash[String, untyped]", opt, :getopts, ['-a'], "ab:", "foo", "bar:", "zot:Z;zot option"
  end

  def test_help
    assert_send_type "() -> String", opt, :help
  end

  def test_on
    assert_send_type "(*String) -> self", opt, :on, '-a'
    assert_send_type "(String, Class) -> self", opt, :on, '-a', Array
    assert_send_type "(String, Class, String) -> self", opt, :on, '-a', Array, 'description'
    assert_send_type "(String, String, Class, String) -> self", opt, :on, '-a', '--all', Array, 'description'
    assert_send_type "(String, Array[String]) -> self", opt, :on, '-a', ['foo', 'bar']
    assert_send_type "(String, String, Array[String]) -> self", opt, :on, '-a', '--all', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> self", opt, :on, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, String, Hash[Symbol, untyped]) -> self", opt, :on, '-a', '--all', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> self", opt, :on, '-a', /foo/
    assert_send_type "(String, String, Regexp) -> self", opt, :on, '-a', '--all', /foo/
    assert_send_type "(*String, Proc) -> self", opt, :on, '-a', proc {}
  end

  def test_on_head
    assert_send_type "(*String) -> self", opt, :on_head, '-a'
    assert_send_type "(String, Class) -> self", opt, :on_head, '-a', Array
    assert_send_type "(String, Class, String) -> self", opt, :on_head, '-a', Array, 'description'
    assert_send_type "(String, String, Class, String) -> self", opt, :on_head, '-a', '--all', Array, 'description'
    assert_send_type "(String, Array[String]) -> self", opt, :on_head, '-a', ['foo', 'bar']
    assert_send_type "(String, String, Array[String]) -> self", opt, :on_head, '-a', '--all', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> self", opt, :on_head, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, String, Hash[Symbol, untyped]) -> self", opt, :on_head, '-a', '--all', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> self", opt, :on_head, '-a', /foo/
    assert_send_type "(String, String, Regexp) -> self", opt, :on_head, '-a', '--all', /foo/
    assert_send_type "(*String, Proc) -> self", opt, :on_head, '-a', proc {}
  end

  def test_on_tail
    assert_send_type "(*String) -> self", opt, :on_tail, '-a'
    assert_send_type "(String, Class) -> self", opt, :on_tail, '-a', Array
    assert_send_type "(String, Class, String) -> self", opt, :on_tail, '-a', Array, 'description'
    assert_send_type "(String, String, Class, String) -> self", opt, :on_tail, '-a', '--all', Array, 'description'
    assert_send_type "(String, Array[String]) -> self", opt, :on_tail, '-a', ['foo', 'bar']
    assert_send_type "(String, String, Array[String]) -> self", opt, :on_tail, '-a', '--all', ['foo', 'bar']
    assert_send_type "(String, Hash[Symbol, untyped]) -> self", opt, :on_tail, '-a', {foo: 1, bar: 2}
    assert_send_type "(String, String, Hash[Symbol, untyped]) -> self", opt, :on_tail, '-a', '--all', {foo: 1, bar: 2}
    assert_send_type "(String, Regexp) -> self", opt, :on_tail, '-a', /foo/
    assert_send_type "(String, String, Regexp) -> self", opt, :on_tail, '-a', '--all', /foo/
    assert_send_type "(*String, Proc) -> self", opt, :on_tail, '-a', proc {}
  end

  def test_order
    assert_send_type "(*String) -> Array[String]", opt, :order, '--foo', '42'
    assert_send_type "(*String, into: Hash[untyped, untyped]) -> Array[String]", opt, :order, '--foo', '42', into: {}
    assert_send_type "(*String) { (String) -> void } -> Array[String]", opt, :order, '--foo', '42' do end
    assert_send_type "(Array[String]) -> Array[String]", opt, :order, %w[--foo 42]
  end

  def test_order!
    assert_send_type "(Array[String]) -> Array[String]", opt, :order!, %w[--foo 42]
    assert_send_type "(Array[String], into: Hash[untyped, untyped]) -> Array[String]", opt, :order!, %w[--foo 42], into: {}
    assert_send_type "(Array[String]) { (String) -> void } -> Array[String]", opt, :order!, %w[--foo 42] do end
  end

  def test_parse
    assert_send_type "(*String) -> Array[String]", opt, :parse, '--foo', '42'
    assert_send_type "(*String, into: Hash[untyped, untyped]) -> Array[String]", opt, :parse, '--foo', '42', into: {}
    assert_send_type "(Array[String]) -> Array[String]", opt, :parse, %w[--foo 42]
  end

  def test_parse!
    assert_send_type "(Array[String]) -> Array[String]", opt, :parse!, %w[--foo 42]
    assert_send_type "(Array[String], into: Hash[untyped, untyped]) -> Array[String]", opt, :parse!, %w[--foo 42], into: {}
  end

  def test_permute
    assert_send_type "(*String) -> Array[String]", opt, :permute, '--foo', '42'
    assert_send_type "(*String, into: Hash[untyped, untyped]) -> Array[String]", opt, :permute, '--foo', '42', into: {}
    assert_send_type "(Array[String]) -> Array[String]", opt, :permute, %w[--foo 42]
  end

  def test_permute!
    assert_send_type "(Array[String]) -> Array[String]", opt, :permute!, %w[--foo 42]
    assert_send_type "(Array[String], into: Hash[untyped, untyped]) -> Array[String]", opt, :permute!, %w[--foo 42], into: {}
  end

  def test_program_name
    assert_send_type "() -> String", opt, :program_name
  end

  def test_program_name=
    assert_send_type "(String) -> String", opt, :program_name=, 'foo'
  end

  def test_reject
    assert_send_type '(Class) -> void', opt, :reject, Class.new
  end

  def test_summarize
    assert_send_type '() -> Array[String]', opt, :summarize
    assert_send_type '(Array[String]) -> Array[String]', opt, :summarize, []
    assert_send_type '(Array[String], Integer) -> Array[String]', opt, :summarize, [], 100
    assert_send_type '(Array[String], Integer, Integer) -> Array[String]', opt, :summarize, [], 100, 99
    assert_send_type '(Array[String], Integer, Integer, String) -> Array[String]', opt, :summarize, [], 100, 99, '  '
    assert_send_type '() { (String) -> void } -> Array[String]', opt, :summarize do end
  end

  def test_to_a
    assert_send_type '() -> Array[String]', opt, :to_a
  end

  def test_top
    assert_send_type '() -> OptionParser::List', opt, :top
  end

  def opt
    OptionParser.new do |opt|
      opt.on('--foo value')
    end
  end
end

class OptionParserArguableTest < Test::Unit::TestCase
  class Target < Array
    include OptionParser::Arguable
  end

  include TypeAssertions
  library "optparse"
  testing "::OptionParser::Arguable"

  def test_getopts
    assert_send_type '(*String) -> Hash[String, untyped]', subject, :getopts, 'ab:'
  end

  def test_options
    assert_send_type '() -> OptionParser', subject, :options
    assert_send_type '() { (OptionParser) -> String } -> String', subject, :options do "foo" end
  end

  def test_options=
    assert_send_type '(OptionParser) -> untyped', subject, :options=, OptionParser.new
    assert_send_type '(nil) -> untyped', subject, :options=, nil
  end

  def test_order!
    subject.options.on('-a')
    assert_send_type "() -> Array[String]", subject, :order!
    assert_send_type "() { (String) -> void } -> Array[String]", subject, :order! do end
  end

  def test_parse!
    subject.options.on('-a')
    assert_send_type "() -> Array[String]", subject, :parse!
  end

  def test_permute!
    subject.options.on('-a')
    assert_send_type "() -> Array[String]", subject, :permute!
  end

  def subject
    @subject ||= Target.new(%w[-a 42])
  end
end
