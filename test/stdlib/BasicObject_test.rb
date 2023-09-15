require_relative "test_helper"


class BasicObjectSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'BasicObject'

  BOBJ = BasicObject.new

  # Satisfy the testing harness framework.
  def BOBJ.class; BasicObject end
  def BOBJ.inspect; ::Kernel.instance_method(:inspect).bind_call(self) end
  def BOBJ.raise(...) ::Kernel.raise(...) end

  def test_not
    assert_send_type  '() -> bool',
                      BOBJ, :!
  end

  def test_not_equal
    assert_send_type  '(untyped) -> bool',
                      BOBJ, :!=, 34
  end

  def test_eq
    assert_send_type  '(untyped) -> bool',
                      BOBJ, :==, 34
  end

  def test___id__
    assert_send_type  '() -> Integer',
                      BOBJ, :__id__
  end

  def test___send__
    with_interned :__send__ do |name|
      assert_send_type  '(interned, *untyped, **untyped) -> untyped',
                        BOBJ, :__send__, name, :__id__
      assert_send_type  '(interned, *untyped, **untyped) { (*untyped, **untyped) -> untyped} -> untyped',
                        BOBJ, :__send__, name, :instance_exec do _1 end
    end
  end

  def test_equal?
    assert_send_type  '(untyped) -> bool',
                      BOBJ, :equal?, 34
  end


  def test_instance_eval
    with_string '__id__' do |code|
      assert_send_type  '(string) -> untyped',
                        BOBJ, :instance_eval, code
      with_string 'some file' do |filename|
        assert_send_type  '(string, string) -> untyped',
                          BOBJ, :instance_eval, code, filename
        with_int 123 do |lineno|
          assert_send_type  '(string, string, int) -> untyped',
                            BOBJ, :instance_eval, code, filename, lineno
        end
      end
    end

    assert_send_type  '() { (self) [self: self] -> Integer } -> Integer',
                      BOBJ, :instance_eval do _1.__id__ end
  end

  def test_instance_exec
    assert_send_type  '(*String) { (*String) [self: self] -> Integer } -> Integer',
                      BOBJ, :instance_exec, '1', '2' do |*x| x.join.to_i end
  end
end
