require_relative "test_helper"
require "pathname"
require "tmpdir"

class MarshalSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  testing "singleton(::Marshal)"

  def test_MAJOR_VERSION
    assert_const_type 'Integer', 'Marshal::MAJOR_VERSION'
  end

  def test_MINOR_VERSION
    assert_const_type 'Integer', 'Marshal::MINOR_VERSION'
  end

  def test_dump
    obj = Object.new

    assert_send_type  '(untyped) -> String',
                      Marshal, :dump, obj
    assert_send_type  '(untyped, Integer) -> String',
                      Marshal, :dump, obj, 123

    writer = Writer.new
    assert_send_type  '(untyped, Writer) -> Writer',
                      Marshal, :dump, obj, writer

    with_int.chain([nil]).each do |limit|
      assert_send_type  '(untyped, Writer, int?) -> Writer',
                        Marshal, :dump, obj, writer, limit
    end
  end

  def with_source(src = Marshal.dump(Object.new))
    with_string src do |string|
      def string.reset!; end
      yield string
    end

    src = src.chars
    source = Struct.new(:source).new(src.dup)
    source.define_singleton_method(:reset!) do
      self.source = src.dup
    end

    # String, String
    def source.getbyte; source.shift end
    def source.read(x) source.shift(x).join end
    yield source

    # int, string
    source.reset!
    def source.getbyte; ToInt.new(source.shift.ord) end
    def source.read(x) ToStr.new(source.shift(x).join) end
    yield source
  end

  def test_load(meth = :load)
    result_proc = Object.new
    def result_proc.call(loaded) 1r end

    with_source do |source|
      assert_send_type  '(string | Marshal::_Source) -> untyped',
                        Marshal, meth, source
      source.reset!

      assert_send_type  '(string | Marshal::_Source, Marshal::_Proc[Rational]) -> Rational',
                        Marshal, meth, source, result_proc
      source.reset!

      [nil, :yep, true, "hello"].each do |freeze|
        assert_send_type  '(string | Marshal::_Source, freeze: boolish) -> untyped',
                          Marshal, meth, source, freeze: freeze
        source.reset!

        assert_send_type  '(string | Marshal::_Source, Marshal::_Proc[Rational], freeze: boolish) -> Rational',
                          Marshal, meth, source, result_proc, freeze: freeze
        source.reset!
      end
    end
  end

  def test_restore
    test_load :restore
  end
end

class MarshalIncludeTest < Test::Unit::TestCase
  include TypeAssertions
  testing "::Marshal"

  def test_dump
    obj = Object.new

    assert_send_type  '(untyped) -> String',
                      Marshal, :dump, obj
    assert_send_type  '(untyped, Integer) -> String',
                      Marshal, :dump, obj, 123

    writer = Writer.new
    assert_send_type  '(untyped, Writer) -> Writer',
                      Marshal, :dump, obj, writer

    with_int.chain([nil]).each do |limit|
      assert_send_type  '(untyped, Writer, int?) -> Writer',
                        Marshal, :dump, obj, writer, limit
    end
  end
end
