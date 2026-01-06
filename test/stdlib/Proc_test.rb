require_relative 'test_helper'

class ProcSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Proc)'

  class MyProc < Proc
  end

  def test_new
    assert_send_type '() { (?) -> untyped } -> ProcSingletonTest::MyProc',
                     MyProc, :new do end
  end
end

class ProcInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Proc'

  class MyProc < Proc
  end

  def test_clone
    assert_send_type '() -> ProcInstanceTest::MyProc',
                     MyProc.new{}, :clone
  end

  def test_dup
    assert_send_type '() -> ProcInstanceTest::MyProc',
                     MyProc.new{}, :dup
  end

  def test_op_eqq
    test_call(method: :===)
  end

  def test_yield
    test_call(method: :yield)
  end


  def test_op_lsh
    # Ensure it returns a Proc regardless of self and other type
    assert_send_type  '(ProcInstanceTest::MyProc) -> Proc',
                      MyProc.new{}, :<<, MyProc.new{}

    callable = BlankSlate.new
    def callable.call(*, **, &b) = 1r

    with proc{}, lambda{}, method(:p), callable do |other|
      assert_send_type  '(Proc::_Callable) -> Proc',
                        proc{}, :<<, other
    end
  end

  def test_op_rsh
    # Ensure it returns a Proc regardless of self and other type
    assert_send_type  '(ProcInstanceTest::MyProc) -> Proc',
                      MyProc.new{}, :>>, MyProc.new{}

    callable = BlankSlate.new
    def callable.call(*, **, &b) = 1r

    with proc{}, lambda{}, method(:p), callable do |other|
      assert_send_type  '(Proc::_Callable) -> Proc',
                        proc{}, :>>, other
    end

  end

  def test_op_eq(method: :==)
    with_untyped.and proc{} do |untyped|
      assert_send_type  '(untyped) -> bool',
                        proc{}, method, untyped
    end
  end

  def test_eql?
    test_op_eq(method: :eql?)
  end

  def test_arity
    assert_send_type  '() -> Integer',
                      proc{}, :arity
    assert_send_type  '() -> Integer',
                      proc{|x|}, :arity
    assert_send_type  '() -> Integer',
                      proc{|*x|}, :arity
  end

  def test_binding
    assert_send_type  '() -> Binding',
                      proc{}, :binding
  end

  def test_call(method: :call)
    assert_send_type  '(?) -> untyped',
                      proc{1r}, method, 1, 2i, foo: :three do end
  end

  def test_op_aref
    test_call(method: :[])
  end

  def test_curry
    # Use `MyProc` to ensure it returns `Proc` and not `instance`.
    assert_send_type  '() -> Proc',
                      MyProc.new{}, :curry

    with_int.and_nil do |arity|
      assert_send_type  '(int?) -> Proc',
                        MyProc.new{}, :curry, arity
    end
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      proc{}, :hash
  end

  def test_lambda?
    assert_send_type  '() -> bool',
                      proc{}, :lambda?
    assert_send_type  '() -> bool',
                      lambda{}, :lambda?
  end

  def test_parameters
    assert_send_type  '() -> ::Method::param_types',
                      proc{|a=3, b=4, c, d: 3| }, :parameters
    assert_send_type  '() -> ::Method::param_types',
                      proc{|a, b=3, *c, d: 1, e:, **f, &g| }, :parameters
    assert_send_type  '() -> ::Method::param_types',
                      proc{|**nil| }, :parameters
    assert_send_type  '() -> ::Method::param_types',
                      proc{|*, **, &b| }, :parameters
  end

  def test_source_location
    if_ruby(..."4.1") do
      assert_send_type  '() -> [String, Integer]',
                        proc{}, :source_location
    end
    assert_send_type  '() -> nil',
                      Proc.new(&Kernel.method(:print)), :source_location
  end

  def test_to_proc
    assert_send_type  '() -> ProcInstanceTest::MyProc',
                      MyProc.new{}, :to_proc
  end

  def test_to_s(method: :to_s)
    assert_send_type  '() -> String',
                      proc{}, method
  end
end
