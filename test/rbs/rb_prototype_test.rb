require "test_helper"

class RBS::RbPrototypeTest < Test::Unit::TestCase
  RB = RBS::Prototype::RB

  include TestHelper

  def test_class_module
    rb = <<-EOR
class Hello
end

class World < Hello
end

module Foo
end

class Bar < Struct.new(:bar)
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
end

class World < Hello
end

module Foo
end

class Bar
end
    EOF
  end

  def test_defs
    rb = <<-EOR
class Hello
  def hello(a, b = 3, *c, d, e:, f: 3, **g, &h)
  end

  def self.world
    yield
    yield 1, x: 3
    yield 1, 2, x: 3, y: 2
    yield 1, 2, 'hello' => world
  end

  def kw_req(a:) end

  def empty_array_opt(a = []) end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  def hello: (untyped a, ?::Integer b, *untyped c, untyped d, e: untyped, ?f: ::Integer, **untyped g) { (?) -> untyped } -> nil

  def self.world: () { (untyped, untyped, untyped, x: untyped, y: untyped) -> untyped } -> untyped

  def kw_req: (a: untyped) -> nil

  def empty_array_opt: (?::Array[untyped] a) -> nil
end
    EOF
  end

  def test_defs_return_type
    rb = <<-'EOR'
class Hello
  def initialize() 'foo' end

  def str() "こんにちは" end
  def str_lit() "foo" end
  def dstr() "f#{x}oo" end
  def xstr() `ls` end

  def sym() :foo end
  def dsym() :"foo#{bar}" end

  def regx() /foo/ end
  def dregx() /foo#{bar}/ end

  def t() true end
  def f() false end
  def n() nil end
  def n2() end

  def int() 42 end
  def float() 4.2 end
  def complex() 42i end
  def rational() 42r end

  def zlist() [] end
  def list1() [1, '2', :x] end
  def list2() [1, 2, foo] end

  def range1() 1..foo end
  def range2() 1..42 end
  def range3() foo..bar end

  def hash1() {} end
  def hash2() { foo: 1 } end
  def hash3() { foo: { bar: 42 }, x: { y: z } } end
  def hash4() { foo: 1, **({ bar: x}).compact } end

  def self1() self end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  def initialize: () -> void

  def str: () -> ::String

  def str_lit: () -> "foo"

  def dstr: () -> ::String

  def xstr: () -> ::String

  def sym: () -> :foo

  def dsym: () -> ::Symbol

  def regx: () -> ::Regexp

  def dregx: () -> ::Regexp

  def t: () -> true

  def f: () -> false

  def n: () -> nil

  def n2: () -> nil

  def int: () -> 42

  def float: () -> ::Float

  def complex: () -> ::Complex

  def rational: () -> ::Rational

  def zlist: () -> ::Array[untyped]

  def list1: () -> ::Array[1 | "2" | :x]

  def list2: () -> ::Array[1 | 2 | untyped]

  def range1: () -> ::Range[::Integer]

  def range2: () -> ::Range[::Integer]

  def range3: () -> ::Range[untyped]

  def hash1: () -> ::Hash[untyped, untyped]

  def hash2: () -> { foo: 1 }

  def hash3: () -> { foo: { bar: 42 }, x: { y: untyped } }

  def hash4: () -> ::Hash[:foo | untyped, 1 | untyped]

  def self1: () -> self
end
    EOF
  end

  def test_defs_return_type_with_block
    rb = <<-'EOR'
class Hello
  def with_return
    if cond
      return 1
    elsif cond2
      return '2'
    end
    :x
  end

  def with_untyped_return
    return foo if cond
    :x
  end

  def with_return_same_types
    return 1 if cond
    return 1 if cond2
    1
  end

  def with_return_without_value
    return if cond
    42
  end

  def when_last_is_nil
    foo
    nil
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  def with_return: () -> (1 | "2" | :x)

  def with_untyped_return: () -> (untyped | :x)

  def with_return_same_types: () -> 1

  def with_return_without_value: () -> (nil | 42)

  def when_last_is_nil: () -> nil
end
    EOF
  end

  def test_defs_return_type_with_block_optional
    rb = <<~'EOR'
      class Hello
        def with_optional_block1
          # `block_given?` call makes the block optional
          if block_given?
            yield 1
          end
        end

        def with_optional_block2(&block)
          # testing block var makes the block optional
          if block
            yield 1
          end
        end
      end
    EOR

    assert_write RB.parse(rb), <<~EOF
      class Hello
        def with_optional_block1: () ?{ (untyped) -> untyped } -> (untyped | nil)

        def with_optional_block2: () ?{ (untyped) -> untyped } -> (untyped | nil)
      end
    EOF
  end

  def test_defs_return_type_with_if
    rb = <<-EOR
class ReturnTypeWithIF
  def with_if
    if foo?
      true
    end
  end

  def with_if_and_block
    if foo?
      foo
      return false if bar?
      true
    end
  end

  def with_else_and_bool
    if foo?
      true
    else
      false
    end
  end

  def with_else_and_elsif_and_bool_nil
    if foo?
    elsif bar?
      true
    else
      false
    end
  end

  def with_nested_if
    if foo?
      if bar?
        if baz?
          1
        else
          2
        end
      else
        3
      end
    else
      4
    end
  end

  def with_unless
    unless foo?
      :sym
    end
  end
end
EOR

    assert_write RB.parse(rb), <<-EOR
class ReturnTypeWithIF
  def with_if: () -> (true | nil)

  def with_if_and_block: () -> (false | true | nil)

  def with_else_and_bool: () -> (true | false)

  def with_else_and_elsif_and_bool_nil: () -> (nil | true | false)

  def with_nested_if: () -> (1 | 2 | 3 | 4)

  def with_unless: () -> (:sym | nil)
end
EOR
  end

  def test_defs_return_type_multiple
    rb = <<~RUBY
      class Hello
        def one_statement
          return 1, ""
        end

        def multiple_statements
          foo
          return 1, ""
        end
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      class Hello
        def one_statement: () -> ::Array[1 | \"\"]

        def multiple_statements: () -> ::Array[1 | \"\"]
      end
    RBS
  end

  def test_sclass
    rb = <<-EOR
class Hello
  class << self
    def hello() end
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  def self.hello: () -> nil
end
    EOF
  end

  def test_meta_programming
    rb = <<-EOR
class Hello
  include Foo
  extend ::Bar, baz
  prepend Baz

  attr_reader :x
  attr_accessor :y, :z
  attr_writer foo, :a, 'b'

  class << self
    include FooBar

    attr_reader :x2
    attr_accessor :y2, :z2
    attr_writer foo2, :a2, 'b2'
  end
end

module Mod
  extend self

  module Mod2
    extend self
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  include Foo

  extend ::Bar

  prepend Baz

  attr_reader x: untyped

  attr_accessor y: untyped

  attr_accessor z: untyped

  attr_writer a: untyped

  attr_writer b: untyped

  extend FooBar

  attr_reader self.x2: untyped

  attr_accessor self.y2: untyped

  attr_accessor self.z2: untyped

  attr_writer self.a2: untyped

  attr_writer self.b2: untyped
end

module Mod
  extend ::Mod

  module Mod2
    extend ::Mod::Mod2
  end
end
    EOF
  end

  def test_module_function
    rb = <<-EOR
module Hello
  def foo() end

  def bar() end
  module_function :bar

  module_function def baz() end

  module_function

  def foobar() end

  module_function :unknown_method
end
    EOR

    assert_write RB.parse(rb), <<-EOF
module Hello
  def foo: () -> nil

  def self?.bar: () -> nil

  def self?.baz: () -> nil

  def self?.foobar: () -> nil
end
    EOF
  end

  def test_accessibility
    rb = <<-EOR
class Hello
  attr_reader :private_attr

  private :private_attr

  private def prv1() end

  private def prv2() end

  def pub1() end

  private

  def prv3() end

  public

  def pub2() end

  def prv4() end

  private :prv4
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  private

  attr_reader private_attr: untyped

  def prv1: () -> nil

  def prv2: () -> nil

  public

  def pub1: () -> nil

  private

  def prv3: () -> nil

  public

  def pub2: () -> nil

  private

  def prv4: () -> nil
end
    EOF
  end

  def test_accessibility_and_sclass
    rb = <<~RUBY
      class C
        class << self
          private

          def foo() end
        end

        def bar() end
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      class C
        private

        def self.foo: () -> nil

        public

        def bar: () -> nil
      end
    RBS
  end

  def test_aliases
    rb = <<-EOR
class Hello
  alias a b
  alias_method :c, 'd'

  # Ignore global variable alias
  alias $a $b

  class << self
    alias e f
    alias_method 'g', :h
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  alias a b

  alias c d

  alias self.e self.f

  alias self.g self.h
end
    EOF
  end

  def test_comments
    rb = <<-EOR
# Comments for class.
# This is a comment.
class Hello # :nodoc:
  # Comment for include.
  include Foo

  # Comment to be ignored

  # Comment for extend
  extend ::Bar, baz

  # Comment for hello
  def hello()
  end

  # Comment for world
  def self.world
  end

  # Comment for attr_reader
  attr_reader :x

  # Comment for attr_accessor
  attr_accessor :y, :z

  # Comment for attr_writer
  attr_writer foo, :a
end
    EOR

    assert_write RB.parse(rb), <<-EOF
# Comments for class.
# This is a comment.
class Hello
  # Comment for include.
  include Foo

  # Comment for extend
  extend ::Bar

  # Comment for hello
  def hello: () -> nil

  # Comment for world
  def self.world: () -> nil

  # Comment for attr_reader
  attr_reader x: untyped

  # Comment for attr_accessor
  attr_accessor y: untyped

  # Comment for attr_accessor
  attr_accessor z: untyped

  # Comment for attr_writer
  attr_writer a: untyped
end
    EOF
  end

  def test_toplevel
    rb = <<-EOR
def hello
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Object
  def hello: () -> nil
end
    EOF
  end

  def test_const
    rb = <<-EOR
module Foo
  VERSION = '0.1.1'
  FROZEN = 'str'.freeze
  ::Hello::World = :foo
  self::MAX = 42
end
    EOR

    assert_write RB.parse(rb), <<-EOF
module Foo
  VERSION: "0.1.1"

  FROZEN: "str"

  ::Hello::World: :foo

  ::Foo::MAX: 42
end
    EOF
  end

  def test_const_with_multi_assign
    rb = <<-EOR
module Foo
  MAJOR, MINOR, PATCH = ['0', '1', '1']
end
    EOR

    assert_write RB.parse(rb), <<-EOF
module Foo
  MAJOR: untyped

  MINOR: untyped

  PATCH: untyped
end
    EOF
  end

  def test_const_with_multi_assign_ivar
    rb = <<~RUBY
      module Foo
        @major, @minor, @patch = ['0', '1', '1']
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      module Foo
        self.@major: untyped

        self.@minor: untyped

        self.@patch: untyped
      end
    RBS
  end

  def test_literal_types
    rb = <<-'EOR'
A = 1
B = 1.0
C = "hello#{21}"
D = :hello
E = nil
F = false
G = [1,2,3]
H = { id: 123 }
I = self
    EOR

    assert_write RB.parse(rb), <<-EOF
A: 1

B: ::Float

C: ::String

D: :hello

E: nil

F: false

G: ::Array[1 | 2 | 3]

H: { id: 123 }

I: untyped
    EOF
  end

  def test_invalid_byte_sequence_in_utf8
    rb = 'A = "\xff"'
    assert_write RB.parse(rb), "A: ::String\n"
  end

  def test_argumentless_call
    rb = <<-'EOR'
class C
  included do
    do_something
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class C
end
    EOF
  end

  def test_method_definition_in_call
    rb = <<-'EOR'
class C
  some_method_takes_method_name def foo
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class C
  def foo: () -> nil
end
    EOF
  end

  def test_multiple_nested_class
    rb = <<-'EOR'
module Foo
  class Bar
  end
end

module Foo
  class Baz
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
module Foo
  class Bar
  end
end

module Foo
  class Baz
  end
end
    EOF
  end

  def test_duplicate_methods
    rb = <<-'EOR'
class C
  def foo(x, y, z)
    do_something_27
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class C
  def foo: (untyped x, untyped y, untyped z) -> untyped
end
    EOF
  end

  def test_block_content
    rb = <<~'RUBY'
module M
  def not_refinements
  end

  refine Array do
    def by_refinements
    end
  end

  included do
    def in_included
    end
  end
end
    RUBY

    assert_write RB.parse(rb), <<~RBS
module M
  def not_refinements: () -> nil
end
    RBS
  end

  def test_calling_class_method_from_instance
    rb = <<~'RUBY'
class HelloWorld
  def self.world(str)
    str + 'world'
  end

  def hello
    self.class.world('hello')
  end
end
    RUBY

    assert_write RB.parse(rb), <<~RBS
class HelloWorld
  def self.world: (untyped str) -> untyped

  def hello: () -> untyped
end
    RBS
  end

  def test_instance_variables
    rb = <<-EOR
class Hello
  def message(message)
    # comment for ivar
    @message = message

    @a ||= 1
    @b &&= 2
    @c += 3
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  # comment for ivar
  @message: untyped

  @a: untyped

  @b: untyped

  @c: untyped

  def message: (untyped message) -> untyped
end
    EOF
  end

  def test_instance_variables_in_module
    rb = <<-EOR
module Hello
  def message(message)
    # comment for ivar
    @message = message
  end

  def foo
    @foo = 42
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
module Hello
  # comment for ivar
  @message: untyped

  @foo: untyped

  def message: (untyped message) -> untyped

  def foo: () -> untyped
end
    EOF
  end

  def test_instance_variable_in_receiver
    rb = <<~RUBY
      class Hello
        def options(options = {})
          (@options ||= { key: SecureRandom.hex }).merge!(options)
        end
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      class Hello
        @options: untyped

        def options: (?::Hash[untyped, untyped] options) -> untyped
      end
    RBS
  end

  def test_class_variables
    rb = <<-EOR
class Hello
  def self.foo
    @foo = 42
  end

  class << self
    @foobar = 42 # It should be ignored

    def bar
      @bar = 42
    end
  end

  @baz = 42

  def message(message)
    # comment for cvar
    @@message = message
  end
end
    EOR

    assert_write RB.parse(rb), <<-EOF
class Hello
  # comment for cvar
  @@message: untyped

  self.@foo: untyped

  self.@bar: untyped

  self.@baz: untyped

  def self.foo: () -> untyped

  def self.bar: () -> untyped

  def message: (untyped message) -> untyped
end
    EOF
  end

  def test_class_variables_conditional_assign
    rb = <<~RUBY
      class Hello
        @@foo &&= 1
        @@bar ||= 2
        @@baz += 3
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      class Hello
        @@foo: untyped

        @@bar: untyped

        @@baz: untyped
      end
    RBS
  end

  def test_literal_to_type
    visitor = RB::Visitor.new([])
    [
      [%{"abc"}, %{"abc"}],
      [%{"abc\#{d}"}, %{::String}],
      [%{`abc`}, %{::String}],
      [%{`abc\#{d}`}, %{::String}],
      [%{:abc}, %{:abc}],
      [%{:"abc\#{d}"}, %{::Symbol}],
      [%{/abc/}, %{::Regexp}],
      [%{/abc\#{d}/}, %{::Regexp}],
      [%{[]}, %{::Array[untyped]}],
      [%{[true]}, %{::Array[true]}],
      [%{[foo: true]}, %{::Array[{foo: true}]}],
      [%{1..2}, %{::Range[::Integer]}],
      [%{{}}, %{::Hash[untyped, untyped]}],
      [%{{a: nil}}, %{ { a: nil } }],
      [%({"a" => /b/}), %({ 'a' => ::Regexp })],
    ].each do |rb, rbs|
      node = Prism.parse(rb).value.statements.body[0]
      assert_equal RBS::Parser.parse_type(rbs), visitor.literal_to_type(node)
    end
  end

  def test_const_to_name
    visitor = RB::Visitor.new([])
    [
      ["self", RBS::TypeName.parse("::Foo")],
      ["Bar", RBS::TypeName.parse("Bar")],
      ["::Bar", RBS::TypeName.parse("::Bar")],
      ["Bar::Baz", RBS::TypeName.parse("Bar::Baz")],
      ["obj::Baz", nil],
    ].each do |rb, name|
      node = Prism.parse(rb).value.statements.body[0]
      context = RBS::Prototype::RB::Context.initial(namespace: RBS::Namespace.new(path: [:Foo], absolute: true))
      assert_equal name, visitor.const_to_name(node, context: context)
    end
  end

  def test_argument_forwarding
    rb = <<~'RUBY'
      module M
        def block_unused(...) end

        def block_optional(...)
          yield 1 if block_given?
        end
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
        module M
          def block_unused: (*untyped, **untyped) ?{ (?) -> untyped } -> nil

          def block_optional: (*untyped, **untyped) ?{ (untyped) -> untyped } -> (untyped | nil)
        end
      RBS
  end

  def test_endless_method_definition
    rb = <<~'RUBY'
module M
  def foo = 42
end
    RUBY

    assert_write RB.parse(rb), <<~RBS
module M
  def foo: () -> 42
end
    RBS
  end

  def test_ignores_anonymous_modules
    rb = <<~RUBY
      Module.new do
        def hook(name, path)
          super
        end
      end
    RUBY

    assert_write RB.parse(rb), ''
  end

  def test_anonymous_block
    rb = <<~RUBY
      module M
        def block_optional(&)
          yield if block_given?
        end

        def block_required(&)
          yield
        end

        def block_unused(&)
        end
      end
    RUBY

    assert_write RB.parse(rb), <<~RBS
      module M
        def block_optional: () ?{ () -> untyped } -> (untyped | nil)

        def block_required: () { () -> untyped } -> untyped

        def block_unused: () { (?) -> untyped } -> nil
      end
    RBS
  end
end
