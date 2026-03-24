require_relative "test_helper"

class ClassSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Class)"

  def test_allocate
    assert_send_type "() -> untyped",
                     Class, :new
  end
end

class ClassInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Class"

  Subclass = Class.new

  def test_allocate
    assert_send_type "() -> untyped",
                     Subclass, :new
  end

  def test_new
    assert_send_type  '() -> untyped',
                      Subclass, :new

    big_init = Class.new do
      def initialize(*a, **k, &b) = nil
    end

    assert_send_type  '(*untyped, **untyped) { (?) -> untyped } -> untyped',
                      big_init, :new, 1, 2, a: 3, 'b' => 4 do |x, y, &z| 3 end
  end

  def test_initialize
    assert_send_type "() -> void",
                     Class.allocate, :initialize

    assert_send_type "() { (Class) [self: Class] -> void } -> void",
                     Class.allocate, :initialize do end

    assert_send_type "(Class) -> void",
                     Class.allocate, :initialize, String

    assert_send_type "(Class) { (Class) [self: Class] -> void } -> void",
                     Class.allocate, :initialize, String do end
  end

  def test_superclass
    assert_send_type "() -> Class",
                     String, :superclass
    assert_send_type "() -> nil",
                     BasicObject, :superclass
  end

  def test_subclasses
    assert_send_type "() -> Array[Class]",
                     Module, :subclasses
  end

  def test_attached_object
    assert_send_type "() -> singleton(String)",
                     String.singleton_class, :attached_object
  end

  def test_inherited
    assert_send_type "(Class) -> void",
                     Subclass, :inherited, String
  end
end
