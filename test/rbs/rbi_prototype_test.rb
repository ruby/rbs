require "test_helper"

class RBS::RbiPrototypeTest < Test::Unit::TestCase
  omit_on_truffle_ruby! "`RubyVM::AbstractSyntaxTree` is not available on TruffleRuby"
  omit_on_jruby! "`RubyVM::AbstractSyntaxTree` is not available on JRuby"

  RBI = RBS::Prototype::RBI

  include TestHelper

  def test_1
    parser = RBI.new

    rbi = <<-EOR
class Array < Object
  include Enumerable

  extend T::Generic
  Elem = type_member(:out)

  sig do
    type_parameters(:U).params(
        arg0: T.type_parameter(:U),
        foo: String,
        bar: Integer,
        baz: Object,
        blk: T.proc.params(arg0: Elem).returns(BasicObject)
    )
    .returns(T::Array[T.type_parameter(:U)])
  end
  def self.[](*arg0, foo:, bar: 1, **baz, &blk); end
end
    EOR

    parser.parse(rbi)

    parser.decls

    # decls = parser.decls
    # pp parser.decls
  end

  def test_module
    parser = RBI.new

    rbi = <<-EOR
module Foo
end
EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
module Foo
end
    EOF
  end

  def test_nested_module
    parser = RBI.new

    rbi = <<-EOR
module Foo
  module Bar
  end
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
module Foo
  module Bar
  end
end
    EOF
  end

  def test_nested_module2
    parser = RBI.new

    rbi = <<-EOR
module Foo
  module ::Bar
  end
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
module Foo
  module ::Bar
  end
end
    EOF
  end

  def test_constant
    parser = RBI.new

    rbi = <<-EOR
module Foo
  ABBR_DAYNAMES = T.let(T.unsafe(nil), Array)
  ABBR_MONTHNAMES = T.let(T.unsafe(nil), Integer)
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
module Foo
  ABBR_DAYNAMES: Array

  ABBR_MONTHNAMES: Integer
end
    EOF
  end

  def test_alias
    parser = RBI.new

    rbi = <<-EOR
module Foo
  alias_method(:foo, :Bar)
  alias hello world
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
module Foo
  alias foo Bar

  alias hello world
end
    EOF
  end

  def test_block_args
    parser = RBI.new

    rbi = <<-EOR
class Hello
  sig do
    type_parameters(:U).params(
        arg0: T.type_parameter(:U),
        blk: T.proc.params(arg0: Elem).returns(BasicObject)
    )
    .returns(T::Array[T.type_parameter(:U)])
  end
  def hello(arg0, &blk); end
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
class Hello
  def hello: [U] (U arg0) { (Elem arg0) -> untyped } -> ::Array[U]
end
    EOF
  end

  def test_untyped_block
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig { params(blk: T.untyped).void }
  def self.split(&blk); end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: () { () -> untyped } -> void
end
    EOF
  end

  def test_implicit_block
    parser = RBI.new

    rbi = <<-EOR
class Hello
  sig do
    params(arg0: String).void
  end
  def hello(arg0, &blk); end
end
    EOR

    parser.parse(rbi)

    assert_write parser.decls, <<-EOF
class Hello
  def hello: (String arg0) ?{ () -> untyped } -> void
end
    EOF
  end

  def test_optional_block
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig { params(blk: T.nilable(T.proc.void)).void }
  def self.split(&blk); end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: () ?{ () -> void } -> void
end
    EOF
  end

  def test_overloading
    parser = RBI.new

    parser.parse(<<-EOF)
class Class
  sig {void}
  sig do
    params(
        superclass: Class,
    )
    .void
  end
  sig do
    params(
        blk: T.proc.params(arg0: Class).returns(BasicObject),
    )
    .void
  end
  sig do
    params(
        superclass: Class,
        blk: T.proc.params(arg0: Class).returns(BasicObject),
    )
    .void
  end
  def initialize(superclass=_, &blk); end
end
    EOF

    # Maybe, the argument `superclass` does not look like an optional parameter, but cannot detect if it is required or optional.
    assert_write parser.decls, <<-EOF
class Class
  def initialize: () -> void
                | (?Class superclass) -> void
                | () { (Class arg0) -> untyped } -> void
                | (?Class superclass) { (Class arg0) -> untyped } -> void
end
    EOF
  end

  def test_tuple
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig do
    params(
        file: String,
    )
    .returns([String, String])
  end
  def self.split(file); end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: (String file) -> [ String, String ]
end
    EOF
  end

  def test_all
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig do
    params(
        file: T.all(String, Integer),
    )
    .void
  end
  def self.split(file); end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: (String & Integer file) -> void
end
    EOF
  end

  def test_self_type
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig { returns(T.self_type) }
  def self.split; end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: () -> self
end
    EOF
  end

  def test_colon
    parser = RBI.new

    parser.parse(<<-EOF)
class Test
  sig { returns(Foo) }
  def m1; end

  sig { returns(::Foo) }
  def m2; end

  sig { returns(Foo::Bar) }
  def m3; end

  sig { returns(::Foo::Bar) }
  def m4; end
end
    EOF

    assert_write parser.decls, <<-EOF
class Test
  def m1: () -> Foo

  def m2: () -> ::Foo

  def m3: () -> Foo::Bar

  def m4: () -> ::Foo::Bar
end
    EOF
  end

  def test_attached_class
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig { returns(T.attached_class) }
  def self.split; end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: () -> instance
end
    EOF
  end

  def test_noreturn
    parser = RBI.new

    parser.parse(<<-EOF)
class File
  sig do
    params(
        file: T.all(String, Integer),
    )
    .returns(T.noreturn)
  end
  def self.split(file); end
end
    EOF

    assert_write parser.decls, <<-EOF
class File
  def self.split: (String & Integer file) -> bot
end
    EOF
  end

  def test_class_of
    parser = RBI.new

    parser.parse(<<-EOF)
class Foo
  sig do
    returns(T.class_of(String))
  end
  def foo; end
end
    EOF

    assert_write parser.decls, <<-EOF
class Foo
  def foo: () -> singleton(String)
end
    EOF
  end

  def test_parameter
    parser = RBI.new

    parser.parse <<-EOF
class Array
  include Enumerable

  extend T::Generic
  Elem = type_member(:out)
end
    EOF

    assert_write parser.decls, <<-EOF
class Array[out Elem]
  include Enumerable
end
    EOF
  end

  def test_basic_object
    parser = RBI.new

    parser.parse <<-EOF
class Foo
  sig { returns(BasicObject) }
  def hello; end
end
    EOF

    assert_write parser.decls, <<-EOF
class Foo
  def hello: () -> untyped
end
    EOF
  end

  def test_bool
    parser = RBI.new

    parser.parse <<-EOF
class Foo
  sig { returns(T::Boolean) }
  def hello; end
end
    EOF

    assert_write parser.decls, <<-EOF
class Foo
  def hello: () -> bool
end
    EOF
  end

  def test_comment
    parser = RBI.new

    parser.parse <<-EOF
# This is a class.
#
#   It is super useful.
class Foo
  # This is useful method.
  sig { void }
  # Another comment.
  sig { returns(Integer) }
  def foo; end
end

# This is a module
module Bar

  # This is singleton method.
  sig { void }
  def self.foo; end
end
    EOF

    assert_write parser.decls, <<-EOF
# This is a class.
#
#   It is super useful.
class Foo
  # This is useful method.
  #
  # Another comment.
  def foo: () -> void
         | () -> Integer
end

# This is a module
module Bar
  # This is singleton method.
  def self.foo: () -> void
end
    EOF
  end

  def test_non_parameter_type_member
    parser = RBI.new

    parser.parse <<-EOF
class Dir
  extend T::Generic

  Elem = type_member(:out, fixed: String)
  include Enumerable
end
    EOF

    assert_write parser.decls, <<-EOF
class Dir
  include Enumerable
end
    EOF
  end

  def test_parameter_type_member_variance
    parser = RBI.new

    parser.parse <<-EOF
class Dir
  extend T::Generic

  X = type_member(:out)
  Y = type_member(:in)
  Z = type_member()

  include Enumerable
end
    EOF

    assert_write parser.decls, <<-EOF
class Dir[out X, in Y, Z]
  include Enumerable
end
    EOF
  end

  def test_nested_declarations_preserve_lexical_resolution
    parser = RBI.new

    parser.parse <<-EOF
module Demo
  class Parent; end
  module Helpers; end
  class Value; end

  class Child < Parent
    include Helpers

    sig { params(value: Value).returns(Value) }
    def convert(value); end
  end
end
    EOF

    assert_write parser.decls, <<-EOF
module Demo
  class Parent
  end

  module Helpers
  end

  class Value
  end

  class Child < Parent
    include Helpers

    def convert: (Value value) -> Value
  end
end
    EOF
  end

  def test_nested_constant
    parser = RBI.new

    parser.parse <<-EOF
module Demo
  module Modes
    VALUE = T.let(:value, Symbol)
  end
end
    EOF

    assert_write parser.decls, <<-EOF
module Demo
  module Modes
    VALUE: Symbol
  end
end
    EOF
  end

  def test_ignores_t_helpers
    parser = RBI.new

    parser.parse <<-EOF
module Factory
  extend T::Helpers
  extend OtherHelpers
end
    EOF

    assert_write parser.decls, <<-EOF
module Factory
  extend OtherHelpers
end
    EOF
  end

  def test_t_class_falls_back_to_untyped
    parser = RBI.new

    parser.parse <<-EOF
module Factory
  sig do
    type_parameters(:Config)
      .params(config_class: T::Class[T.type_parameter(:Config)])
      .returns(T.type_parameter(:Config))
  end
  def make(config_class); end
end
    EOF

    assert_write parser.decls, <<-EOF
module Factory
  def make: [Config] (untyped config_class) -> Config
end
    EOF
  end

  def test_singleton_class_method
    parser = RBI.new

    parser.parse <<-EOF
class Registry
  class << self
    sig { returns(T.attached_class) }
    def build; end
  end
end
    EOF

    assert_write parser.decls, <<-EOF
class Registry
  def self.build: () -> instance
end
    EOF
  end

  def test_typed_attribute_consumes_signature
    parser = RBI.new

    parser.parse <<-EOF
class Cache
  sig { returns(T.nilable(Integer)) }
  attr_reader :size

  sig { returns(String) }
  attr_accessor :name

  sig { params(value: Integer).void }
  attr_writer :count

  sig { params(size: T.nilable(Integer)).void }
  def initialize(size: nil); end
end
    EOF

    assert_write parser.decls, <<-EOF
class Cache
  attr_reader size: Integer?

  attr_accessor name: String

  attr_writer count: Integer

  def initialize: (?size: Integer? size) -> void
end
    EOF
  end

  def test_method_visibility
    parser = RBI.new

    parser.parse <<-EOF
module Factory
  private

  sig { void }
  def helper; end

  public

  sig { void }
  def make; end
end
    EOF

    assert_write parser.decls, <<-EOF
module Factory
  private

  def helper: () -> void

  public

  def make: () -> void
end
    EOF
  end

  def test_generated_reproduction_can_be_loaded
    parser = RBI.new

    parser.parse <<-EOF
module Demo
  class Parent; end
  module Helpers; end

  class Child < Parent
    include Helpers
  end

  module Modes
    VALUE = T.let(:value, Symbol)
  end

  class Registry
    class << self
      sig { returns(T.attached_class) }
      def build; end
    end
  end

  class Cache
    sig { returns(T.nilable(Integer)) }
    attr_reader :size

    sig { params(size: T.nilable(Integer)).void }
    def initialize(size: nil); end
  end

  module Factory
    extend T::Helpers

    sig do
      type_parameters(:Config)
        .params(config_class: T::Class[T.type_parameter(:Config)])
        .returns(T.type_parameter(:Config))
    end
    def make(config_class); end

    private

    sig { void }
    def helper; end
  end
end
    EOF

    out = StringIO.new
    RBS::Writer.new(out: out).write(parser.decls)
    refute_match(/\bT::/, out.string)

    SignatureManager.new do |manager|
      manager.add_file("repro.rbs", out.string)
      manager.build do |env|
        builder = RBS::DefinitionBuilder.new(env: env)

        ["::Demo::Child", "::Demo::Registry", "::Demo::Cache", "::Demo::Factory"].each do |name|
          builder.build_instance(type_name(name))
          builder.build_singleton(type_name(name))
        end

        assert_include env.constant_decls.keys, type_name("::Demo::Modes::VALUE")
      end
    end
  end

  def test_masgn
    parser = RBI.new

    parser.parse <<-EOF
class Test
  A, B, C = [1, 2, 3]
end
    EOF

    assert_write parser.decls, <<-EOF
class Test
  A: untyped

  B: untyped

  C: untyped
end
    EOF
  end
end
