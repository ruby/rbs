require_relative "test_helper"

require "securerandom"

class KernelSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::Kernel)"

  def test_Array
    assert_send_type "(nil) -> []",
                     Kernel, :Array, nil

    with_array(1r, 2r).chain([ToA.new(1r,2r)]).each do |ary|
      assert_send_type "(::array[Rational] | ::_ToA[Rational]) -> Array[Rational]",
                       Kernel, :Array, ary
    end

    assert_send_type "(Rational) -> [Rational]",
                     Kernel, :Array, 1r
  end

  def test_Float
    with_float 1.0 do |float|
      assert_send_type "(::float) -> Float",
                       Kernel, :Float, float
      assert_send_type "(::float, exception: true) -> Float",
                       Kernel, :Float, float, exception: true
      assert_send_type "(::float, exception: bool) -> Float?",
                       Kernel, :Float, float, exception: false
    end

    assert_send_type "(untyped, ?exception: bool) -> Float?",
                     Kernel, :Float, :hello, exception: false
  end

  def test_Hash
    assert_send_type "(nil) -> Hash[untyped, untyped]",
                     Kernel, :Hash, nil
    assert_send_type "([]) -> Hash[untyped, untyped]",
                     Kernel, :Hash, []

    with_hash 'a' => 3 do |hash|
      assert_send_type "(::hash[String, Integer]) -> Hash[String, Integer]",
                       Kernel, :Hash, hash
    end
  end

  def test_Integer
    with_int(1).chain([ToI.new(1)]).each do |int|
      assert_send_type "(::int | ::_ToI) -> Integer",
                       Kernel, :Integer, int
      assert_send_type "(::int | ::_ToI, exception: true) -> Integer",
                       Kernel, :Integer, int, exception: true
      assert_send_type "(::int | ::_ToI, exception: bool) -> Integer?",
                       Kernel, :Integer, int, exception: false
    end

    with_string "123" do |string|
      with_int 8 do |base|
        assert_send_type "(::string, ::int) -> Integer",
                         Kernel, :Integer, string, base
        assert_send_type "(::string, ::int, exception: true) -> Integer",
                         Kernel, :Integer, string, base, exception: true
        assert_send_type "(::string, ::int, exception: bool) -> Integer?",
                         Kernel, :Integer, string, base, exception: false
      end
    end

    assert_send_type "(untyped, ?exception: bool) -> Integer?",
                     Kernel, :Integer, :hello, exception: false
  end


  def test_String
    with_string do |string|
      assert_send_type "(::string) -> String",
                       Kernel, :String, string
    end

    assert_send_type "(::_ToS) -> String",
                     Kernel, :String, ToS.new
  end

  def test_autoload?
    with_interned :TestModuleForAutoload do |interned|
      assert_send_type "(::interned) -> String?",
                       Kernel, :autoload?, interned
    end

    autoload :TestModuleForAutoload, '/shouldnt/be/executed'

    with_interned :TestModuleForAutoload do |interned|
      assert_send_type "(::interned) -> String?",
                       Kernel, :autoload?, interned
    end
  end
end

class KernelTest < StdlibTest
  target Kernel
  discard_output

  def test_caller
    caller(1, 2)
    caller(1)
    caller(1..2)
    caller
  end

  def test_caller_locations
    caller_locations(1, 2)
    caller_locations(1)
    caller_locations(1..2)
    caller_locations
  end

  def test_catch_throw
    catch do |tag|
      throw tag
    end

    catch("tag") do |tag|
      throw tag
    end
  end

  def test_class
    Object.new.class
  end

  def test_eval
    eval "p"
    eval "p", binding, "fname", 1
  end

  def test_block_given?
    block_given?
  end

  def test_local_variables
    _ = x = 1
    local_variables
  end

  def test_srand
    srand
    srand(10)
    srand(10.5)
  end

  def test_not_tilde
    return if RUBY_VERSION >= "3.2.0"

    Object.new !~ Object.new
  end

  def test_spaceship
    Object.new <=> Object.new
  end

  def test_eqeqeq
    Object.new === Object.new
  end

  def test_clone
    Object.new.clone
    Object.new.clone(freeze: false)
  end

  def test_display
    1.display
    1.display($stderr)

    stdout = STDOUT.dup
    STDOUT.reopen(IO::NULL)
    Object.new.display()
    Object.new.display(STDOUT)
    Object.new.display(StringIO.new)
  ensure
    STDOUT.reopen(stdout)
  end

  def test_dup
    1.dup
  end

  def each(*args)

  end

  def test_enum_for
    enum_for :then

    enum_for :each, 1
    enum_for(:each, 1) { 2 }

    obj = Object.new

    obj.enum_for(:instance_exec)
    obj.enum_for(:instance_exec, 1,2,3)
    obj.enum_for(:instance_exec, 1,2,3) { |x,y,z| x + y + z }

    obj.to_enum(:instance_exec)
    obj.to_enum(:instance_exec, 1, 2, 3)
    obj.to_enum(:instance_exec, 1, 2, 3) { |x, y, z| x + y + z }
  end

  def test_eql?
    Object.new.eql? 1
  end

  def test_extend
    Object.new.extend Module.new
    Object.new.extend Module.new, Module.new
  end

  def test_fork
    if Process.respond_to?(:fork)
      exit! unless fork
      fork { exit! }
    end
  end

  def test_freeze
    Object.new.freeze
  end

  def test_frozen?
    Object.new.frozen?
  end

  def test_hash
    Object.new.hash
  end

  def test_initialize_copy
    Object.new.instance_eval do
      initialize_copy(Object.new)
    end
  end

  def test_inspect
    Object.new.inspect
  end

  def test_instance_of?
    Object.new.instance_of? String
  end

  def test_instance_variable_defined?
    Object.new.instance_variable_defined?('@foo')
    Object.new.instance_variable_defined?(:@bar)
  end

  def test_instance_variable_get
    Object.new.instance_variable_get('@foo')
    Object.new.instance_variable_get(:@bar)
  end

  def test_instance_variable_set
    Object.new.instance_variable_set('@foo', 1)
    Object.new.instance_variable_set(:@bar, 2)
  end

  def test_instance_variables
    obj = Object.new
    obj.instance_eval do
      @foo = 1
    end
    obj.instance_variables
  end

  def test_is_a?
    Object.new.is_a? String
    Object.new.kind_of? Enumerable
  end

  def test_method
    Object.new.method(:tap)
    Object.new.method('yield_self')
  end

  def test_methods
    Object.new.methods
    Object.new.methods true
    Object.new.methods false
  end

  def test_nil?
    Object.new.nil?
  end

  def test_private_methods
    Object.new.private_methods
    Object.new.private_methods true
    Object.new.private_methods false
  end

  def test_protected_methods
    Object.new.protected_methods
    Object.new.protected_methods true
    Object.new.protected_methods false
  end

  def test_public_method
    Object.new.public_method(:tap)
    Object.new.public_method('yield_self')
  end

  def test_public_methods
    Object.new.public_methods
    Object.new.public_methods true
    Object.new.public_methods false
  end

  def test_public_send
    Object.new.public_send(:inspect)
    Object.new.public_send('inspect')
    Object.new.public_send(:public_send, :inspect)
    Object.new.public_send(:tap) { 1 }
    Object.new.public_send(:tap) { |this| this }
  end

  def test_remove_instance_variable
    obj = Object.new
    obj.instance_eval do
      @foo = 1
      @bar = 2
    end

    obj.remove_instance_variable(:@foo)
    obj.remove_instance_variable('@bar')
  end

  def test_send
    Object.new.send(:inspect)
    Object.new.send('inspect')
    Object.new.send(:public_send, :inspect)
    Object.new.send(:tap) { 1 }
    Object.new.send(:tap) { |this| this }
  end

  def test_singleton_class
    Object.new.singleton_class
  end

  def test_singleton_method
    o = Object.new
    def o.x
    end
    o.singleton_method :x
    o.singleton_method 'x'
  end

  def test_singleton_methods
    o = Object.new
    def o.x
    end
    o.singleton_methods
  end

  if Kernel.method_defined?(:taint)
    def test_taint
      Object.new.taint
      Object.new.untrust
    end

    def test_tainted?
      Object.new.tainted?
      Object.new.untrusted?
    end
  end

  def test_tap
    Object.new.tap do |this|
      this
    end
  end

  def test_to_s
    Object.new.to_s
  end

  if Kernel.method_defined?(:taint)
    def test_untaint
      Object.new.untaint
      Object.new.trust
    end
  end

  def test_Array
    Array(nil)

    # We add the `.first.whatever` tests to make sure that we're being returned the right type.
    Array([1,2,3]).first.even?
    Array(ToArray.new(1,2)).first.even?
    Array(ToA.new(1,2)).first.even?
    Array(1..4).first.even?
    Array({34 => 'hello'}).first.first.even?

    Array('foo').first.upcase
    Array(['foo']).first.upcase
  end

  def test_Complex
    Complex(1.3).real?
    Complex(1.3, exception: true).real?
    Complex(1.3, exception: false)&.real?
    Complex(1.3, exception: $VERBOSE)&.real? # `$VERBOSE` is an undecidable-at-compile-time bool.

    Complex('1+2i')
    Complex(1r)
    Complex(Class.new(Numeric).new)

    # The `Kernel#Complex` function is the only place in the entire stdlib that uses `.to_c`
    def (obj = BasicObject.new).to_c
      1+3i
    end
    Complex(obj)

    Complex(1.3, '1i')
    Complex(Class.new(Numeric).new, "1")
  end

  def test_Float
    Float(42).infinite?
    Float(42, exception: true).real?
    Float(42, exception: false)&.real?
    Float(42, exception: $VERBOSE)&.real? # `$VERBOSE` is an undecidable-at-compile-time bool.

    Float(1.4)
    Float('1.4')
    Float(ToF.new)
  end

  def test_Hash
    Hash(nil)
    Hash([])

    Hash({key: 1})
    Hash(ToHash.new)
  end

  def test_Integer
    Integer(42).even?
    Integer(42, exception: true).even?
    Integer(42, exception: false)&.even?
    Integer(42, exception: $VERBOSE)&.even? # `$VERBOSE` is an undecidable-at-compile-time bool.

    Integer(2.3)
    Integer(ToInt.new)
    Integer(ToI.new)

    Integer('2').even?
    Integer('2', exception: true).even?
    Integer('2', exception: false)&.even?
    Integer('2', exception: $VERBOSE)&.even? # `$VERBOSE` is an undecidable-at-compile-time bool.

    Integer('11', 2)
    Integer(ToStr.new('11'), ToInt.new(12))
  end

  # These two classes are required to for `test_Rational`, and the `Class.new(Numeric)` construct
  # doesn't type check them properly (yet.)
  class Rational_RationalDiv < Numeric
    def /(numeric) "Hello!" end
  end
  class Rational_OneCase < Numeric
    def __unique_method_name__; 34 end
  end

  def test_Rational
    Rational(42).integer?
    Rational(42, exception: true).integer?
    Rational(42, exception: false)&.integer?
    Rational(42, exception: $VERBOSE)&.integer? # `$VERBOSE` is an undecidable-at-compile-time bool.

    def (test_rational = BasicObject.new).to_r
      1r
    end

    Rational(ToInt.new)
    Rational(test_rational)

    Rational(42.0, 3)
    Rational('42.0', 3, exception: true)
    Rational(ToInt.new, test_rational)
    Rational(test_rational, ToInt.new, exception: false)

    rational_div = Rational_RationalDiv.new
    # `Rational` ignores `exception:` in the `_RationalDiv` variant.
    Rational(rational_div, Class.new(Numeric).new).upcase
    Rational(rational_div, Class.new(Numeric).new, exception: true).upcase
    Rational(rational_div, Class.new(Numeric).new, exception: false).upcase
    Rational(rational_div, Class.new(Numeric).new, exception: $VERBOSE).upcase

    one_case = Rational_OneCase.new
    # `Rational` also ignores `exception:` in the `(Numeric, 1)` variant.
    Rational(one_case, 1).__unique_method_name__
    Rational(one_case, 1, exception: true).__unique_method_name__
    Rational(one_case, 1, exception: false).__unique_method_name__
    Rational(one_case, 1, exception: $VERBOSE).__unique_method_name__
  end

  def test_String
    String('foo')
    String([])
    String(nil)

    String(ToS.new)
    String(ToStr.new)
  end

  def test___callee__
    __callee__
  end

  def test___dir__
    __dir__
  end

  def test___method__
    __method__
  end

  def test_backtick
    `echo 1`
  end

  def test_abort
    begin
      abort
    rescue SystemExit
    end

    begin
      abort 'foo'
    rescue SystemExit
    end

    begin
      abort ToStr.new
    rescue SystemExit
    end
  end

  def test_at_exit
    at_exit { 'foo' }
  end

  def test_autoload
    autoload 'FooBar', 'fname'
    autoload :FooBar, 'fname'
  end

  def test_autoload?
    autoload? 'FooBar'
    autoload? :FooBarBaz
  end

  def test_binding
    binding
  end

  def test_exit
    begin
      exit
    rescue SystemExit
    end

    begin
      exit 1
    rescue SystemExit
    end

    begin
      exit ToInt.new
    rescue SystemExit
    end

    begin
      exit true
    rescue SystemExit
    end

    begin
      exit false
    rescue SystemExit
    end
  end

  def test_exit!
    # TODO
  end

  def test_fail
    begin
      fail
    rescue RuntimeError
    end

    begin
      fail 'error'
    rescue RuntimeError
    end

    begin
      fail 'error', cause: nil
    rescue RuntimeError
    end

    begin
      fail 'error', cause: RuntimeError.new("oops!")
    rescue RuntimeError
    end

    test_error = Class.new(StandardError)
    begin
      fail test_error
    rescue test_error
    end

    begin
      fail test_error, 'a'
    rescue test_error
    end

    begin
      fail test_error, ToS.new, ['1.rb, 2.rb']
    rescue test_error
    end

    begin
      fail test_error, 'b', '1.rb'
    rescue test_error
    end

    begin
      fail test_error, 'b', nil
    rescue test_error
    end

    begin
      fail test_error, 'b', cause: RuntimeError.new("?")
    rescue test_error
    end

    begin
      fail test_error, 'b', cause: nil
    rescue test_error
    end

    begin
      fail test_error.new('a')
    rescue test_error
    end

    begin
      fail test_error.new('a'), foo: 1, bar: 2, baz: 3, cause: RuntimeError.new("?")
    rescue test_error
    end

    exception_container = Class.new do
      define_method :exception do |arg = 'a'|
        test_error.new(arg)
      end
    end

    begin
      fail exception_container.new
    rescue test_error
    end

    begin
      fail exception_container.new, 14
    rescue test_error
    end
  end

  def test_format
    format 'x'
    format '%d', 1
    sprintf '%d%s', 1, 2
  end

  def test_gets
    # TODO
  end

  def test_global_variables
    global_variables
  end

  def test_load
    Dir.mktmpdir do |dir|
      path = File.join(dir, "foo.rb")

      File.write(path, "class Foo; end")

      load(path)
      load(path, true)
      load(path, false)
      load(path, Module.new)
    end
  end

  def test_loop
    loop { break }
    loop
  end

  def test_open
    open(File.expand_path(__FILE__)).close
    open(File.expand_path(__FILE__), 'r').close
    open(File.expand_path(__FILE__)) do |f|
      f.read
    end
  end

  def test_print
    print
    print 1
    print 'a', 2
    print ToS.new
  end

  def test_printf
    File.open('/dev/null', 'w') do |io|
      printf io, 'a'
      printf io, '%d', 2
    end

    printf
    printf "123"
    printf "%s%d%f", "A", 2, 3.0

    def (writer = Object.new).write(*) end
    printf writer, ToStr.new("%s%d"), '1', 2
  end

  def test_proc
    proc {}
  end

  def test_lambda
    lambda {}
  end

  def test_putc
    putc 1
    putc 'a'
    putc ToInt.new
  end

  def test_puts
    puts
    puts 1, nil, false, "yes!", ToS.new
  end

  def test_p
    p
    p 1
    p 'a', 2

    def (obj = BasicObject.new).inspect
      "foo"
    end

    p obj
  end

  def test_pp
    pp
    pp 1
    pp 'a', 2

    pp Object.new
  end

  def test_rand
    rand
    rand(10)
    rand(1..10)
    rand(1.0..10.0)
  end

  def test_readline
    # TODO
  end

  def test_readlines
    # TODO
  end

  def test_require
    # TODO
  end

  def test_require_relative
    # TODO
  end

  def test_select
    # TODO
  end

  def test_sleep
    sleep 0

    sleep 0.01

    o = Object.new
    def o.divmod(i)
      [0.001, 0.001]
    end
    sleep o
  end

  def test_syscall
    # TODO
  end

  def test_test
    test ?r, File.expand_path(__FILE__)
    test ?r.ord, File.expand_path(__FILE__)
    test ?s, File.expand_path(__FILE__)

    File.open(File.expand_path(__FILE__)) do |f|
      test ?r, f
      test ?=, f, f
    end
  end

  def test_warn
    warn
    warn 'foo'
    warn 'foo', 'bar'
    warn 'foo', uplevel: 1
    warn ToS.new, uplevel: ToInt.new
    warn ToS.new, uplevel: nil

    omit_if(RUBY_VERSION < "3.0")

    warn 'foo', uplevel: 1, category: :deprecated
    warn 'foo', uplevel: 1, category: nil
  end

  def test_exec
    # TODO
  end

  def test_system
    # TODO
  end

  def test_operators
    if RUBY_VERSION < "3.2.0"
      Object.new !~ 123
    end

    Object.new <=> 123
    Object.new <=> Object.new

    Object.new === false
  end

  def test_eql
    Object.new.eql?(1)
  end

  def test_frozen
    Object.new.frozen?
  end

  def test_itself
    Object.new.itself
  end

  def test_kind_of?
    Object.new.kind_of?(String)
  end

  def test_object_id
    Object.new.object_id
  end

  def test_respond_to?
    obj = Object.new

    obj.respond_to?(:to_s)
    obj.respond_to?('to_s')
    obj.respond_to?('to_s', true)
  end

  if Kernel.method_defined?(:taint)
    def test_taint
      obj = Object.new

      obj.taint
      obj.tainted?
      obj.untaint
    end
  end

  def test_yield_self
    obj = Object.new

    obj.yield_self { }
    obj.then { }
  end
end

class KernelInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::Kernel"

  def test_define_singleton_method
    obj = Object.new

    assert_send_type(
      "(::Symbol) { () -> void } -> Symbol",
      obj, :define_singleton_method,
      :foo
    ) do end

    assert_send_type(
      "(::Symbol, ::Proc) -> Symbol",
      obj, :define_singleton_method,
      :bar,
      -> {}
    )

    assert_send_type(
      "(::Symbol, ::Method) -> Symbol",
      obj, :define_singleton_method,
      :bar,
      obj.method(:to_s)
    )

    assert_send_type(
      "(::Symbol, ::UnboundMethod) -> Symbol",
      obj, :define_singleton_method,
      :bar,
      Object.instance_method(:to_s)
    )
  end

  def test_respond_to_missing?
    obj = Object.new

    # The default implementation always returns `false` regardless of the args,
    # let alone their types; though overrides only have to support Symbol + bool
    assert_send_type(
      "(::Symbol, bool) -> bool",
      obj, :respond_to_missing?, :to_s, true
    )
  end

  def test_pp
    original_stdout = $stdout
    $stdout = StringIO.new

    assert_send_type "() -> nil",
                     self, :pp
    assert_send_type "(123) -> 123",
                     self, :pp, 123
    assert_send_type "(123, :foo) -> [123, :foo]",
                     self, :pp, 123, :foo
    assert_send_type "(123, :foo, nil) -> [123, :foo, nil]",
                     self, :pp, 123, :foo, nil
  ensure
    $stdout = original_stdout
  end

  def test_initialize_copy
    assert_send_type(
      "(self) -> self",
      Object.new, :initialize_copy, Object.new
    )
  end

  def test_initialize_clone
    assert_send_type(
      "(self) -> self",
      Object.new, :initialize_clone, Object.new
    )

    assert_send_type(
      "(self, freeze: bool) -> self",
      Object.new, :initialize_clone, Object.new, freeze: true
    )
  end

  def test_initialize_dup
    assert_send_type(
      "(self) -> self",
      Object.new, :initialize_dup, Object.new
    )
  end
end
