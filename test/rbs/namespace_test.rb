require "test_helper"

class RBS::NamespaceTest < Test::Unit::TestCase
  Namespace = RBS::Namespace

  def test_intern_returns_same_instance_for_equal_arguments
    a = Namespace[[:Foo, :Bar], true]
    b = Namespace[[:Foo, :Bar], true]

    assert_same a, b
  end

  def test_intern_distinguishes_absolute_and_relative
    absolute = Namespace[[:Foo], true]
    relative = Namespace[[:Foo], false]

    refute_same absolute, relative
    assert_equal true, absolute.absolute?
    assert_equal false, relative.absolute?
  end

  def test_intern_freezes_internal_path
    ns = Namespace[[:Foo, :Bar], true]

    assert_predicate ns.path, :frozen?
  end

  def test_intern_is_isolated_from_caller_mutation
    path = [:Foo]
    ns = Namespace[path, true]

    path << :Bar

    assert_equal [:Foo], ns.path
    assert_same ns, Namespace[[:Foo], true]
  end

  def test_intern_coerces_absolute_truthiness
    truthy = Namespace[[:Foo], "yes"]
    plain  = Namespace[[:Foo], true]

    assert_same truthy, plain
  end

  def test_intern_equals_uninterned_new
    interned = Namespace[[:Foo, :Bar], true]
    fresh    = Namespace.new(path: [:Foo, :Bar], absolute: true)

    assert_equal interned, fresh
    assert_equal interned.hash, fresh.hash
  end

  def test_empty_and_root_are_interned
    assert_same Namespace.empty, Namespace[[], false]
    assert_same Namespace.root,  Namespace[[], true]
  end
end
