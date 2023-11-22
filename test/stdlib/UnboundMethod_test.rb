require_relative 'test_helper'

class UnboundMethodInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing '::UnboundMethod'

  UMETH = Rational.instance_method(:to_s)

  module ParamMeths
    def leading_optional(a=3, b=4, c, d: 3) end
    def all_params(a, b=3, *c, d: 1, e:, **f, &g) end
    def only_ddd(...) end
    def tailing_ddd(a, ...) end
    def no_kwargs(**nil) end
    eval "def shorthand(*, **, &) end" unless RUBY_VERSION < '3.1'
  end

  def test_eq
    with_untyped.and(UMETH) do |other|
      assert_send_type  '(untyped) -> bool',
                        UMETH, :==, other
    end
  end

  def test_eql?
    with_untyped.and(UMETH) do |other|
      assert_send_type  '(untyped) -> bool',
                        UMETH, :eql?, other
    end
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      UMETH, :hash
  end

  def test_clone
    assert_send_type  '() -> instance',
                      UMETH, :clone
  end

  def test_arity
    assert_send_type  '() -> Integer',
                      UMETH, :arity
  end

  def test_bind
    assert_send_type  '(untyped) -> Method',
                      UMETH, :bind, 1r
  end

  def test_inspect
    assert_send_type  '() -> String',
                      UMETH, :inspect
  end

  def test_to_s
    assert_send_type  '() -> String',
                      UMETH, :to_s
  end

  def test_name
    assert_send_type  '() -> Symbol',
                      UMETH, :name
  end

  def test_owner
    assert_send_type  '() -> (Class | Module)',
                      UMETH, :owner
    assert_send_type  '() -> (Class | Module)',
                      Module.method(:private).unbind, :owner
  end

  def test_parameters
    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:leading_optional), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:all_params), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:only_ddd), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:tailing_ddd), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:no_kwargs), :parameters
    
    omit_if(RUBY_VERSION < '3.1')

    assert_send_type  '() -> ::Method::param_types',
                      ParamMeths.instance_method(:shorthand), :parameters
  end

  def test_source_location
    assert_send_type  '() -> [String, Integer]?',
                      UMETH, :source_location
    assert_send_type  '() -> [String, Integer]?',
                      ParamMeths.instance_method(:leading_optional), :source_location
  end

  def test_super_method
    assert_send_type  '() -> UnboundMethod?',
                      UMETH, :super_method
    assert_send_type  '() -> UnboundMethod?',
                      ParamMeths.instance_method(:leading_optional), :super_method
  end

  def test_original_name
    assert_send_type  '() -> Symbol',
                      UMETH, :original_name
  end

  def test_bind_call
    assert_send_type  '(untyped, *untyped, **untyped) ?{ (*untyped, **untyped) -> untyped } -> untyped',
                      UMETH, :bind_call, 1r
    assert_send_type  '(untyped, *untyped, **untyped) ?{ (*untyped, **untyped) -> untyped } -> untyped',
                      ParamMeths.instance_method(:only_ddd), :bind_call, Object.new.extend(ParamMeths)
  end
end
