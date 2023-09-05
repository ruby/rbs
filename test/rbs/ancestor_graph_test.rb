require "test_helper"

class RBS::AncestorGraphTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  AncestorGraph = RBS::AncestorGraph

  def InstanceNode(name)
    if name.is_a?(String)
      name = TypeName(name)
    end

    AncestorGraph::InstanceNode.new(type_name: name)
  end

  def SingletonNode(name)
    if name.is_a?(String)
      name = TypeName(name)
    end

    AncestorGraph::SingletonNode.new(type_name: name)
  end

  def test_graph
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class A
end

class B < A
  include M
  include _I
end

class C < B
end

module M
end

interface _I
end

interface _J
  include _I
end
EOF

      manager.build do |env|
        graph = AncestorGraph.new(env: env)

        assert_equal(
          Set[InstanceNode("::Object"), InstanceNode("::Kernel"), InstanceNode("::BasicObject")],
          graph.each_ancestor(InstanceNode("::A")).to_set
        )
        assert_equal(
          Set[InstanceNode("::B"), InstanceNode("::C")],
          graph.each_descendant(InstanceNode("::A")).to_set
        )

        assert_equal(
          Set[InstanceNode("::M"), InstanceNode("::_I"), InstanceNode("::A"), InstanceNode("::Object"), InstanceNode("::Kernel"), InstanceNode("::BasicObject")],
          graph.each_ancestor(InstanceNode("::B")).to_set
        )
        assert_equal(
          Set[InstanceNode("::C")],
          graph.each_descendant(InstanceNode("::B")).to_set
        )

        assert_equal(
          Set[InstanceNode("::B"), InstanceNode("::M"), InstanceNode("::_I"), InstanceNode("::A"), InstanceNode("::Object"), InstanceNode("::Kernel"), InstanceNode("::BasicObject")],
          graph.each_ancestor(InstanceNode("::C")).to_set
        )
        assert_equal(
          Set[],
          graph.each_descendant(InstanceNode("::C")).to_set
        )

        assert_equal(
          Set[InstanceNode("::Object"), InstanceNode("::Kernel"), InstanceNode("::BasicObject")],
          graph.each_ancestor(InstanceNode("::M")).to_set
        )
        assert_equal(
          Set[InstanceNode("::B"), InstanceNode("::C"), SingletonNode("::B"), SingletonNode("::C")],
          graph.each_descendant(InstanceNode("::M")).to_set
        )

        assert_equal(
          Set[],
          graph.each_ancestor(InstanceNode("::_I")).to_set
        )
        assert_equal(
          Set[InstanceNode("::B"), InstanceNode("::C"), InstanceNode("::_J")],
          graph.each_descendant(InstanceNode("::_I")).to_set
        )

        assert_equal(
          Set[InstanceNode("::_I")],
          graph.each_ancestor(InstanceNode("::_J")).to_set
        )
        assert_equal(
          Set[],
          graph.each_descendant(InstanceNode("::_J")).to_set
        )
      end
    end
  end
end
