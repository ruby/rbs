require_relative "test_helper"

class BindingInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'Binding'

  def test_clone
    assert_send_type  '() -> Binding',
                      binding, :clone
  end

  def test_dup
    assert_send_type  '() -> Binding',
                      binding, :dup
  end

  def test_eval
    with_string '123' do |src|
      assert_send_type  '(string) -> untyped',
                        binding, :eval, src

      with_string 'my file' do |filename|
        assert_send_type  '(string, string) -> untyped',
                          binding, :eval, src, filename

        with_int 3 do |lineno|
          assert_send_type  '(string, string, int) -> untyped',
                            binding, :eval, src, filename, lineno
        end
      end
    end
  end

  def test_local_variable_defined?
    with_interned :hello do |varname|
      assert_send_type  '(interned) -> bool',
                        binding, :local_variable_defined?, varname
    end
  end

  def test_local_variable_get
    with_interned :varname do |varname|
      assert_send_type  '(interned) -> untyped',
                        binding, :local_variable_get, varname
    end
  end

  def test_local_variable_set
    with_interned :hello do |varname|
      assert_send_type  '(interned, Rational) -> Rational',
                        binding, :local_variable_set, varname, 1r
    end
  end

  def test_local_variables
    foo = bar = baz = 3 # make a few local variables

    assert_send_type  '() -> Array[Symbol]',
                      binding, :local_variables
  end

  def test_receiver
    assert_send_type  '() -> untyped',
                      binding, :receiver
  end

  def test_source_location
    assert_send_type  '() -> [String, Integer]',
                      binding, :source_location
  end
end
