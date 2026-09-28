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

  def test_kind_reads_only_the_leading_ascii_character
    ns = Namespace.root

    # The parser never hands `kind` a name that opens outside ASCII, because a
    # type name has to start with an ASCII character to be one. A name built by
    # hand still can, and `kind` reads nothing there -- no Unicode table on this
    # side, which is the whole point of that restriction.
    assert_equal :class, TypeName[ns, :Foo日本語].kind
    assert_equal :alias, TypeName[ns, :foo日本語].kind
    assert_equal :interface, TypeName[ns, :_Foo日本語].kind
    assert_equal :class, TypeName[ns, :日本語].kind
  end
end
