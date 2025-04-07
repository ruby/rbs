require "test_helper"
require "stringio"
require "rbs/cli"

class RBS::CliTest < Test::Unit::TestCase
  include TestHelper

  CLI = RBS::CLI

  def stdout
    @stdout ||= StringIO.new
  end

  def stderr
    @stderr ||= StringIO.new
  end

  # Run `rbs collection` with fresh bundler environment
  #
  # You need this method to test `rbs collection` features.
  # `rbs collection` loads gems from Bundler context, so re-using the current Bundler context (used to develop rbs gem) causes issues.
  #
  # - If `bundler: true` is given, it runs `rbs collection` command with `bundle exec`
  # - If `bundler: false` is given, it runs `rbs collection` command without `bundle exec`
  #
  # We cannot run tests that uses this method in ruby CI.
  #
  def run_rbs_collection(*commands, bundler:)
    stdout, stderr, status =
      Bundler.with_unbundled_env do
        bundle_exec = []
        bundle_exec = ["bundle", "exec"] if bundler

        rbs_path = Pathname("#{__dir__}/../../lib").cleanpath.to_s
        if rblib = ENV["RUBYLIB"]
          rbs_path << (":" + rblib)
        end

        Open3.capture3({ "RUBYLIB" => rbs_path }, *bundle_exec, "#{__dir__}/../../exe/rbs", "--log-level=debug", "collection", *commands, chdir: Dir.pwd)
      end

    if block_given?
      yield status
    else
      assert_predicate status, :success?, stderr
    end

    [stdout, stderr]
  end

  def bundle_install(*gems)
    stdout, stderr, status =
      Bundler.with_unbundled_env do
        gems << 'prism' unless gems.include?('prism')
        
        gems = gems.map do |gem|
          if gem == :gemspec
            "gemspec"
          else
            if gem.is_a?(Array)
              "gem #{gem.map(&:inspect).join(", ")}"
            else
              "gem '#{gem}'"
            end
          end
        end

        (Pathname(Dir.pwd) + "Gemfile").write(<<~RUBY)
          source "https://rubygems.org"

          #{gems.join("\n")}
        RUBY

        Open3.capture3("bundle", "install", chdir: Dir.pwd)
      end

    assert_predicate status, :success?, stderr

    [stdout, stderr]
  end

  def with_cli
    orig_logger_output = RBS.logger_output
    RBS.logger_output = stdout
    yield CLI.new(stdout: stdout, stderr: stderr)
  ensure
    RBS.logger_output = orig_logger_output
    @stdout = nil
    @stderr = nil
  end

  def test_ast
    with_cli do |cli|
      cli.run(%w(ast))

      # Outputs a JSON
      JSON.parse stdout.string
    end
  end

  def test_no_stdlib_option
    with_cli do |cli|
      cli.run(%w(--no-stdlib ast))

      assert_equal '[]', stdout.string
    end
  end

  def test_list
    with_cli do |cli|
      cli.run(%w(-r pathname list))
      assert_match %r{^::Pathname \(class\)$}, stdout.string
      assert_match %r{^::Kernel \(module\)$}, stdout.string
      assert_match %r{^::_Each \(interface\)$}, stdout.string
    end

    with_cli do |cli|
      cli.run(%w(-r pathname list --class))
      assert_match %r{^::Pathname \(class\)$}, stdout.string
      refute_match %r{^::Kernel \(module\)$}, stdout.string
      refute_match %r{^::_Each \(interface\)$}, stdout.string
    end

    with_cli do |cli|
      cli.run(%w(-r pathname list --module))
      refute_match %r{^::Pathname \(class\)$}, stdout.string
      assert_match %r{^::Kernel \(module\)$}, stdout.string
      refute_match %r{^::_Each \(interface\)$}, stdout.string
    end

    with_cli do |cli|
      cli.run(%w(-r pathname list --interface))
      refute_match %r{^::Pathname \(class\)$}, stdout.string
      refute_match %r{^::Kernel \(module\)$}, stdout.string
      assert_match %r{^::_Each \(interface\)$}, stdout.string
    end

    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('alias.rbs').write(<<~RBS)
        class Foo = String

        module Bar = Kernel
      RBS

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(-I. list))

          assert_match %r{^::Foo \(class alias\)$}, stdout.string
          assert_match %r{^::Bar \(module alias\)$}, stdout.string
        end
      end
    end
  end

  def test_ancestors
    with_cli do |cli|
      cli.run(%w(ancestors ::Set))
      assert_equal <<-EOF, stdout.string
::Set[A]
::Enumerable[A]
::Object
::Kernel
::BasicObject
      EOF
    end

    with_cli do |cli|
      cli.run(%w(ancestors --instance ::Set))
      assert_equal <<-EOF, stdout.string
::Set[A]
::Enumerable[A]
::Object
::Kernel
::BasicObject
      EOF
    end

    with_cli do |cli|
      cli.run(%w(ancestors --singleton ::Set))
      assert_equal <<-EOF, stdout.string
singleton(::Set)
singleton(::Object)
singleton(::BasicObject)
::Class
::Module
::Object
::Kernel
::BasicObject
      EOF
    end

    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('alias.rbs').write(<<~RBS)
        class Foo = String

        class Bar
        end
      RBS

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(-I. ancestors ::Foo))

          assert_equal <<~EOF, stdout.string
            ::String
            ::Comparable
            ::Object
            ::Kernel
            ::BasicObject
          EOF
        end
      end
    end
  end

  def test_methods
    with_cli do |cli|
      cli.run(%w(methods ::Set))
      cli.run(%w(methods --instance ::Set))
      cli.run(%w(methods --singleton ::Set))
    end

    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('alias.rbs').write(<<~RBS)
        class Foo = String

        module Bar = Kernel
      RBS

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(-I. methods ::Foo))
          assert_match %r{^puts \(private\)$}, stdout.string
        end

        with_cli do |cli|
          cli.run(%w(-I. methods --singleton ::Bar))
          assert_match %r{^puts \(public\)$}, stdout.string
        end
      end
    end
  end

  def test_method
    with_cli do |cli|
      cli.run(%w(method ::Object yield_self))
      assert_includes stdout.string, '::Object#yield_self'
      assert_includes stdout.string, 'defined_in: ::Kernel'
      assert_includes stdout.string, 'implementation: ::Kernel'
      assert_includes stdout.string, 'accessibility: public'
      assert_includes stdout.string, 'types:'
      assert_includes stdout.string, '  () -> ::Enumerator[self, untyped]'
      assert_includes stdout.string, 'core/kernel.rbs'
      assert_includes stdout.string, '| [T] () { (self) -> T } -> T'
      assert_includes stdout.string, 'core/kernel.rbs'
    end

    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('alias.rbs').write(<<~RBS)
        class Foo = String

        module Bar = Kernel
      RBS

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(-I. method ::Foo puts))
          assert_match %r{^::Foo#puts$}, stdout.string
        end

        with_cli do |cli|
          cli.run(%w(-I. method --singleton ::Bar puts))
          assert_match %r{^::Bar\.puts$}, stdout.string
        end
      end
    end

  end

  def test_validate
    with_cli do |cli|
      cli.run(%w(--log-level=info validate))
      assert_match(/Validating/, stdout.string)
    end

    with_cli do |cli|
      cli.run(%w(--log-level=warn validate --silent))
      assert_match(/`--silent` option is deprecated because it's silent by default\. You can use --log-level option of rbs command to display more information\.$/, stdout.string)
    end
  end

  def test_validate_no_type_found_error_1
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Hello::World
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:1:0...2:3: Could not find ::Hello (RBS::NoTypeFoundError)"
      end
    end
  end

  def test_validate_no_type_found_error_2
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        Hello::World: Integer
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:1:0...1:21: Could not find ::Hello (RBS::NoTypeFoundError)"
      end
    end
  end

  def test_validate_no_type_found_error_3
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        type Hello::t = Integer
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:1:0...1:23: Could not find ::Hello (RBS::NoTypeFoundError)"
      end
    end
  end

  def test_validate_no_type_found_error_4
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo[A]
          extend Bar[A]
        end

        module Bar[B]
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:2:13...2:14: Could not find ::A (RBS::NoTypeFoundError)"
      end
    end
  end

  def test_validate_with_cyclic_type_parameter_bound_1
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo[A < _Each[B], B < _Foo[A]]
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:1:9...1:36: Cyclic type parameter bound is prohibited (RBS::CyclicTypeParameterBound)"
      end
    end
  end

  def test_validate_with_cyclic_type_parameter_bound_2
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          class Foo[A < _Each[B]]
            def foo: [X < _Foo[Y]] () -> X

            def bar: [X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]] () -> void
          end

          class B
          end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:4:11...4:50: Cyclic type parameter bound is prohibited (RBS::CyclicTypeParameterBound)"
      end
    end
  end

  def test_validate_with_cyclic_type_parameter_bound_3
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        interface _Foo[A < _Each[B], B < _Baz[A]]
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:1:14...1:41: Cyclic type parameter bound is prohibited (RBS::CyclicTypeParameterBound)"
      end
    end
  end

  def test_validate_with_cyclic_type_parameter_bound_4
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        interface _Foo[A]
          def foo: [X < _Foo[Y]] () -> X

          def bar: [X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]] () -> void
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "a.rbs:4:11...4:50: Cyclic type parameter bound is prohibited (RBS::CyclicTypeParameterBound)"
      end
    end
  end

  def test_validate__generics_default
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          module A[T = Integer]
          end

          class B[S = String]
          end

          interface _C[T = Symbol]
          end

          class Foo[T = A]
            type t = A

            def foo: () -> A

            def self.bar: () -> B
          end

          class Bar < B
            include A
            extend A
            include _C
            extend _C
          end

          module Baz : A, _C
          end
        RBS

        cli.run(["-I", dir, "validate"])
      end
    end
  end

  def test_validate__generics_default2
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        dir = Pathname(dir)

        (dir + 'a.rbs').write(<<~RBS)
          module A[T = Integer]
          end

          class B[S = String]
          end

          interface _C[T = Symbol]
          end
        RBS

        (dir + "x0.rbs").write(<<~RBS)
          class X0[T = A[Symbol, Symbol]]
          end
        RBS

        (dir + "x1.rbs").write(<<~RBS)
          class X1 < B[String, untyped]
          end
        RBS

        (dir + "x2.rbs").write(<<~RBS)
          class X2
            include A[String, untyped]
          end
        RBS

        (dir + "x3.rbs").write(<<~RBS)
          class X3
            include _C[String, untyped]
          end
        RBS

        (dir + "x4.rbs").write(<<~RBS)
          class X4
            prepend A[String, untyped]
          end
        RBS

        (dir + "x5.rbs").write(<<~RBS)
          class X5
            extend A[String, untyped]
          end
        RBS

        (dir + "x6.rbs").write(<<~RBS)
          class X6
            extend _C[String, untyped]
          end
        RBS

        (dir + "x7.rbs").write(<<~RBS)
          module X7 : A[String, untyped]
          end
        RBS


        assert_raises SystemExit do
          cli.run(["-I", dir.to_s, "validate"])
        end

        assert_include stdout.string, "/x0.rbs:1:13...1:30: ::A expects parameters [T = ::Integer], but given args [::Symbol, ::Symbol] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x1.rbs:1:11...1:29: ::B expects parameters [S = ::String], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x2.rbs:2:2...2:28: ::A expects parameters [T = ::Integer], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x3.rbs:2:2...2:29: ::_C expects parameters [T = ::Symbol], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x4.rbs:2:2...2:28: ::A expects parameters [T = ::Integer], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x5.rbs:2:2...2:27: ::A expects parameters [T = ::Integer], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x6.rbs:2:2...2:28: ::_C expects parameters [T = ::Symbol], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
        assert_include stdout.string, "/x7.rbs:1:12...1:30: ::A expects parameters [T = ::Integer], but given args [::String, untyped] (RBS::InvalidTypeApplicationError)"
      end
    end
  end

  def test_validate__generics_default_self
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          module A[T = self]
          end

          class B[S = self]
          end

          interface _C[T = self]
          end

          type t[T = self] = untyped
        RBS

        cli.run(["-I", dir, "validate"])

        assert_include stdout.string, "/a.rbs:1:13...1:17: `self` type is not allowed in this context (RBS::WillSyntaxError)\n"
        assert_include stdout.string, "/a.rbs:4:12...4:16: `self` type is not allowed in this context (RBS::WillSyntaxError)\n"
        assert_include stdout.string, "/a.rbs:7:17...7:21: `self` type is not allowed in this context (RBS::WillSyntaxError)\n"
        assert_include stdout.string, "/a.rbs:10:11...10:15: `self` type is not allowed in this context (RBS::WillSyntaxError)\n"
      end
    end
  end

  def test_validate__generics_default_ref
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          module A[A, B = A, C = B?]
          end

          class B[A, B = A, C = B?]
          end

          interface _C[A, B = A, C = B?]
          end

          type t[A, B = A, C = B?] = untyped
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end

        assert_include stdout.string, "/a.rbs:1:23...1:25: the default of C cannot include optional type parameter (RBS::TypeParamDefaultReferenceError)\n"
        assert_include stdout.string, "/a.rbs:4:22...4:24: the default of C cannot include optional type parameter (RBS::TypeParamDefaultReferenceError)\n"
        assert_include stdout.string, "/a.rbs:7:27...7:29: the default of C cannot include optional type parameter (RBS::TypeParamDefaultReferenceError)\n"
        assert_include stdout.string, "/a.rbs:10:21...10:23: the default of C cannot include optional type parameter (RBS::TypeParamDefaultReferenceError)\n"
      end
    end
  end

  def test_validate_multiple
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          class Foo
            def foo: (void) -> void
            def bar: (void) -> void
          end
        RBS

        cli.run(["-I", dir, "--log-level=warn", "validate"])

        assert_include stdout.string, "a.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
        assert_include stdout.string, "a.rbs:3:11...3:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
      end
    end
  end

  def test_validate_multiple_with_fail_fast
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          class Foo
            def foo: (void) -> void
            def bar: (void) -> void
          end
        RBS

        cli.run(["-I", dir, "--log-level=warn", "validate", "--fail-fast"])
        assert_include stdout.string, "a.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
        assert_include stdout.string, "a.rbs:3:11...3:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
      end
    end
  end

  def test_validate_multiple_with_exit_error_on_syntax_error
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          class Foo
            def foo: (void) -> void
            def bar: (void) -> void
          end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "--log-level=warn", "validate", "--exit-error-on-syntax-error"])
        end
        assert_include stdout.string, "a.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
        assert_include stdout.string, "a.rbs:3:11...3:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
      end
    end
  end

  def test_validate_multiple_with_fail_fast_and_exit_error_on_syntax_error
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
          class Foo
            def foo: (void) -> void
            def bar: (void) -> void
          end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "--log-level=warn", "validate", "--fail-fast", "--exit-error-on-syntax-error"])
        end
        assert_include stdout.string, "a.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
        assert_not_include stdout.string, "a.rbs:3:11...3:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)"
      end
    end
  end

  def test_validate_multiple_with_many_errors
    with_cli do |cli|
      assert_raise SystemExit do
        cli.run(%w(--log-level=warn -I test/multiple_error.rbs validate))
      end
      assert_include(stdout.string, "`void` type is only allowed in return type or generics parameter")
      assert_include(stdout.string, "test/multiple_error.rbs:6:17...6:24: ::TypeArg expects parameters [T], but given args [] (RBS::InvalidTypeApplicationError)")
      assert_include(stdout.string, "test/multiple_error.rbs:8:0...9:3: Detected recursive ancestors: ::RecursiveAncestor < ::RecursiveAncestor (RBS::RecursiveAncestorError)")
      assert_include(stdout.string, "test/multiple_error.rbs:11:15...11:22: Could not find Nothing (RBS::NoTypeFoundError)")
      assert_include(stdout.string, "test/multiple_error.rbs:13:0...14:3: Could not find super class: Nothing (RBS::NoSuperclassFoundError)")
      assert_include(stdout.string, "test/multiple_error.rbs:15:22...15:28: Cannot inherit a module: ::Kernel (RBS::InheritModuleError)")
      assert_include(stdout.string, "test/multiple_error.rbs:17:25...17:32: Could not find self type: Nothing (RBS::NoSelfTypeFoundError)")
      assert_include(stdout.string, "test/multiple_error.rbs:20:2...20:17: Could not find mixin: Nothing (RBS::NoMixinFoundError)")
      assert_include(stdout.string, "test/multiple_error.rbs:23:2...23:19: ::DuplicatedMethodDefinition#a has duplicated definitions in test/multiple_error.rbs:24:2...24:19 (RBS::DuplicatedMethodDefinitionError)")
      assert_include(stdout.string, "test/multiple_error.rbs:34:2...34:48: Duplicated method definition: ::DuplicatedInterfaceMethodDefinition_3#a (RBS::DuplicatedInterfaceMethodDefinitionError)")
      assert_include(stdout.string, "test/multiple_error.rbs:37:2...37:17: Unknown method alias name: nothing => a (::UnknownMethodAlias) (RBS::UnknownMethodAliasError)")
      assert_include(stdout.string, "test/multiple_error.rbs:43:0...44:3: Superclass mismatch: ::SuperclassMismatch (RBS::SuperclassMismatchError)")
      assert_include(stdout.string, "test/multiple_error.rbs:52:0...53:3: Generic parameters mismatch: ::GenericParameterMismatch (RBS::GenericParameterMismatchError)")
      assert_include(stdout.string, "test/multiple_error.rbs:58:9...58:20: Type parameter variance error: T is covariant but used as incompatible variance (RBS::InvalidVarianceAnnotationError)")
      assert_include(stdout.string, "test/multiple_error.rbs:61:2...61:11: Unknown method alias name: a => a (::RecursiveAliasDefinition) (RBS::UnknownMethodAliasError)")
      assert_include(stdout.string, "test/multiple_error.rbs:66:2...66:25: Cannot include a class `::MixinClassClass` in the definition of `::MixinClassModule` (RBS::MixinClassError)")
      assert_include(stdout.string, "test/multiple_error.rbs:77:37...77:44: Could not find Nothing (RBS::NoTypeFoundError)")
      assert_include(stdout.string, "test/multiple_error.rbs:78:35...78:61: A ::CyclicClassAliasDefinition is a cyclic definition (RBS::CyclicClassAliasDefinitionError)")
      assert_include(stdout.string, "test/multiple_error.rbs:48:2...48:27: Invalid method overloading: ::_InvalidOverloadMethod#foo (RBS::InvalidOverloadMethodError)")
      assert_include(stdout.string, "test/multiple_error.rbs:75:11...75:50: Cyclic type parameter bound is prohibited (RBS::CyclicTypeParameterBound)")
      assert_include(stdout.string, "test/multiple_error.rbs:69:2...69:12: Recursive type alias definition found for: a (RBS::RecursiveTypeAliasError)")
      assert_include(stdout.string, "test/multiple_error.rbs:72:2...72:25: Nonregular generic type alias is prohibited: ::NonregularTypeAlias::bar, ::NonregularTypeAlias::bar[T?] (RBS::NonregularTypeAliasError)")
    end
  end

  def test_validate_multiple_fail_fast
    with_cli do |cli|
      assert_raise SystemExit do
        cli.run(%w(--log-level=warn -I test/multiple_error.rbs validate --fail-fast))
      end
      assert_include(stdout.string, "test/multiple_error.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)")
      assert_include(stdout.string, "test/multiple_error.rbs:3:11...3:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)")
      assert_include(stdout.string, "test/multiple_error.rbs:6:17...6:24: ::TypeArg expects parameters [T], but given args []")
    end
  end

  def test_validate_multiple_fail_fast_and_exit_error_on_syntax_error
    with_cli do |cli|
      assert_raise SystemExit do
        cli.run(%w(--log-level=warn -I test/multiple_error.rbs validate --fail-fast --exit-error-on-syntax-error))
      end
      assert_include(stdout.string, "test/multiple_error.rbs:2:11...2:25: `void` type is only allowed in return type or generics parameter (RBS::WillSyntaxError)")
    end
  end

  def test_context_validation
    tests = [
      <<~RBS,
        class Foo
          def foo: (void) -> untyped
        end
      RBS
      <<~RBS,
        class Bar[A]
        end
        class Foo < Bar[instance]
        end
      RBS
      <<~RBS,
        module Bar : _Each[instance]
        end
      RBS
      <<~RBS,
        module Foo[A < _Each[self]]
        end
      RBS
      <<~RBS,
        class Foo
          @@bar: self
        end
      RBS
      <<~RBS,
        type foo = instance
      RBS
      <<~RBS,
        BAR: instance
      RBS
      <<~RBS,
        class Foo
          include Enumerable[self]
        end
      RBS
      <<~RBS,
        $FOO: instance
      RBS
    ]

    tests.each do |rbs|
      with_cli do |cli|
        Dir.mktmpdir do |dir|
          (Pathname(dir) + 'a.rbs').write(rbs)

          cli.run(["-I", dir, "validate"])

          assert_match(/void|self|instance|class/, stdout.string)

          cli.run(["-I", dir, "validate", "--no-exit-error-on-syntax-error"])
          assert_raises SystemExit do
            cli.run(["-I", dir, "validate", "--exit-error-on-syntax-error"])
          end
        end
      end
    end
  end

  def test_validate_878
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Bar[out X]
          def voice: [X] { () -> X } -> String
        end
        RBS

        cli.run(["-I", dir, "validate"])
      end
    end
  end

  def test_undefined_interface
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo
          def void: () -> _Void
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end
        assert_match %r{a.rbs:2:18...2:23: Could not find _Void \(.*RBS::NoTypeFoundError.*\)}, stdout.string
      end
    end
  end

  def test_undefined_alias
    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo
          def void: () -> voida
        end
        RBS

        assert_raises SystemExit do
          cli.run(["-I", dir, "validate"])
        end
        assert_match %r{a.rbs:2:18...2:23: Could not find voida \(.*RBS::NoTypeFoundError.*\)}, stdout.string
      end
    end
  end

  def test_constant
    with_cli do |cli|
      cli.run(%w(constant Pathname))
      cli.run(%w(constant --context File IO))
    end
  end

  def test_version
    with_cli do |cli|
      cli.run(%w(version))
    end
  end

  def test_paths
    with_cli do |cli|
      cli.run(%w(-r pathname -I no-such-dir paths))
      assert_match %r{/core \(dir, core\)$}, stdout.string
      assert_match %r{/stdlib/pathname/0 \(dir, library, name=pathname\)$}, stdout.string
      assert_match %r{^no-such-dir \(absent\)$}, stdout.string
    end
  end

  def test_paths_with_gem
    omit unless has_gem?("rbs-amber")

    with_cli do |cli|
      cli.run(%w(-r rbs-amber paths))
      assert_match %r{/core \(dir, core\)$}, stdout.string
      assert_match %r{/sig \(dir, library, name=rbs-amber\)$}, stdout.string
    end
  end

  def test_vendor
    Dir.mktmpdir do |d|
      Dir.chdir(d) do
        with_cli do |cli|
          cli.run(%w(vendor --vendor-dir=dir1))

          assert_predicate Pathname(d) + "dir1/core", :directory?
        end
      end
    end
  end

  def test_vendor_gem
    omit unless has_gem?("rbs-amber")

    Dir.mktmpdir do |d|
      Dir.chdir(d) do
        with_cli do |cli|
          cli.run(%w(-r rbs-amber vendor --vendor-dir=dir1))

          assert_predicate Pathname(d) + "dir1/rbs-amber-1.0.0", :directory?
        end
      end
    end
  end

  def test_parse
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('syntax_error.rbs').write(<<~RBS)
        class C
          def foo: () ->
        end
      RBS
      dir.join('semantics_error.rbs').write(<<~RBS)
        interface _I
          def self.foo: () -> void
        end
      RBS
      dir.join('no_error.rbs').write(<<~RBS)
        class C
          def foo: () -> void
        end
      RBS

      with_cli do |cli|
        assert_raises(SystemExit) { cli.run(%W(parse #{dir})) }

        assert_equal [
          "#{dir}/semantics_error.rbs:2:10...2:11: Syntax error: expected a token `pCOLON`, token=`.` (pDOT) (RBS::ParsingError)",
          "",
          "    def self.foo: () -> void",
          "            ^",
          "#{dir}/syntax_error.rbs:3:0...3:3: Syntax error: unexpected token for simple type, token=`end` (kEND) (RBS::ParsingError)",
          "",
          "  end",
          "  ^^^"
        ], stdout.string.gsub(/\e\[.*?m/, '').split("\n")
      end
    end
  end

  def test_parse_e
    with_cli do |cli|
      cli.run(['parse', '-e', 'class C end'])
      assert_empty stdout.string

      assert_raises(SystemExit) { cli.run(['parse', '-e', 'class C en']) }
      assert_equal [
        "-e:1:8...1:10: Syntax error: unexpected token for class/module declaration member, token=`en` (tLIDENT) (RBS::ParsingError)",
        "",
        "  class C en",
        "          ^^"
      ], stdout.string.gsub(/\e\[.*?m/, '').split("\n")
    end
  end

  def test_parse_type
    with_cli do |cli|
      cli.run(['parse', '--type', '-e', 'bool'])
      assert_empty stdout.string

      assert_raises(SystemExit) { cli.run(['parse', '--type', '-e', '?']) }
      assert_equal [
        "-e:1:0...1:1: Syntax error: unexpected token for simple type, token=`?` (pQUESTION) (RBS::ParsingError)",
        "",
        "  ?",
        "  ^"
      ], stdout.string.gsub(/\e\[.*?m/, '').split("\n")
    end
  end

  def test_parse_method_type
    with_cli do |cli|
      cli.run(['parse', '--method-type', '-e', '() -> void'])
      assert_empty stdout.string

      assert_raises(SystemExit) { cli.run(['parse', '--method-type', '-e', '()']) }
      assert_equal [
        "-e:1:2...1:2: Syntax error: expected a token `pARROW`, token=`` (pEOF) (RBS::ParsingError)",
        "",
        "  ()",
        "    ^"
      ], stdout.string.gsub(/\e\[.*?m/, '').split("\n")
    end
  end

  def test_prototype_no_parser
    Dir.mktmpdir do |dir|
      with_cli do |cli|
        def cli.has_parser?
          false
        end

        assert_raises SystemExit do
          cli.run(%w(prototype rb))
        end

        assert_raises SystemExit do
          cli.run(%w(prototype rbi))
        end

        assert_equal "Not supported on this interpreter (ruby).\n", stdout.string.lines[0]
        assert_equal "Not supported on this interpreter (ruby).\n", stdout.string.lines[1]
      end
    end
  end

  def test_prototype_batch
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      (dir + "lib").mkdir
      (dir + "lib/a.rb").write(<<-RUBY)
module A
end
      RUBY
      (dir + "lib/a").mkdir
      (dir + "lib/a/b.rb").write(<<-RUBY)
module A
  class B
  end
end
      RUBY
      (dir + "lib/c.rb").write(<<-RUBY)
module C
end
      RUBY
      (dir + "Gemfile").write(<<-RUBY)
source "https://rubygems.org"

gem "rbs"
      RUBY

      (dir+"sig").mkdir
      (dir + "sig/c.rbs").write(<<-RUBY)
module C
end
      RUBY

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(prototype rb --out_dir=sig lib Gemfile))

          assert_equal <<-EOM, cli.stdout.string
Processing `lib`...
  Generating RBS for `lib/a/b.rb`...
    - Writing RBS to `sig/a/b.rbs`...
  Generating RBS for `lib/a.rb`...
    - Writing RBS to `sig/a.rbs`...
  Generating RBS for `lib/c.rb`...
    - Skipping existing file `sig/c.rbs`...
Processing `Gemfile`...
  Generating RBS for `Gemfile`...
    - Writing RBS to `sig/Gemfile.rbs`...

>>>> Skipped existing 1 files. Use `--force` option to update the files.
  bundle exec rbs prototype rb --out_dir\\=sig --force lib/c.rb
        EOM
        end
      end

      assert_predicate dir + "sig", :directory?
      assert_predicate dir + "sig/a.rbs", :exist?
      assert_predicate dir + "sig/a", :exist?
      assert_predicate dir + "sig/a/b.rbs", :exist?
    end
  end

  def test_prototype_batch_outer
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      (dir + "test").mkdir
      (dir + "test/a_test.rb").write(<<-RUBY)
module A
end
      RUBY

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(prototype rb --out_dir=sig --base_dir=lib test/a_test.rb))

          assert_equal <<-EOM, cli.stdout.string
Processing `test/a_test.rb`...
  Generating RBS for `test/a_test.rb`...
  ⚠️  Cannot write the RBS to outside of the output dir: `../test/a_test.rb`
          EOM
        end
      end

      refute_predicate dir + "sig", :directory?
    end
  end

  def test_prototype_batch_syntax_error
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      (dir + "lib").mkdir
      (dir + "lib/a.rb").write(<<-RUBY)
class A < <%= @superclass %>
end
      RUBY

      Dir.chdir(dir) do
        with_cli do |cli|
          cli.run(%w(prototype rb --out_dir=sig lib))

          assert_equal <<-EOM, cli.stdout.string
Processing `lib`...
  Generating RBS for `lib/a.rb`...
  ⚠️  Unable to parse due to SyntaxError: `lib/a.rb`
          EOM
        end
      end

      refute_predicate dir + "sig", :directory?
    end
  end

  def test_prototype__runtime__todo
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        with_cli do |cli|
          begin
            old = $stderr
            $stderr = cli.stderr
            cli.run(%w(prototype runtime --todo ::Object))
          ensure
            $stderr = old
          end

          assert_equal <<~EOM, cli.stdout.string
          EOM

          assert_match Regexp.new(Regexp.escape "Generating prototypes with `--todo` option is experimental"), cli.stderr.string
        end
      end
    end
  end


  def test_test
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)
      dir.join('foo.rbs').write(<<~RBS)
        class Foo
          def foo: () -> void
        end

        module Bar
          class Baz
            def foo: () -> void
          end
        end
      RBS

      with_cli do |cli|
        # `exit` is a common shell built-in command.
        assert_rbs_test_no_errors(cli, dir, %w(--target ::Foo exit))

        assert_raises(SystemExit) { cli.run(%w(test)) }
        assert_raises(SystemExit) { cli.run(%W(-I #{dir} test)) }
        assert_raises(SystemExit) { cli.run(%W(-I #{dir} test --target ::Foo)) }
      end
    end
  end

  def test_collection_install
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)
        dir.join(RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML

        bundle_install('ast', 'abbrev', 'bigdecimal', 'logger')
        _stdout, _stderr = run_rbs_collection("install", bundler: true)

        rbs_collection_lock = dir.join('rbs_collection.lock.yaml')
        assert rbs_collection_lock.exist?
        rbs_collection_lock.delete

        collection_dir = dir.join('gem_rbs_collection/ast')
        assert collection_dir.exist?
        collection_dir.rmtree

        Dir.mkdir("child")
        Dir.chdir("child") do
          _stdout, _stderr = run_rbs_collection("install", bundler: true)
          assert rbs_collection_lock.exist?
          assert collection_dir.exist?
        end
      end
    end
  end

  def test_collection_install_frozen
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)
        lock_content = <<~YAML
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems
          path: #{dir.join('gem_rbs_collection')}
          gems:
            - name: ast
              version: "2.4"
              source:
                name: ruby/gem_rbs_collection
                remote: https://github.com/ruby/gem_rbs_collection.git
                revision: b4d3b346d9657543099a35a1fd20347e75b8c523
                repo_dir: gems
        YAML
        dir.join('rbs_collection.lock.yaml').write(lock_content)

        run_rbs_collection("install", "--frozen", bundler: false)

        refute dir.join(RBS::Collection::Config::PATH).exist?
        assert dir.join('gem_rbs_collection/ast').exist?
        assert_equal lock_content, dir.join('rbs_collection.lock.yaml').read
      end
    end
  end

  def test_collection_update
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)
        dir.join(RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML

        bundle_install('ast', 'abbrev', 'bigdecimal', 'logger')
        run_rbs_collection("update", bundler: true)

        assert dir.join('rbs_collection.lock.yaml').exist?
        assert dir.join('gem_rbs_collection/ast').exist?
      end
    end
  end

  def test_collection_install_gemspec
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)
        dir.join(RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML
        gemspec_path = dir / "hola.gemspec"
        gemspec_path.write <<~RUBY
          Gem::Specification.new do |s|
            s.name        = "hola"
            s.version     = "0.0.0"
            s.summary     = "Hola!"
            s.description = "A simple hello world gem"
            s.authors     = ["Nick Quaranto"]
            s.email       = "nick@quaran.to"
            s.files       = ["lib/hola.rb", "sig/hola.rbs"]
            s.homepage    =
              "https://rubygems.org/gems/hola"
            s.license       = "MIT"
            s.add_dependency "ast", "> 2"
          end
        RUBY
        (dir/"sig").mkdir

        bundle_install(:gemspec, "abbrev", "bigdecimal", "logger")
        stdout, _ = run_rbs_collection("install", bundler: true)

        assert_match(/Installing ast:(\d(\.\d)*)/, stdout)
        refute_match(/^Using hola:(\d(\.\d)*)/, stdout)

        assert dir.join('rbs_collection.lock.yaml').exist?
        assert dir.join('gem_rbs_collection/ast').exist?
      end
    end
  end

  def test_collection_install__mutex_m__config__bundled
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}

          gems:
          - name: mutex_m
        YAML

        bundle_install("logger", ["mutex_m", ">= 0.3.0"])
        _stdout, stderr = run_rbs_collection("install", bundler: true)

        refute_match(/`mutex_m` as a stdlib in rbs-gem is deprecated./, stderr)

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Rubygems, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__config__no_bundled
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}

          gems:
          - name: mutex_m
        YAML

        bundle_install("logger", ["mutex_m", "0.2.0"])
        _stdout, stderr = run_rbs_collection("install", bundler: true)

        assert_include stderr, '`mutex_m` as a stdlib in rbs-gem is deprecated.'
        assert_include stderr, 'Add `mutex_m` (>= 0.3.0) to the dependency of your Ruby program to use the gem-bundled type definition.'

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Stdlib, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__config__stdlib_source
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}

          gems:
          - name: mutex_m
            source:
              type: stdlib
        YAML

        bundle_install("logger")
        _stdout, stderr = run_rbs_collection("install", bundler: true)

        assert_include stderr, '`mutex_m` as a stdlib in rbs-gem is deprecated.'
        assert_include stderr, 'Add `mutex_m` (>= 0.3.0) to the dependency of your Ruby program to use the gem-bundled type definition.'

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Stdlib, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__bundled
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML

        bundle_install("logger", ["mutex_m", ">= 0.3.0"])
        _stdout, stderr = run_rbs_collection("install", bundler: true)

        refute_match(/`mutex_m` as a stdlib in rbs-gem is deprecated./, stderr)

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Rubygems, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__no_bundled
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML

        bundle_install("logger", ["mutex_m", "0.2.0"])
        _stdout, stderr = run_rbs_collection("install", bundler: true)

        assert_include stderr, '`mutex_m` as a stdlib in rbs-gem is deprecated.'
        assert_include stderr, 'Add `mutex_m` (>= 0.3.0) to the dependency of your Ruby program to use the gem-bundled type definition.'

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Stdlib, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__dependency_no_bundled
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - type: local
              path: repo

          path: #{dir.join('gem_rbs_collection')}
        YAML

        (dir/"repo/true_string/0").mkpath
        (dir/"repo/true_string/0/manifest.yaml").write(<<~YAML)
          dependencies:
          - name: mutex_m
        YAML

        bundle_install("logger", "true_string")  # true_string is a soutaro's gem that doesn't have sig directory

        _stdout, stderr = run_rbs_collection("install", bundler: true)

        assert_include stderr, '`mutex_m` is included in the RBS dependencies of `true_string`, but the type definition as a stdlib in rbs-gem is deprecated.'
        assert_include stderr, 'Add `mutex_m` (>= 0.3.0) to the dependency of your Ruby program to use the gem-bundled type definition.'

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Stdlib, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_collection_install__mutex_m__rbs_dependency_and__gem_dependency
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        dir = Pathname(dir)

        (dir/"gem").mkpath
        (dir/"gem/hola.gemspec").write(<<~RUBY)
          Gem::Specification.new do |s|
            s.name        = "hola"
            s.version     = "0.0.0"
            s.summary     = "Hola!"
            s.description = "A simple hello world gem"
            s.authors     = ["Nick Quaranto"]
            s.email       = "nick@quaran.to"
            s.files       = ["lib/hola.rb", "sig/hola.rbs"]
            s.homepage    =
              "https://rubygems.org/gems/hola"
            s.license       = "MIT"
            s.add_runtime_dependency "mutex_m", ">= 0.3.0"
          end
        RUBY
        (dir/"gem/sig").mkpath
        (dir/"gem/sig/manifest.yaml").write(<<~YAML)
          dependencies:
          - name: mutex_m
        YAML

        bundle_install("logger", ["hola", { path: "gem" }])

        (dir + RBS::Collection::Config::PATH).write(<<~YAML)
          sources:
            - name: ruby/gem_rbs_collection
              remote: https://github.com/ruby/gem_rbs_collection.git
              revision: b4d3b346d9657543099a35a1fd20347e75b8c523
              repo_dir: gems

          path: #{dir.join('gem_rbs_collection')}
        YAML

        _stdout, stderr = run_rbs_collection("install", bundler: true)

        assert_include stderr, '`mutex_m` is included in the RBS dependencies of `hola`, but the type definition as a stdlib in rbs-gem is deprecated.'
        assert_include stderr, 'Delete `mutex_m` from the RBS dependencies of `hola`.'

        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: dir + "rbs_collection.lock.yaml",
          data: YAML.safe_load((dir + "rbs_collection.lock.yaml").read)
        )

        assert_instance_of RBS::Collection::Sources::Rubygems, lockfile.gems["mutex_m"][:source]
      end
    end
  end

  def test_subtract
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      minuend = dir.join('minuend.rbs')
      minuend.write(<<~RBS)
        use A::B
        class C
          def x: () -> untyped
          def y: () -> untyped
        end
      RBS
      subtrahend = dir.join('subtrahend.rbs')
      subtrahend.write(<<~RBS)
        class C
          def x: () -> untyped
        end
      RBS

      with_cli do |cli|
        cli.run(['subtract', minuend.to_s, subtrahend.to_s])
        assert_empty stderr.string
        assert_equal <<~RBS, stdout.string
          use A::B

          class C
            def y: () -> untyped
          end
        RBS
      end
    end
  end

  def test_subtract_several_subtrahends
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      minuend = dir.join('minuend.rbs')
      minuend.write(<<~RBS)
        use A::B
        class C
          def x: () -> untyped
          def y: () -> untyped
          def z: () -> untyped
        end
      RBS
      subtrahend_1 = dir.join('subtrahend_1.rbs')
      subtrahend_1.write(<<~RBS)
        class C
          def x: () -> untyped
        end
      RBS
      subtrahend_2 = dir.join('subtrahend_2.rbs')
      subtrahend_2.write(<<~RBS)
        class C
          def y: () -> untyped
        end
      RBS

      with_cli do |cli|
        cli.run(['subtract', minuend.to_s, '--subtrahend', subtrahend_1.to_s, '--subtrahend', subtrahend_2.to_s])
        assert_empty stderr.string
        assert_equal <<~RBS, stdout.string
          use A::B

          class C
            def z: () -> untyped
          end
        RBS
      end
    end
  end

  def test_subtract_write
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      minuend = dir.join('minuend.rbs')
      minuend.write(<<~RBS)
        use A::B
        class C
          def x: () -> untyped
          def y: () -> untyped
        end
      RBS
      subtrahend = dir.join('subtrahend.rbs')
      subtrahend.write(<<~RBS)
        class C
          def x: () -> untyped
        end
      RBS

      with_cli do |cli|
        cli.run(['subtract', '--write', minuend.to_s, subtrahend.to_s])
        assert_empty stderr.string
        assert_empty stdout.string
        assert_equal minuend.read, <<~RBS
          use A::B

          class C
            def y: () -> untyped
          end
        RBS
      end
    end
  end


  def test_subtract_write_removes_definition_if_empty
    Dir.mktmpdir do |dir|
      dir = Pathname(dir)

      minuend = dir.join('minuend.rbs')
      minuend.write(<<~RBS)
        class C
          def x: () -> untyped
        end
      RBS
      subtrahend = dir.join('subtrahend.rbs')
      subtrahend.write(<<~RBS)
        class C
          def x: () -> untyped
        end
      RBS

      with_cli do |cli|
        cli.run(['subtract', '--write', minuend.to_s, subtrahend.to_s])
        assert_empty stderr.string
        assert_empty stdout.string
        refute_predicate minuend, :exist?
    end
    end
  end

  def assert_rbs_test_no_errors cli, dir, arg_array
    args = ['-I', dir.to_s, 'test', *arg_array]
    assert_instance_of Process::Status, cli.run(args)
  end

  def mktmp_diff_case
    Dir.mktmpdir do |path|
      path = Pathname(path)

      dir1 = (path / "dir1")
      dir1.mkdir
      (dir1 / 'before.rbs').write(<<~RBS)
        class Foo
          def bar: () -> void
          def self.baz: () -> (Integer | String)
          def qux: (untyped) -> untyped
          def quux: () -> void

          CONST: Array[Integer]
        end
      RBS

      dir2 = (path / "dir2")
      dir2.mkdir
      (dir2 / 'after.rbs').write(<<~RBS)
        module Bar
          def bar: () -> void
        end

        module Baz
          def baz: (Integer) -> Integer?
        end

        class Foo
          include Bar
          extend Baz
          alias quux bar
          CONST: Array[String]
        end
      RBS

      yield dir1, dir2
    end
  end

  def test_diff_markdown
    mktmp_diff_case do |dir1, dir2|
      with_cli do |cli|
        cli.run(['diff', '--format', 'markdown', '--type-name', 'Foo', '--before', dir1.to_s, '--after', dir2.to_s])

        assert_equal <<~MARKDOWN, stdout.string
          | before | after |
          | --- | --- |
          | `def qux: (untyped) -> untyped` | `-` |
          | `def quux: () -> void` | `alias quux bar` |
          | `def self.baz: () -> (::Integer \\| ::String)` | `def self.baz: (::Integer) -> ::Integer?` |
          | `CONST: ::Array[::Integer]` | `CONST: ::Array[::String]` |
        MARKDOWN
      end
    end
  end

  def test_diff_diff
    mktmp_diff_case do |dir1, dir2|
      with_cli do |cli|
        cli.run(['diff', '--format', 'diff', '--type-name', 'Foo', '--before', dir1.to_s, '--after', dir2.to_s])

        assert_equal <<~DIFF, stdout.string
          - def qux: (untyped) -> untyped
          + -

          - def quux: () -> void
          + alias quux bar

          - def self.baz: () -> (::Integer | ::String)
          + def self.baz: (::Integer) -> ::Integer?

          - CONST: ::Array[::Integer]
          + CONST: ::Array[::String]
        DIFF
      end
    end
  end
end
