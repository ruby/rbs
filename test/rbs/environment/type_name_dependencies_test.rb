require "test_helper"

class RBS::Environment::TypeNameDependenciesTest < Test::Unit::TestCase
  include TestHelper

  Environment = RBS::Environment
  TypeNameDependencies = RBS::Environment::TypeNameDependencies

  # The sources before the type name resolution
  attr_reader :sources

  # The resolved environment
  attr_reader :env

  attr_reader :dependencies

  def setup
    super
    @sources = {}
    @env = Environment.new
    @dependencies = TypeNameDependencies.new
  end

  def parse(path, content)
    path = Pathname(path)
    buffer = RBS::Buffer.new(name: path, content: content)

    if path.extname == ".rb"
      prism = Prism.parse(content)
      result = RBS::InlineParser.parse(buffer, prism)
      RBS::Source::Ruby.new(buffer, prism, result.declarations, result.diagnostics)
    else
      _, dirs, decls = RBS::Parser.parse_signature(buffer)
      RBS::Source::RBS.new(buffer, dirs, decls)
    end
  end

  # Updates the environment with the files, a hash from the path to the content or `nil` to delete it
  #
  # Only the files and the sources affected by the changes are resolved, and the result is the same as resolving all of
  # the sources. Returns the paths of the affected sources.
  #
  def update(files)
    paths = Set.new(files.keys.map { Pathname(_1) })

    files.each do |path, content|
      if content
        sources[Pathname(path)] = parse(path, content)
      else
        sources.delete(Pathname(path))
      end
    end

    new_env = env.unload(paths)
    paths.each do |path|
      if source = sources[path]
        new_env.add_source(source)
      end
    end

    affected_paths = dependencies.affected_paths(new_env, except: paths)

    new_env = new_env.unload(affected_paths)
    affected_paths.each { new_env.add_source(sources.fetch(_1)) }

    only = Set[].compare_by_identity
    (paths + affected_paths).each do |path|
      if source = sources[path]
        only.merge(source.declarations)
      end
    end

    @env = new_env.resolve_type_names(only: only, dependencies: dependencies)

    fresh_env = Environment.new
    sources.each_value { fresh_env.add_source(_1) }
    fresh_dependencies = TypeNameDependencies.new
    fresh_env = fresh_env.resolve_type_names(dependencies: fresh_dependencies)

    assert_equal declarations(fresh_env), declarations(env)
    assert_equal queries(fresh_dependencies), queries(dependencies)
    assert_equal fresh_dependencies.wildcards, dependencies.wildcards
    assert_equal fresh_dependencies.aliases, dependencies.aliases

    affected_paths
  end

  def declarations(env)
    env.sources.to_h do |source|
      case source
      when RBS::Source::RBS
        [source.buffer.name, source.declarations]
      when RBS::Source::Ruby
        # The declarations of Ruby sources are compared by their fingerprints
        [source.buffer.name, source.declarations.map(&:type_fingerprint)]
      end
    end
  end

  # The type names resolved for each source, with the contexts compared by `==`
  def queries(dependencies = self.dependencies)
    dependencies.queries.transform_values do |contexts|
      contexts.each_with_object({}) do |(context, results), hash|
        (hash[context] ||= {}).update(results)
      end
    end
  end

  def source(path)
    env.sources.find { _1.buffer.name == Pathname(path) }
  end

  def method_type(type_name, method_name)
    env.class_decls.fetch(type_name(type_name)).each_decl do |decl|
      decl.members.each do |member|
        if member.is_a?(RBS::AST::Members::MethodDefinition) && member.name == method_name
          return member.overloads[0].method_type.to_s
        end
      end
    end

    nil
  end

  def test_resolve_type_names
    update(
      "a.rbs" => <<~RBS,
        module M
          class A
            def foo: () -> B
          end
        end
      RBS
      "b.rbs" => <<~RBS,
        class B
        end
      RBS
      "c.rbs" => <<~RBS,
        # resolve-type-names: false

        class C
          def foo: () -> B
        end
      RBS
      "d.rbs" => <<~RBS
        use M::*

        type d = A
      RBS
    )

    assert_equal "() -> ::B", method_type("::M::A", :foo)

    assert_equal(
      {
        # The type name is resolved in the context of the class
        Pathname("a.rbs") => { [[nil, type_name("::M")], type_name("::M::A")] => { type_name("B") => type_name("::B") } },
        # The type name the `use` directive gives is resolved
        Pathname("d.rbs") => { nil => { type_name("::M::A") => type_name("::M::A") } }
      },
      queries
    )

    # No type names to resolve
    refute_operator dependencies.queries, :key?, Pathname("b.rbs")
    refute_operator dependencies.queries, :key?, Pathname("c.rbs")

    assert_equal(
      { Pathname("d.rbs") => { RBS::Namespace.parse("::M::") => Set[type_name("::M::A")] } },
      dependencies.wildcards
    )
    assert_empty dependencies.aliases
  end

  def test_resolve_type_names__aliases
    update(
      "a.rbs" => <<~RBS,
        module M
          class Y = E

          module N = ::M
        end

        class E
        end
      RBS
      "b.rb" => <<~RUBY
        module M
          Z = E #: class-alias
        end
      RUBY
    )

    # The names of the modules are the ones before the resolution
    assert_equal type_name("::E"), env.class_alias_decls.fetch(type_name("::M::Y")).decl.old_name
    assert_equal(
      {
        Pathname("a.rbs") => {
          type_name("::M::Y") => [type_name("E"), [nil, type_name("::M")]],
          type_name("::M::N") => [type_name("::M"), [nil, type_name("::M")]]
        },
        Pathname("b.rb") => {
          type_name("::M::Z") => [type_name("E"), [nil, type_name("::M")]]
        }
      },
      dependencies.aliases
    )
  end

  def test_resolve_type_names__only
    update(
      "a.rbs" => <<~RBS,
        class A
          def foo: () -> String
        end
      RBS
      "b.rbs" => <<~RBS,
        class B
          def foo: () -> A
        end
      RBS
      "string.rbs" => <<~RBS
        class String
        end
      RBS
    )

    a_source = source("a.rbs")
    a_queries = dependencies.queries.fetch(Pathname("a.rbs"))
    assert_equal({ [nil, type_name("::A")] => { type_name("String") => type_name("::String") } }, queries.fetch(Pathname("a.rbs")))

    affected_paths = update(
      "b.rbs" => nil,
      "c.rbs" => <<~RBS
        class C
          def foo: () -> A
        end
      RBS
    )
    assert_empty affected_paths

    # The source that is not resolved is added as it is, and keeps its dependencies
    assert_same a_source, source("a.rbs")
    assert_same a_queries, dependencies.queries.fetch(Pathname("a.rbs"))

    # The dependencies of the removed source are deleted
    refute_operator dependencies.queries, :key?, Pathname("b.rbs")
    assert_equal({ [nil, type_name("::C")] => { type_name("A") => type_name("::A") } }, queries.fetch(Pathname("c.rbs")))
  end

  def test_resolve_type_names__only_part_of_source
    source = parse("a.rbs", <<~RBS)
      class A
        def foo: () -> Foo
      end

      class B
        def bar: () -> Bar
      end
    RBS

    env = Environment.new
    env.add_source(source)

    a, b = source.declarations

    a_queries = { [nil, type_name("::A")] => { type_name("Foo") => type_name("Foo") } }
    b_queries = { [nil, type_name("::B")] => { type_name("Bar") => type_name("Bar") } }

    # The type names of the declarations are added to the ones the source has
    dependencies = TypeNameDependencies.new
    env.resolve_type_names(only: Set[a].compare_by_identity, dependencies: dependencies)
    assert_equal a_queries, queries(dependencies).fetch(Pathname("a.rbs"))

    copy = dependencies.dup
    recorded = dependencies.queries.fetch(Pathname("a.rbs"))

    env.resolve_type_names(only: Set[b].compare_by_identity, dependencies: dependencies)
    assert_equal a_queries.merge(b_queries), queries(dependencies).fetch(Pathname("a.rbs"))

    # The hash shared with the copy is not updated
    assert_same recorded, copy.queries.fetch(Pathname("a.rbs"))
    assert_equal a_queries, queries(copy).fetch(Pathname("a.rbs"))

    # All of the declarations replace the type names
    env.resolve_type_names(only: Set[b, a].compare_by_identity, dependencies: copy)
    assert_equal queries(dependencies), queries(copy)

    # No declaration keeps the type names
    recorded = dependencies.queries.fetch(Pathname("a.rbs"))
    env.resolve_type_names(only: Set[].compare_by_identity, dependencies: dependencies)
    assert_same recorded, dependencies.queries.fetch(Pathname("a.rbs"))
  end

  def test_resolve_type_names__only_part_of_source__aliases
    source = parse("a.rbs", <<~RBS)
      class Y = A

      module M
        class Z = A
      end

      class A
      end
    RBS

    env = Environment.new
    env.add_source(source)

    y, m, _ = source.declarations

    # The aliases of the declarations are added to the ones the source has
    dependencies = TypeNameDependencies.new
    env.resolve_type_names(only: Set[y].compare_by_identity, dependencies: dependencies)
    assert_equal({ type_name("::Y") => [type_name("A"), nil] }, dependencies.aliases.fetch(Pathname("a.rbs")))

    copy = dependencies.dup
    aliases = dependencies.aliases.fetch(Pathname("a.rbs"))

    env.resolve_type_names(only: Set[m].compare_by_identity, dependencies: dependencies)
    assert_equal(
      {
        type_name("::Y") => [type_name("A"), nil],
        type_name("::M::Z") => [type_name("A"), [nil, type_name("::M")]]
      },
      dependencies.aliases.fetch(Pathname("a.rbs"))
    )

    # The hash shared with the copy is not updated
    assert_same aliases, copy.aliases.fetch(Pathname("a.rbs"))
    assert_equal [type_name("::Y")], aliases.keys
  end

  def test_affected_paths__type_name_in_outer_module
    update(
      "a.rbs" => <<~RBS,
        module M
          class A
            def foo: () -> B
          end
        end
      RBS
      "b.rbs" => <<~RBS
        class B
        end
      RBS
    )
    assert_equal "() -> ::B", method_type("::M::A", :foo)

    affected_paths = update("m_b.rbs" => <<~RBS)
      module M
        class B
        end
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::M::B", method_type("::M::A", :foo)

    affected_paths = update("m_b.rbs" => nil)
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::B", method_type("::M::A", :foo)
  end

  def test_affected_paths__unresolved_type_name
    update("a.rbs" => <<~RBS)
      class A
        def foo: () -> Foo
      end
    RBS
    assert_equal "() -> Foo", method_type("::A", :foo)

    affected_paths = update("foo.rbs" => <<~RBS)
      class Foo
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::Foo", method_type("::A", :foo)

    affected_paths = update("foo.rbs" => nil)
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> Foo", method_type("::A", :foo)
  end

  def test_affected_paths__unaffected
    update(
      "a.rbs" => <<~RBS,
        module M
          class A
            def foo: () -> String
          end
        end
      RBS
      "string.rbs" => <<~RBS
        class String
        end
      RBS
    )

    # `String` in `::M::A` is resolved to `::String` with `::N::String` and `::Integer`
    affected_paths = update("b.rbs" => <<~RBS)
      module N
        class String
        end
      end

      class Integer
      end
    RBS
    assert_empty affected_paths

    # The declarations of an existing class don't change the type names
    affected_paths = update("string.rbs" => <<~RBS)
      class String
        def size: () -> Integer
      end
    RBS
    assert_empty affected_paths
  end

  def test_affected_paths__same_type_name_in_same_context
    # Both sources resolve `B` in the same context
    update(
      "a1.rbs" => <<~RBS,
        module M
          type a1 = B
        end
      RBS
      "a2.rbs" => <<~RBS,
        module M
          type a2 = B
        end
      RBS
      "b.rbs" => <<~RBS
        class B
        end
      RBS
    )

    affected_paths = update("m_b.rbs" => <<~RBS)
      module M
        class B
        end
      end
    RBS
    assert_equal Set[Pathname("a1.rbs"), Pathname("a2.rbs")], affected_paths
  end

  def test_affected_paths__module_of_alias
    update(
      "alias.rbs" => <<~RBS,
        class Y = ::D
      RBS
      "d.rbs" => <<~RBS,
        class D
        end
      RBS
      "a.rbs" => <<~RBS
        class A
          def foo: () -> Y
        end
      RBS
    )
    assert_equal "() -> ::D", method_type("::A", :foo)

    # The alias cannot be normalized. The declaration of the alias has `::D` whether it can be resolved or not.
    affected_paths = update("d.rbs" => nil)
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> Y", method_type("::A", :foo)

    affected_paths = update("d.rbs" => <<~RBS)
      class D
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::D", method_type("::A", :foo)
  end

  def test_affected_paths__alias_of_another_module
    update(
      "alias.rbs" => <<~RBS,
        class Y = ::D
      RBS
      "d.rbs" => <<~RBS,
        class D
        end

        class E
        end
      RBS
      "a.rbs" => <<~RBS
        class A
          def foo: () -> Y
        end
      RBS
    )
    assert_equal "() -> ::D", method_type("::A", :foo)

    # The type names exist in both environments, and the alias is declared differently
    affected_paths = update("alias.rbs" => <<~RBS)
      class Y = ::E
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::E", method_type("::A", :foo)

    # The alias is declared in the same way
    affected_paths = update("alias.rbs" => <<~RBS)
      # The comment is added
      class Y = ::E
    RBS
    assert_empty affected_paths
  end

  def test_affected_paths__class_replaced_with_alias
    update(
      "x.rbs" => <<~RBS,
        class X
        end

        class D
        end
      RBS
      "a.rbs" => <<~RBS
        class A
          def foo: () -> X
        end
      RBS
    )
    assert_equal "() -> ::X", method_type("::A", :foo)

    # `::X` exists in both environments, as a class and as a class alias
    affected_paths = update("x.rbs" => <<~RBS)
      class X = ::D

      class D
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::D", method_type("::A", :foo)
  end

  def test_affected_paths__alias_with_relative_name
    update(
      "alias.rbs" => <<~RBS,
        class Y = E
      RBS
      "e.rbs" => <<~RBS,
        class E
        end
      RBS
      "a.rbs" => <<~RBS
        class A
          def foo: () -> Y
        end
      RBS
    )
    assert_equal "() -> ::E", method_type("::A", :foo)

    # `Y` is resolved to `::E` through the alias as it is written in the new source
    affected_paths = update("alias.rbs" => <<~RBS)
      # The comment is added
      class Y = E
    RBS
    assert_empty affected_paths

    affected_paths = update("alias.rbs" => <<~RBS)
      class Y = ::E
    RBS
    assert_empty affected_paths
  end

  def test_affected_paths__alias_resolved_before_reference
    update(
      "alias.rbs" => <<~RBS,
        module M
          class Y = E
        end
      RBS
      "e.rbs" => <<~RBS
        class E
        end
      RBS
    )

    # `alias.rbs` is resolved already, and the alias is `::E` in the environment
    update("a.rbs" => <<~RBS)
      class A
        def foo: () -> M::Y
      end
    RBS
    assert_equal "() -> ::E", method_type("::A", :foo)

    # The resolver normalizes the alias with `E` as it is written, not with `::E` in the environment
    affected_paths = update("m_e.rbs" => <<~RBS)
      module M
        class E
        end
      end
    RBS
    assert_equal Set[Pathname("alias.rbs"), Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::M::E", method_type("::A", :foo)
  end

  def test_affected_paths__alias_of_alias
    update(
      "y.rbs" => <<~RBS,
        module M
          class Y = E
        end
      RBS
      "e.rbs" => <<~RBS
        class E
        end
      RBS
    )
    update("z.rbs" => <<~RBS)
      class Z = M::Y
    RBS
    update("a.rbs" => <<~RBS)
      class A
        def foo: () -> Z
      end
    RBS
    assert_equal "() -> ::E", method_type("::A", :foo)

    affected_paths = update("m_e.rbs" => <<~RBS)
      module M
        class E
        end
      end
    RBS
    assert_equal Set[Pathname("y.rbs"), Pathname("z.rbs"), Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::M::E", method_type("::A", :foo)
  end

  def test_affected_paths__alias_moved_to_another_source
    update(
      "alias1.rbs" => <<~RBS,
        class Y = D
      RBS
      "alias2.rbs" => <<~RBS,
        class Z = D
      RBS
      "d.rbs" => <<~RBS,
        class D
        end

        class E
        end
      RBS
      "a.rbs" => <<~RBS
        class A
          def foo: () -> Y
        end
      RBS
    )

    affected_paths = update(
      "alias1.rbs" => "",
      "alias2.rbs" => <<~RBS
        class Z = D

        class Y = E
      RBS
    )
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::E", method_type("::A", :foo)
  end

  def test_affected_paths__alias_in_inner_module
    update(
      "a.rbs" => <<~RBS,
        module M
          class A
            def foo: () -> B
          end
        end
      RBS
      "b.rbs" => <<~RBS
        class B
        end
      RBS
    )
    assert_equal "() -> ::B", method_type("::M::A", :foo)

    # `B` is resolved to `::B` through the alias
    affected_paths = update("m_b.rbs" => <<~RBS)
      module M
        class B = ::B
      end
    RBS
    assert_empty affected_paths
    assert_equal "() -> ::B", method_type("::M::A", :foo)
  end

  def test_affected_paths__absolute_type_name
    update("a.rbs" => <<~RBS)
      class A
        def foo: () -> ::Foo
      end
    RBS

    # The declaration has `::Foo` whether it can be resolved or not
    affected_paths = update("foo.rbs" => <<~RBS)
      class Foo
      end
    RBS
    assert_empty affected_paths
  end

  def test_affected_paths__source_without_declarations
    update(
      "a.rbs" => <<~RBS,
        class A
          def foo: () -> Foo
        end
      RBS
    )
    assert_operator dependencies.queries, :key?, Pathname("a.rbs")

    # The source has no declaration to give to `only`, and its dependencies are deleted
    update("a.rbs" => "# Nothing here\n")
    refute_operator dependencies.queries, :key?, Pathname("a.rbs")

    affected_paths = update("foo.rbs" => <<~RBS)
      class Foo
      end
    RBS
    assert_empty affected_paths
  end

  def test_affected_paths__wildcard_use
    update(
      "foo.rbs" => <<~RBS,
        module Foo
          class Baz
          end
        end
      RBS
      "a.rbs" => <<~RBS
        use Foo::*

        class A
          def foo: () -> Bar
        end
      RBS
    )
    assert_equal "() -> Bar", method_type("::A", :foo)

    # `Bar` is not resolved to `::Foo::Bar` by the resolver, but it is a type name under the namespace of the directive
    affected_paths = update("bar.rbs" => <<~RBS)
      module Foo
        class Bar
        end
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> ::Foo::Bar", method_type("::A", :foo)

    affected_paths = update("bar.rbs" => nil)
    assert_equal Set[Pathname("a.rbs")], affected_paths
    assert_equal "() -> Bar", method_type("::A", :foo)

    # The source is affected by a type name under the namespace that it doesn't have
    affected_paths = update("qux.rbs" => <<~RBS)
      module Foo
        class Qux
        end
      end
    RBS
    assert_equal Set[Pathname("a.rbs")], affected_paths
  end

  def test_affected_paths__ruby
    update(
      "a.rb" => <<~RUBY,
        module M
          class A
            def foo #: B
            end
          end
        end
      RUBY
      "b.rbs" => <<~RBS
        class B
        end
      RBS
    )

    affected_paths = update("m_b.rbs" => <<~RBS)
      module M
        class B
        end
      end
    RBS
    assert_equal Set[Pathname("a.rb")], affected_paths
    assert_includes declarations(env).fetch(Pathname("a.rb")).inspect, "::M::B"
  end

  def test_affected_paths__except
    update(
      "a.rbs" => <<~RBS,
        class A
          def foo: () -> Foo
        end
      RBS
      "b.rbs" => <<~RBS
        class B
          def foo: () -> Foo
        end
      RBS
    )

    new_env = env.unload(Set[Pathname("b.rbs")])
    new_env.add_source(parse("b.rbs", <<~RBS))
      class B
        def foo: () -> Foo
      end

      class Foo
      end
    RBS

    # `b.rbs` is updated, and has the dependencies of the source before the update
    assert_equal Set[Pathname("a.rbs")], dependencies.affected_paths(new_env, except: Set[Pathname("b.rbs")])
    assert_equal Set[Pathname("a.rbs"), Pathname("b.rbs")], dependencies.affected_paths(new_env, except: Set[])
  end

  def test_copy
    update("a.rbs" => <<~RBS)
      class A
        def foo: () -> Foo
      end
    RBS

    copy = dependencies.dup

    update("b.rbs" => <<~RBS)
      class B
        def foo: () -> Bar
      end
    RBS

    assert_equal [Pathname("a.rbs")], copy.queries.keys
    assert_equal [Pathname("a.rbs"), Pathname("b.rbs")], dependencies.queries.keys
    assert_same copy.queries.fetch(Pathname("a.rbs")), dependencies.queries.fetch(Pathname("a.rbs"))
  end
end
