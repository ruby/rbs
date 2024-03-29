require_relative "test_helper"

class ClassTest < StdlibTest
  target Class

  def test_singleton_new
    Class.new()
    Class.new(Integer)
    Class.new { }
  end

  def test_allocate
    Class.new.allocate
  end

  def test_instance_new
    Class.new.new
  end

  def test_super_class
    Class.new.superclass
    BasicObject.superclass
  end

  def test_subclasses
    Class.new.subclasses
  end

  def test_attached_object
    Class.new.singleton_class.attached_object
  end
end
