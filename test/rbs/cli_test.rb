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

  def with_cli
    yield CLI.new(stdout: stdout, stderr: stderr)
  ensure
    @stdout = nil
    @stderr = nil
  end

  def test_ast
    with_cli do |cli|
      cli.run(%w(-r set ast))

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
  end

  def test_ancestors
    with_cli do |cli|
      cli.run(%w(-r set ancestors ::Set))
      assert_equal <<-EOF, stdout.string
::Set[A]
::Enumerable[A]
::Object
::Kernel
::BasicObject
      EOF
    end

    with_cli do |cli|
      cli.run(%w(-r set ancestors --instance ::Set))
      assert_equal <<-EOF, stdout.string
::Set[A]
::Enumerable[A]
::Object
::Kernel
::BasicObject
      EOF
    end

    with_cli do |cli|
      cli.run(%w(-r set ancestors --singleton ::Set))
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
  end

  def test_methods
    with_cli do |cli|
      cli.run(%w(-r set methods ::Set))
      cli.run(%w(-r set methods --instance ::Set))
      cli.run(%w(-r set methods --singleton ::Set))
    end
  end

  def test_method
    with_cli do |cli|
      cli.run(%w(-r set method ::Object yield_self))
      assert_equal <<-EOF, stdout.string
::Object#yield_self
  defined_in: ::Object
  implementation: ::Object
  accessibility: public
  types:
      [X] () { (self) -> X } -> X
    | () -> ::Enumerator[self, untyped]
      EOF
    end
  end

  def test_validate
    with_cli do |cli|
      cli.run(%w(-r set validate))
      assert_match(/Validating/, stdout.string)
    end

    with_cli do |cli|
      cli.run(%w(validate --silent))
      assert_equal "", stdout.string
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Hello::World
        end
        RBS

        error = assert_raises RBS::NoTypeFoundError do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal "::Hello", error.type_name.to_s
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        Hello::World: Integer
        RBS

        error = assert_raises RBS::NoTypeFoundError do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal "::Hello", error.type_name.to_s
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        type Hello::t = Integer
        RBS

        error = assert_raises RBS::NoTypeFoundError do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal "::Hello", error.type_name.to_s
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo[A]
          extend Bar[A]
        end

        module Bar[B]
        end
        RBS

        error = assert_raises RBS::NoTypeFoundError do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal "::A", error.type_name.to_s
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo[A < _Each[B], B < _Foo[A]]
        end
        RBS

        error = assert_raises RBS::CyclicTypeParameterBound do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal TypeName("::Foo"), error.type_name
        assert_nil error.method_name
        assert_equal "[A < _Each[B], B < _Foo[A]]", error.location.source
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        class Foo[A < _Each[B]]
          def foo: [X < _Foo[Y]] () -> X

          def bar: [X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]] () -> void
        end
        RBS

        error = assert_raises RBS::CyclicTypeParameterBound do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal TypeName("::Foo"), error.type_name
        assert_equal :bar, error.method_name
        assert_equal "[X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]]", error.location.source
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        interface _Foo[A < _Each[B], B < _Baz[A]]
        end
        RBS

        error = assert_raises RBS::CyclicTypeParameterBound do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal TypeName("::_Foo"), error.type_name
        assert_nil error.method_name
        assert_equal "[A < _Each[B], B < _Baz[A]]", error.location.source
      end
    end

    with_cli do |cli|
      Dir.mktmpdir do |dir|
        (Pathname(dir) + 'a.rbs').write(<<~RBS)
        interface _Foo[A]
          def foo: [X < _Foo[Y]] () -> X

          def bar: [X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]] () -> void
        end
        RBS

        error = assert_raises RBS::CyclicTypeParameterBound do
          cli.run(["-I", dir, "validate"])
        end

        assert_equal TypeName("::_Foo"), error.type_name
        assert_equal :bar, error.method_name
        assert_equal "[X < _Foo[Y], Y < _Bar[Z], Z < _Baz[X]]", error.location.source
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

  def test_constant
    with_cli do |cli|
      cli.run(%w(-r set constant Pathname))
      cli.run(%w(-r set constant --context File IO))
    end
  end

  def test_version
    with_cli do |cli|
      cli.run(%w(-r set version))
    end
  end

  def test_paths
    with_cli do |cli|
      cli.run(%w(-r set -I sig/test paths))
      assert_match %r{/rbs/core \(dir, core\)$}, stdout.string
      assert_match %r{/rbs/stdlib/set/0 \(dir, library, name=set\)$}, stdout.string
      assert_match %r{^sig/test \(absent\)$}, stdout.string
    end
  end

  def test_paths_with_gem
    omit unless has_gem?("rbs-amber")

    with_cli do |cli|
      cli.run(%w(-r rbs-amber paths))
      assert_match %r{/rbs/core \(dir, core\)$}, stdout.string
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
          "#{dir}/semantics_error.rbs:2:10...2:11: Syntax error: expected a token `pCOLON`, token=`.` (pDOT)",
          "#{dir}/syntax_error.rbs:3:0...3:3: Syntax error: unexpected token for simple type, token=`end` (kEND)",
        ], stdout.string.split("\n").sort
      end
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
        # Assumes there is `ls` command.
        assert_rbs_test_no_errors(cli, dir, %w(--target ::Foo ls))

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
        dir.join('Gemfile').write('')
        dir.join('Gemfile.lock').write(<<~LOCK)
          GEM
            remote: https://rubygems.org/
            specs:
              ast (2.4.2)

          PLATFORMS
            x86_64-linux

          DEPENDENCIES
            ast

          BUNDLED WITH
             2.2.0
        LOCK

        with_cli do |cli|
          cli.run(%w[collection install])

          rbs_collection_lock = dir.join('rbs_collection.lock.yaml')
          assert rbs_collection_lock.exist?
          rbs_collection_lock.delete

          collection_file = dir.join('gem_rbs_collection/ast')
          assert collection_file.exist?
          collection_file.rmtree

          Dir.mkdir("child")
          Dir.chdir("child") do
            cli.run(%w[collection install])
            assert rbs_collection_lock.exist?
            assert collection_file.exist?
          end
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

        with_cli do |cli|
          cli.run(%w[collection install --frozen])
          refute dir.join(RBS::Collection::Config::PATH).exist?
          assert dir.join('gem_rbs_collection/ast').exist?
          assert_equal lock_content, dir.join('rbs_collection.lock.yaml').read
        end
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
        dir.join('Gemfile').write('')
        dir.join('Gemfile.lock').write(<<~LOCK)
          GEM
            remote: https://rubygems.org/
            specs:
              ast (2.4.2)

          PLATFORMS
            x86_64-linux

          DEPENDENCIES
            ast

          BUNDLED WITH
             2.2.0
        LOCK

        with_cli do |cli|
          cli.run(%w[collection update])
          assert dir.join('rbs_collection.lock.yaml').exist?
          assert dir.join('gem_rbs_collection/ast').exist?
        end
      end
    end
  end

  def assert_rbs_test_no_errors cli, dir, arg_array
    args = ['-I', dir.to_s, 'test', *arg_array]
    assert_instance_of Process::Status, cli.run(args)
  end
end
