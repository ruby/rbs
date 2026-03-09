require "test_helper"

class RBS::InlineTypeFingerprintTest < Test::Unit::TestCase
  include TestHelper

  def fingerprint(src)
    buffer = RBS::Buffer.new(name: Pathname("test.rb"), content: src)

    prism = Prism.parse(src)
    RBS::InlineParser.parse(buffer, prism).type_fingerprint
  end

  def test_class_decl_fingerprint
    result = fingerprint(<<-RUBY)
class Foo
end

module Bar
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo; end
module Bar; end
    RUBY

    result3 = fingerprint(<<-RUBY)
module Foo; end
class Bar; end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_class_with_superclass_fingerprint
    result = fingerprint(<<-RUBY)
class Foo < Bar
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo < Bar; end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo < Bar1
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_class_with_type_args_fingerprint
    result = fingerprint(<<-RUBY)
class Foo < Bar #[String]
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo < Bar    #[ String ]
end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo < Bar    #[ str ]
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_method_fingerprint_changes_with_type
    result = fingerprint(<<-RUBY)
class Foo
  # @rbs return:    String
  def bar
  end
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  # @rbs return: String
  def bar
  end
end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo
  def bar
  end
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_method_fingerprint_same_with_impl_change
    result = fingerprint(<<-RUBY)
class Foo
  # @rbs return: String
  def bar
    "hello"
  end
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  # @rbs return: String
  def bar
    "world"
  end
end
    RUBY

    assert_equal result, result2
  end

  def test_method_with_overloads_fingerprint
    result = fingerprint(<<-RUBY)
class Foo
  # : () -> String
  # : (Integer) -> Integer
  def bar(x = nil)
  end
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  # : () -> String
  # : (Integer) -> Integer
  def bar(x = nil); end
end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo
  # : (Integer) -> Integer
  # : () -> String
  def bar(x = nil); end
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_mixin_fingerprint
    result = fingerprint(<<-RUBY)
module Foo
  include Bar
  extend Baz
  prepend Qux
end
    RUBY

    result2 = fingerprint(<<-RUBY)
module Foo
  include Bar; extend Baz; prepend Qux
end
    RUBY

    result3 = fingerprint(<<-RUBY)
module Foo
  prepend Qux
  extend Baz
  include Bar
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_mixin_with_type_args_fingerprint
    result = fingerprint(<<-RUBY)
module Foo
  include Bar #[String, Integer]
end
    RUBY

    result2 = fingerprint(<<-RUBY)
module Foo
  include Bar #[  String,   Integer  ]
end
    RUBY

    assert_equal result, result2
  end

  def test_attribute_fingerprint
    result = fingerprint(<<-RUBY)
class Foo
  attr_reader :name #: String

  attr_writer :age

  attr_accessor :active #: bool
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  attr_reader :name #: String
  attr_writer :age
  attr_accessor :active  #: bool
end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo
  attr_reader :name1 #: String
  attr_writer :age
  attr_accessor :active  #: bool
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_instance_variable_fingerprint
    result = fingerprint(<<-RUBY)
class Foo
  # @rbs @name: String
  # @rbs @age: Integer

  def initialize
    @name = ""
    @age = 0
  end
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  # @rbs @name: String

  # @rbs @age: Integer

  def initialize
    @name = ""; @age = 0
  end
end
    RUBY

    assert_equal result, result2
  end

  def test_constant_fingerprint
    result = fingerprint(<<-RUBY)
class Foo
  VERSION = "1.0.0"
  MAX_SIZE = 100
end
    RUBY

    result2 = fingerprint(<<-RUBY)
class Foo
  VERSION = "1.0.1"

  MAX_SIZE = 100
end
    RUBY

    result3 = fingerprint(<<-RUBY)
class Foo
  VERSION = "1.0.1" #: String

  MAX_SIZE = 100 #: untyped
end
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end

  def test_class_alias_fingerprint
    result = fingerprint(<<-RUBY)
NewName = OldName #: class-alias
    RUBY

    result2 = fingerprint(<<-RUBY)
NewName =
  OldName #: class-alias
    RUBY

    result3 = fingerprint(<<-RUBY)
NewName = ::OldName #: class-alias
    RUBY

    assert_equal result, result2
    refute_equal result, result3
  end
end
