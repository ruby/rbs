require "test_helper"

class RBS::EnvironmentWalkerTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  EnvironmentLoader = RBS::EnvironmentLoader
  EnvironmentWalker = RBS::EnvironmentWalker

  def test_sort
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
class Hello
  def foo: (Symbol) -> World
end

class World
  def bar: () -> Hello
end
EOF

      manager.build do |env|
        walker = EnvironmentWalker.new(env: env).only_ancestors!

        walker.each_strongly_connected_component do |component|
          # pp component.map(&:to_s)
        end
      end
    end
  end

  def test_sort_nested_modules
    SignatureManager.new do |manager|
      manager.files[Pathname("foo.rbs")] = <<EOF
module A::Foo
end

module A
  def hello: () -> Foo
end
EOF

      manager.build do |env|
        walker = EnvironmentWalker.new(env: env)

        components = walker.each_strongly_connected_component.to_a
        foo_instance = components.find_index do |component|
          component.any? {|node|
            node.is_a?(EnvironmentWalker::InstanceNode) && node.type_name.to_s == "::A::Foo"
          }
        end
        foo_singleton = components.find_index do |component|
          component.any? {|node|
            node.is_a?(EnvironmentWalker::SingletonNode) && node.type_name.to_s == "::A::Foo"
          }
        end
        a_instance = components.find_index do |component|
          component.any? {|node|
            node.is_a?(EnvironmentWalker::InstanceNode) && node.type_name.to_s == "::A"
          }
        end
        a_singleton = components.find_index do |component|
          component.any? {|node|
            node.is_a?(EnvironmentWalker::SingletonNode) && node.type_name.to_s == "::A"
          }
        end

        # singleton(A) <| A::Foo, singleton(A) <| singleton(A::Foo)
        # A::Foo <| A
        assert_operator a_singleton, :<, foo_instance
        assert_operator a_singleton, :<, foo_singleton
        assert_operator foo_instance, :<, a_instance
      end
    end
  end

  def test_stdlib_strongly_connected_components
    env = Environment.from_loader(EnvironmentLoader.new).resolve_type_names

    walker = EnvironmentWalker.new(env: env.resolve_type_names).only_ancestors!

    walker.each_strongly_connected_component do |component|
      # pp component.map(&:to_s)
    end
  end

  def test_stdlib_tsort
    env = Environment.from_loader(EnvironmentLoader.new).resolve_type_names

    walker = EnvironmentWalker.new(env: env.resolve_type_names).only_ancestors!

    walker.tsort_each do |type_name|
      # pp type_name.to_s
    end
  end

  def test_each_type_name
    env = Environment.from_loader(EnvironmentLoader.new).resolve_type_names

    walker = EnvironmentWalker.new(env: env.resolve_type_names).only_ancestors!

    walker.each_type_name(parse_type("::String")) do |type_name|
      # pp type_name.to_s
    end
  end
end
