require_relative 'test_helper'

class MethodInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Method'

  def self.takes_anything(*, **, &b)
    :hello
  end

  METHOD = singleton_method(:takes_anything)

  def test_op_eq(method: :==)
    with_untyped.and METHOD do |untyped|
      assert_send_type  '(untyped) -> bool',
                        METHOD, method, untyped
    end
  end

  def test_eql?
    test_op_eq(method: :eql?)
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      METHOD, :hash
  end

  def test_dup
    omit_if RUBY_VERSION < '3.4'

    assert_send_type  '() -> Method',
                      METHOD, :dup
  end

  def test_inspect(method: :inspect)
    assert_send_type  '() -> String',
                      METHOD, method
  end

  def test_to_s
    test_inspect(method: :to_s)
 end

  def test_to_proc
    assert_send_type  '() -> Proc',
                      METHOD, :to_proc
  end

  def test_call(method: :call)
    assert_send_type  '(?) -> untyped',
                      METHOD, method, :takes_anything, 1, 2i, foo: :three do end
  end

  def test_op_lsh
    callable = BlankSlate.new
    def callable.call(*, **, &b) = 1r

    with proc{}, lambda{}, method(:p), callable do |other|
      assert_send_type  '(Proc::_Callable) -> Proc',
                        METHOD, :<<, other
    end
 end

  def test_op_eqq
    test_call(method: :===)
 end

  def test_op_rsh
    callable = BlankSlate.new
    def callable.call(*, **, &b) = 1r

    with proc{}, lambda{}, method(:p), callable do |other|
      assert_send_type  '(Proc::_Callable) -> Proc',
                        METHOD, :>>, other
    end
 end

  def test_op_aref
    test_call(method: :[])
 end

  def test_arity
    arities = BlankSlate.new.__with_object_methods(:method)
    def arities.no_args = nil
    def arities.any_amount(*) = nil
    def arities.all(*, **, &x) = nil

    assert_send_type  '() -> Integer',
                      arities.method(:no_args), :arity
    assert_send_type  '() -> Integer',
                      arities.method(:any_amount), :arity
    assert_send_type  '() -> Integer',
                      arities.method(:all), :arity
  end

  def test_clone
    assert_send_type  '() -> Method',
                      METHOD, :clone
  end

  def test_curry
    assert_send_type  '() -> Proc',
                      METHOD, :curry

    with_int.and_nil do |arity|
      assert_send_type  '(int?) -> Proc',
                        METHOD, :curry, arity
    end
  end

  def test_name
    assert_send_type  '() -> Symbol',
                      METHOD, :name
  end

  def test_original_name
    assert_send_type  '() -> Symbol',
                      METHOD, :original_name
  end

  def test_owner
    assert_send_type  '() -> (Class | Module)',
                      METHOD, :owner
  end

  def test_parameters
    params = BlankSlate.new.__with_object_methods(:method)
    def params.leading_optional(a=3, b=4, c, d: 3) end
    def params.all_params(a, b=3, *c, d: 1, e:, **f, &g) end
    def params.only_ddd(...) end
    def params.tailing_ddd(a, ...) end
    def params.no_kwargs(**nil) end
    def params.shorthand(*, **, &x) end

    assert_send_type  '() -> ::Method::param_types',
                      params.method(:leading_optional), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      params.method(:all_params), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      params.method(:only_ddd), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      params.method(:tailing_ddd), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      params.method(:no_kwargs), :parameters
    assert_send_type  '() -> ::Method::param_types',
                      params.method(:shorthand), :parameters
  end

  def test_receiver
    assert_send_type  '() -> untyped',
                      METHOD, :receiver
  end

  def test_source_location
    if_ruby(..."4.1") do
      assert_send_type  '() -> [String, Integer]',
                        METHOD, :source_location
    end
    assert_send_type  '() -> nil',
                      method(:__id__), :source_location
  end

  def test_super_method
    has_super = Object.new
    def has_super.display = nil

    no_super = BlankSlate.new.__with_object_methods(:method)
    def no_super.has_no_super_method = nil

    assert_send_type  '() -> Method',
                      has_super.method(:display), :super_method

    assert_send_type  '() -> nil',
                      no_super.method(:has_no_super_method), :super_method
  end

  def test_unbind
    assert_send_type  '() -> UnboundMethod',
                      METHOD, :unbind
  end
end
