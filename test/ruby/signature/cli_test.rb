require "test_helper"
require "stringio"

require "ruby/signature/cli"

class Ruby::Signature::CliTest < Minitest::Test
  CLI = Ruby::Signature::CLI

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
::Enumerable[A, self]
::Object
::Kernel
::BasicObject
      EOF
    end

    with_cli do |cli|
      cli.run(%w(-r set ancestors --instance ::Set))
      assert_equal <<-EOF, stdout.string
::Set[A]
::Enumerable[A, self]
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
      EOF
    end
  end

  def test_validate
    with_cli do |cli|
      cli.run(%w(-r set validate))
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
      cli.run(%w(-r set -r racc -I sig/test paths))
      assert_match %r{/ruby-signature/stdlib/builtin \(dir, stdlib\)$}, stdout.string
      assert_match %r{/ruby-signature/stdlib/set \(dir, library, name=set\)$}, stdout.string
      assert_match %r{/racc-\d\.\d\.\d+/sig \(absent, gem, name=racc, version=\)$}, stdout.string
      assert_match %r{^sig/test \(absent\)$}, stdout.string
    end
  end
end
