require_relative "test_helper"

class BindingTest < StdlibTest
  target Binding

  def test_clone
    binding.clone
  end

  def test_dup
    binding.dup
  end

  def test_eval
    binding.eval('1', '(eval)', 1)
    binding.eval(ToStr.new)
    binding.eval(ToStr.new, ToStr.new)
    binding.eval(ToStr.new, ToStr.new, ToInt.new)
  end

  def test_local_variable_defined?
    binding.local_variable_defined?(:yes)
    yes = true
    binding.local_variable_defined?('yes')
    binding.local_variable_defined?(ToStr.new('yes'))
  end

  def test_local_variable_get
    foo = 1
    binding.local_variable_get(:foo)
    binding.local_variable_get('foo')
    binding.local_variable_get(ToStr.new('foo'))
  end

  def test_local_variable_set
    binding.local_variable_set(:foo, 1)
    binding.local_variable_set('foo', 1)
    binding.local_variable_set(ToStr.new('foo'), 1)
  end

  def test_local_variables
    foo = 1
    binding.local_variables
  end

  def test_receiver
    binding.receiver
  end

  def test_source_location
    binding.source_location
  end
end
