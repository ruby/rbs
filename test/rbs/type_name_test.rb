require "test_helper"

class RBS::TypeNameTest < Test::Unit::TestCase
  Namespace = RBS::Namespace
  TypeName  = RBS::TypeName

  def test_intern_returns_same_instance_for_equal_arguments
    ns = Namespace[[:Foo], true]

    a = TypeName[ns, :Bar]
    b = TypeName[ns, :Bar]

    assert_same a, b
  end

  def test_intern_normalizes_namespace
    fresh_ns     = Namespace.new(path: [:Foo], absolute: true)
    interned_ns  = Namespace[[:Foo], true]

    refute_same fresh_ns, interned_ns

    type_name = TypeName[fresh_ns, :Bar]

    assert_same interned_ns, type_name.namespace
  end

  def test_intern_distinguishes_name
    ns = Namespace[[:Foo], true]
    bar  = TypeName[ns, :Bar]
    baz  = TypeName[ns, :Baz]

    refute_same bar, baz
  end

  def test_intern_equals_uninterned_new
    ns = Namespace.new(path: [:Foo], absolute: true)

    interned = TypeName[ns, :Bar]
    fresh    = TypeName.new(namespace: ns, name: :Bar)

    assert_equal interned, fresh
    assert_equal interned.hash, fresh.hash
  end

  def test_intern_preserves_kind_detection
    ns = Namespace.root
    klass     = TypeName[ns, :Foo]
    aliased   = TypeName[ns, :foo]
    interface = TypeName[ns, :_Foo]

    assert_equal :class,     klass.kind
    assert_equal :alias,     aliased.kind
    assert_equal :interface, interface.kind
  end
end
