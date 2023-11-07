require_relative 'test_helper'

class KernelSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(::Kernel)'

  def test_caller
    assert_send_type  '() -> Array[String]',
                      Kernel, :caller

    with_int 0 do |start|
      assert_send_type  '(int) -> Array[String]',
                        Kernel, :caller, start

      with_int(2).and_nil do |length|
        assert_send_type  '(int, int?) -> Array[String]',
                          Kernel, :caller, start, length
      end
    end

    with_int caller.length*2 do |start|
      assert_send_type  '(int) -> nil',
                        Kernel, :caller, start
    end
  end

  def test_caller_locations
    assert_send_type  '() -> Array[Thread::Backtrace::Location]',
                      Kernel, :caller_locations

    with_int 0 do |start|
      assert_send_type  '(int) -> Array[Thread::Backtrace::Location]',
                        Kernel, :caller_locations, start

      with_int(2).and_nil do |length|
        assert_send_type  '(int, int?) -> Array[Thread::Backtrace::Location]',
                          Kernel, :caller_locations, start, length
      end
    end

    with_int caller.length*2 do |start|
      assert_send_type  '(int) -> nil',
                        Kernel, :caller_locations, start
    end
  end

  def test_catch
    assert_send_type  '(:foo) { (:foo) -> untyped } -> untyped',
                      Kernel, :catch, :foo do end

    assert_send_type  '() { (Object) -> untyped} -> untyped',
                      Kernel, :catch do end
  end


  def test_eval
    with_string '1' do |src|
      assert_send_type  '(string) -> untyped',
                        Kernel, :eval, src

      [binding, nil].each do |scope|
        assert_send_type  '(string, Binding?) -> untyped',
                          Kernel, :eval, src, scope

        with_string __FILE__ do |filename|
          assert_send_type  '(string, Binding?, string) -> untyped',
                            Kernel, :eval, src, scope, filename

          with_int __LINE__ do |lineno|
            assert_send_type  '(string, Binding?, string, int) -> untyped',
                              Kernel, :eval, src, scope, filename, lineno
          end
        end
      end
    end
  end

  def test_block_given?
    assert_send_type  '() -> bool',
                      Kernel, :block_given?
  end

  def test_local_variables
    local_var = 3
    assert_send_type  '() -> Array[Symbol]',
                      Kernel, :local_variables
  end

  def test_srand
    with_int 0 do |int|
      assert_send_type  '(int) -> Integer',
                        Kernel, :srand, int
    end

    # Don't move this test, as it's also implicitly testing the `-> Integer` (ie last value) is
    # actually correct, and won't return an `int`.
    assert_send_type  '() -> Integer',
                      Kernel, :srand
  end

  def test_fork
    assert_send_type  '() { () -> void } -> Integer',
                      Kernel, :fork do 3 end
    omit 'todo'
    begin
      child = assert_send_type  '() -> Integer',
                               Kernel, :fork
    rescue Test::Unit::AssertionFailedError
      child = assert_send_type  '() -> Integer',
                               Kernel, :fork
      exit! 123
    else
      exit! 12 if child.nil?
    end
  end

  def test_Array
    assert_send_type  '(nil) -> []',
                      Kernel, :Array, nil

    with_array(1r, 2r).and_chain(ToA.new(3r)) do |array_like|
      assert_send_type  '[T] (array[T] | _ToA[T]) -> []',
                        Kernel, :Array, array_like
    end

    assert_send_type  '(Rational) -> [Rational]',
                      Kernel, :Array, 1r
  end

  def test_Complex
    assert_send_type  '(_ToC) -> Complex',
                      Kernel, :Complex, ToC.new
    assert_send_type  '(_ToC, exception: true) -> Complex',
                      Kernel, :Complex, ToC.new, exception: true
    assert_send_type  '(_ToC, exception: bool) -> nil',
                      Kernel, :Complex, Class.new{def to_c = raise}.new, exception: false

    # TODO: There's additional constraints on the `Numeric` here, but we need to figure out how
    # we want `Numeric` to work before we can add `, Numeric.new` to the end of the list.
    numerics = [1, 1r, 1.0, 1i]

    (numerics + ['1i']).each do |real|
      assert_send_type  '(Numeric | String) -> Complex',
                        Kernel, :Complex, real
      assert_send_type  '(Numeric | String, exception: true) -> Complex',
                        Kernel, :Complex, real, exception: true

      (numerics + ['1i']).each do |imag|
        assert_send_type  '(Numeric | String, Numeric | String) -> Complex',
                          Kernel, :Complex, real, imag
        assert_send_type  '(Numeric | String, Numeric | String, exception: true) -> Complex',
                          Kernel, :Complex, real, imag, exception: true
      end
    end

    assert_send_type  '(String, exception: false) -> nil',
                      Kernel, :Complex, 'a', exception: false
    assert_send_type  '(String, String, exception: false) -> nil',
                      Kernel, :Complex, 'a', 'a', exception: false
  end

  def test_Float
    [1, 1r, 1.0, '123e45', ToF.new].each do |float_like|
      assert_send_type  '(_ToF) -> Float',
                        Kernel, :Float, float_like
      assert_send_type  '(_ToF, exception: true) -> Float',
                        Kernel, :Float, float_like, exception: true
    end

    assert_send_type  '(_ToF, exception: false) -> nil',
                      Kernel, :Float, Class.new{def to_f = raise}.new, exception: false
  end

  def test_Hash
    assert_send_type  '(nil) -> {}',
                      Kernel, :Hash, nil
    assert_send_type  '([]) -> {}',
                      Kernel, :Hash, []

    with_hash 'a' => 3, 'b' => 4 do |hash|
      assert_send_type  '(hash[String, Integer]) -> Hash[String, Integer]',
                        Kernel, :Hash, hash
    end
  end

  def test_Integer
    omit 'todo'
    with_int.and_chain(ToI.new) do |int_like|
      assert_send_type  '(int | _ToI) -> Integer',
                        Kernel, :Integer, int_like
      assert_send_type  '(int | _ToI, exception: true) -> Integer',
                        Kernel, :Integer, int_like, exception: true
    end
    
    assert_send_type  '(_ToInt, exception: false) -> nil',
                      Kernel, :Integer, Class.new{def to_int = raise}.new, exception: false
    assert_send_type  '(_ToI, exception: false) -> nil',
                      Kernel, :Integer, Class.new{def to_i = raise}.new, exception: false

    with_int 16 do |base|
      with_string 'ff' do |str|
        assert_send_type  '(string, int) -> Integer',
                          Kernel, :Integer, str, base
        assert_send_type  '(string, int, exception: true) -> Integer',
                          Kernel, :Integer, str, base, exception: true
      end

      with_string 'invalid!' do |str|
        assert_send_type  '(string, int, exception: false) -> nil',
                          Kernel, :Integer, str, base, exception: false
      end

      assert_send_type  '(string, int, exception: false) -> nil',
                        Kernel, :Integer, Class.new{def to_str = raise}.new, base, exception: false
    end
    
    assert_send_type  '(string, int, exception: false) -> nil',
                      Kernel, :Integer, '12', Class.new{def to_int = raise}.new, exception: false
  end

  def test_Rational
    omit 'todo'
  end

  def test_String
    with_string.and_chain(ToS.new) do |string_like|
      assert_send_type  '(string | _ToS) -> String',
                        Kernel, :String, string_like
    end
  end

  CALLEE_OUTSIDE_OF_A_METHOD = __callee__
  def test___callee__
    assert_send_type  '() -> Symbol',
                      Kernel, :__callee__

    assert_type 'nil', CALLEE_OUTSIDE_OF_A_METHOD
  end

  def test___dir__
    omit 'todo'
  end

  METHOD_OUTSIDE_OF_A_METHOD = __method__
  def test___method__
    assert_type 'nil', METHOD_OUTSIDE_OF_A_METHOD

    assert_send_type  '() -> Symbol',
                      Kernel, :__method__
  end

  def test_backtick
    # `cd` is on linux, macos, and windows, so it seems like a safe choice.
    omit 'todo' unless system 'cd', %i[out err in] => :close

    with_string 'cd' do |cmd|
      assert_send_type  '(string) -> String',
                        Kernel, :`, cmd
    end
  end

  def test_abort
    omit 'todo'
  end

  def test_at_exit
    omit 'todo'
  end

  def test_autoload
    omit 'todo'
  end

  def test_autoload?
    omit 'todo'
  end

  def test_binding
    assert_send_type  '() -> Binding',
                      Kernel, :binding
  end

  def test_exit
    with_int.and_chain(with_bool) do |status|
      exit status
    rescue SystemExit
      assert true
    else
      flunk '`exit` should raise `SystemExit`'
    end
  end

  def test_exit!
    omit 'todo'
  end

  def test_fail(method = :fail)
    omit 'todo'
  end

  def test_raise
    test_fail :raise
  end

  def test_format(method = :format)
    with_string '%s' do |fmt|
      assert_send_type  '(string, *untyped) -> String',
                        Kernel, method, fmt, 'hello, world!'
    end
  end

  def test_sprintf
    test_format :sprintf
  end

  def test_gets
    omit 'todo'
  end

  def test_global_variables
    assert_send_type  '() -> Array[Symbol]',
                      Kernel, :global_variables
  end

  def test_load
    omit 'todo'
  end

  def test_loop
    assert_send_type  '() -> Enumerator[nil, bot]',
                      Kernel, :loop
    assert_send_type  '() { () -> void } -> bot',
                      Kernel, :loop do break end
  end

  def test_open
    omit 'todo'
  end

  def capture_stdout(&block)
    old_stdout = $stdout
    ($stdout = Writer.new).tap(&block)
  ensure
    $stdout = old_stdout
  end

  def test_print
    capture_stdout do
      assert_send_type  '(*_ToS) -> nil',
                        Kernel, :print, 1, Object.new, 1r, :hello_world
    end
  end

  def test_printf
    capture_stdout do
      assert_send_type  '() -> nil',
                        Kernel, :printf
      assert_send_type  '(String, *untyped) -> nil',
                        Kernel, :printf, '%s', 'hello world'
    end

    with_string '%s' do |fmt|
      assert_send_type  '(_Writer, string, *untyped) -> nil',
                        Kernel, :printf, Writer.new, fmt, 'hello, world!'
    end
  end

  def test_proc
    assert_send_type  '() { (*untyped, **untyped) -> untyped } -> Proc',
                      Kernel, :proc do end
  end

  def test_lambda
    assert_send_type  '() { (*untyped, **untyped) -> untyped } -> Proc',
                      Kernel, :lambda do end
  end

  def test_putc
    capture_stdout do
      assert_send_type  '(String) -> String',
                        Kernel, :putc, '&'
      with_int 38 do |int|
        assert_send_type  '[T < _ToInt] (T) -> T',
                          Kernel, :putc, int
      end
    end
  end

  def test_puts
    capture_stdout do
      assert_send_type  '(*_ToS) -> nil',
                        Kernel, :puts, 1, Object.new, 1r, :hello_world
    end
  end

  def test_p
    inspectable = BlankSlate.new.__with_object_methods(:inspect)

    capture_stdout do
      assert_send_type  '() -> nil',
                        Kernel, :p
      assert_send_type  '[T < _Inspect] (T) -> T',
                        Kernel, :p, inspectable
      assert_send_type  '(_Inspect, _Inspect, *_Inspect) -> Array[_Inspect]',
                        Kernel, :p, inspectable, inspectable
    end
  end

  def test_pp
    omit 'todo'
  end

  def test_rand
    omit 'todo'
  end

  def test_readline
    old_stdin = $stdin

    $stdin = BlankSlate.new
    file = ::File.open(__FILE__)

    ::Kernel.instance_method(:define_singleton_method).bind_call($stdin, :readline) do |*a, **k|
      file.readline(*a, **k)
    rescue EOFError # `__FILE__` isn't large enough to be read in one pass.
      file.rewind
      retry
    end

    assert_send_type  '() -> String',
                      Kernel, :readline
    
    with_string("\n").and_nil do |sep|
      assert_send_type  '(string?) -> String',
                        Kernel, :readline, sep

      with_boolish do |chomp|
        assert_send_type  '(string?, chomp: boolish) -> String',
                          Kernel, :readline, sep, chomp: chomp
      end

      with_int(10).and_nil do |limit|
        assert_send_type  '(string?, int?) -> String',
                          Kernel, :readline, sep, limit

        with_boolish do |chomp|
          assert_send_type  '(string?, int?, chomp: boolish) -> String',
                            Kernel, :readline, sep, limit, chomp: chomp
        end
      end
    end

    with_int(10).and_nil do |limit|
      assert_send_type  '(int?) -> String',
                        Kernel, :readline, limit

      with_boolish do |chomp|
        assert_send_type  '(int?, chomp: boolish) -> String',
                          Kernel, :readline, limit, chomp: chomp
      end
    end
  ensure
    file.close
    $stdin = old_stdin
  end

  def test_readlines
    old_stdin = $stdin

    $stdin = BlankSlate.new
    file = ::File.open(__FILE__)

    ::Kernel.instance_method(:define_singleton_method).bind_call($stdin, :readlines) do |*a, **k|
      file.readlines(*a, **k)
    rescue EOFError # `__FILE__` isn't large enough to be read in one pass.
      file.rewind
      retry
    end

    assert_send_type  '() -> Array[String]',
                      Kernel, :readlines
    
    with_string("\n").and_nil do |sep|
      assert_send_type  '(string?) -> Array[String]',
                        Kernel, :readlines, sep

      with_boolish do |chomp|
        assert_send_type  '(string?, chomp: boolish) -> Array[String]',
                          Kernel, :readlines, sep, chomp: chomp
      end

      with_int(10).and_nil do |limit|
        assert_send_type  '(string?, int?) -> Array[String]',
                          Kernel, :readlines, sep, limit

        with_boolish do |chomp|
          assert_send_type  '(string?, int?, chomp: boolish) -> Array[String]',
                            Kernel, :readlines, sep, limit, chomp: chomp
        end
      end
    end

    with_int(10).and_nil do |limit|
      assert_send_type  '(int?) -> Array[String]',
                        Kernel, :readlines, limit

      with_boolish do |chomp|
        assert_send_type  '(int?, chomp: boolish) -> Array[String]',
                          Kernel, :readlines, limit, chomp: chomp
      end
    end
  ensure
    file.close
    $stdin = old_stdin
  end

  def test_require
    with_path File.join(__dir__, 'util', 'valid.rb') do |path|
      assert_send_type  '(path) -> bool',
                        Kernel, :require, path
    end
  end

  def test_require_relative
    with_path File.join('util', 'valid.rb') do |path|
      assert_send_type  '(path) -> bool',
                        Kernel, :require_relative, path
    end
  end

  def test_select
    omit 'todo'
  end

  def test_sleep
    omit 'todo'
  end

  def test_syscall
    # There's no real way to typecheck this, as syscalls aren't portable at all.
  end

  def test_test
    omit 'todo'
  end

  def test_throw
    omit 'todo'
  end

  def test_warn
    omit 'todo'
  end
end


class KernelInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  class KernelTest < BlankSlate
    include ::Kernel
  end

  testing '::Kernel'

  INSTANCE = KernelTest.new

  def test_nmatch
    kt = KernelTest.new
    def kt.=~(*) = 1

    with_untyped do |other|
      assert_send_type  '(untyped) -> bool',
                        kt, :!~, other
    end
  end

  def test_cmp
    kt = KernelTest.new.__with_object_methods(:==)

    assert_send_type  '(untyped) -> 0',
                      kt, :<=>, kt

    with_untyped do |other|
      assert_send_type  '(untyped) -> nil',
                        kt, :<=>, other
    end
  end

  def test_eqq
    kt = KernelTest.new.__with_object_methods(:==)

    with_untyped.and_chain(kt) do |other|
      assert_send_type  '(untyped) -> bool',
                        kt, :===, other
    end
  end

  def test_class
    assert_send_type  '() -> Class',
                      INSTANCE, :class
  end

  def test_clone
    assert_send_type  '() -> instance',
                      INSTANCE, :clone

    with_bool.and_nil do |freeze|
      assert_send_type  '(freeze: bool?) -> instance',
                        INSTANCE, :clone, freeze: freeze
    end
  end

  def test_define_singleton_method
    with_interned :foo do |name|
      assert_send_type  '(interned, Method) -> Symbol',
                        KernelTest.new, :define_singleton_method, name, method(:__id__)
      assert_send_type  '(interned, UnboundMethod) -> Symbol',
                        KernelTest.new, :define_singleton_method, name, method(:__id__).unbind
      assert_send_type  '(interned, Proc) -> Symbol',
                        KernelTest.new, :define_singleton_method, name, proc{}

      assert_send_type  '(interned) { (*untyped, **untyped) -> untyped } -> Symbol',
                        KernelTest.new, :define_singleton_method, name do end
    end
  end

  def test_display
    old_stdout = $stdout
    $stdout = Writer.new

    assert_send_type  '() -> nil',
                      INSTANCE, :display
    assert_send_type  '(_Writer) -> nil',
                      INSTANCE, :display, Writer.new

  ensure
    $stdout = old_stdout
  end

  def test_dup
    assert_send_type  '() -> instance',
                      INSTANCE, :dup
  end

  def test_enum_for(method = :enum_for)
    omit 'todo'
  end

  def test_to_enum
    test_enum_for :to_enum
  end

  def test_eql?
    with_untyped.and_chain(INSTANCE) do |other|
      assert_send_type  '(untyped) -> bool',
                        INSTANCE, :eql?, other
    end
  end

  def test_extend
    assert_send_type  '(Module) -> self',
                      KernelTest.new, :extend, Module.new

    assert_send_type  '(Module, *Module) -> self',
                      KernelTest.new, :extend, Module.new, Module.new
  end

  def test_freeze
    assert_send_type  '() -> self',
                      KernelTest.new, :freeze
  end

  def test_frozen?
    assert_send_type  '() -> bool',
                      INSTANCE, :frozen?
    assert_send_type  '() -> bool',
                      KernelTest.new.tap(&:freeze), :frozen?
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      INSTANCE, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      INSTANCE, :inspect
  end

  def test_instance_of?
    [Module.new, KernelTest, Kernel].each do |module_or_class|
      assert_send_type  '(Module) -> bool',
                        INSTANCE, :instance_of?, module_or_class
    end
  end

  def test_instance_variable_defined?
    with_interned :@foo do |name|
      assert_send_type  '(interned) -> bool',
                        INSTANCE, :instance_variable_defined?, name
    end
  end

  def test_instance_variable_get
    with_interned :@foo do |name|
      assert_send_type  '(interned) -> untyped',
                        INSTANCE, :instance_variable_get, name
    end
  end

  def test_instance_variable_set
    with_interned :@foo do |name|
      assert_send_type  '[T] (interned, T) -> T',
                        KernelTest.new, :instance_variable_set, name, 1r
    end
  end

  def test_instance_variables
    class << (kt = KernelTest)
      @foo = 3 # So it's an `Array[Symbol]` and not an empty array.
    end

    assert_send_type  '() -> Array[Symbol]',
                      kt, :instance_variables
  end

  def test_is_a?(method = :is_a?)
    [Module.new, KernelTest, Kernel].each do |module_or_class|
      assert_send_type  '(Module) -> bool',
                        INSTANCE, method, module_or_class
    end
  end

  def test_kind_of?
    test_is_a? :kind_of?
  end

  def test_itself
    assert_send_type  '() -> self',
                      INSTANCE, :itself
  end

  def test_method
    with_interned :eql? do |name|
      assert_send_type  '(interned) -> Method',
                        INSTANCE, :method, name
    end

    # Make sure that `ToSym` isn't permitted.
    refute_send_type  '(_ToSym) -> Method',
                      INSTANCE, :method, ToSym.new(:eql?)
  end

  def test_methods
    def (kt = KernelTest.new).foo = 3

    assert_send_type  '() -> Array[Symbol]',
                      kt, :methods

    with_boolish do |include_super|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        kt, :methods, include_super
    end
  end

  def test_nil?
    assert_send_type  '() -> false',
                      INSTANCE, :nil?
  end

  def test_object_id
    assert_send_type  '() -> Integer',
                      INSTANCE, :object_id
  end

  def test_private_methods
    class << (kt = KernelTest.new)
      private def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      kt, :private_methods

    with_boolish do |all|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        kt, :private_methods, all
    end
  end

  def test_protected_methods
    class << (kt = KernelTest.new)
      protected def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      kt, :protected_methods

    with_boolish do |all|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        kt, :protected_methods, all
    end
  end

  def test_public_method
    with_interned :eql? do |name|
      assert_send_type  '(interned) -> Method',
                        INSTANCE, :public_method, name
    end

    # Make sure that `ToSym` isn't permitted.
    refute_send_type  '(_ToSym) -> Method',
                      INSTANCE, :public_method, ToSym.new(:eql?)
  end

  def test_public_methods
    class << (kt = KernelTest.new)
      def foo = 3
    end

    assert_send_type  '() -> Array[Symbol]',
                      kt, :public_methods

    with_boolish do |all|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        kt, :public_methods, all
    end
  end

  def test_public_send
    class << (kt = KernelTest.new)
      def foo(*a, **k, &b) = 3
    end

    with_interned :foo do |name|
      assert_send_type  '(interned, *untyped, **untyped) ?{ (*untyped, **untyped) -> untyped } -> untyped',
                        kt, :public_send, name, 3, b: 4 do end
    end
  end

  def test_remove_instance_variable
    kt = KernelTest.new
    with_interned :@foo do |name|
      kt.instance_variable_set(:@foo, 34)

      assert_send_type  '(interned) -> untyped',
                        kt, :remove_instance_variable, name
    end
  end

  def test_respond_to?
    def (kt = KernelTest.new).respond_to_missing?(*) = :yes

    # You can get `.respond_to?` to return a `boolish` value by defining a custom
    # `respond_to_missing?` method and calling `.respond_to?` by a dynamically-created symbol (just
    # a simple `:"foo#{3}"` is good enough.)

    with_interned :"foo#{3}" do |name|
      assert_send_type  '(interned) -> bool',
                        INSTANCE, :respond_to?, name
      assert_send_type  '(interned) -> :yes',
                        kt, :respond_to?, name

      with_boolish do |include_all|
        assert_send_type  '(interned, boolish) -> bool',
                          INSTANCE, :respond_to?, name, include_all
        assert_send_type  '(interned, boolish) -> :yes',
                          kt, :respond_to?, name, include_all
      end
    end
  end

  def test_send
    class << (kt = KernelTest.new)
      def foo(*a, **k, &b) = 3
    end

    with_interned :foo do |name|
      assert_send_type  '(interned, *untyped, **untyped) ?{ (*untyped, **untyped) -> untyped } -> untyped',
                        kt, :send, name, 3, b: 4 do end
    end
  end

  def test_singleton_class
    assert_send_type  '() -> Class',
                      INSTANCE, :singleton_class
  end

  def test_singleton_method
    def (kt = KernelTest.new).a_singleton_method = 3
    with_interned :a_singleton_method do |name|
      assert_send_type  '(interned) -> Method',
                        kt, :singleton_method, name
    end

    # Make sure that `ToSym` isn't permitted.
    refute_send_type  '(_ToSym) -> Method',
                      kt, :singleton_method, ToSym.new(:a_singleton_method)
  end

  def test_singleton_methods
    def (kt = KernelTest.new).a_singleton_method = 3

    assert_send_type  '() -> Array[Symbol]',
                      kt, :singleton_methods

    with_boolish do |all|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        kt, :singleton_methods, all
    end
  end

  def test_tap
    assert_send_type  '() { (self) -> void } -> self',
                      INSTANCE, :tap do end
  end

  def test_to_s
    assert_send_type  '() -> String',
                      INSTANCE, :to_s
  end

  def test_yield_self(method = :yield_self)
    assert_send_type  '() -> Enumerator[self, untyped]',
                      INSTANCE, method
    assert_send_type  '[T] () { (self) -> T } -> T',
                      INSTANCE, method do 1r end
  end

  def test_then
    test_yield_self :then
  end

  def test_respond_to_missing?
    with_interned :foobar do |name|
      with_boolish do |include_all|
        assert_send_type  '(interned, boolish) -> boolish',
                          INSTANCE, :respond_to_missing?, name, include_all
      end

      # unlike `respond_to?`, `respond_to_missing?` always expects two arguments.
      refute_send_type  '(interned) -> boolish',
                        INSTANCE, :respond_to_missing?, name
    end
  end

  def test_initialize_copy
    assert_send_type  '(instance) -> self',
                      KernelTest.allocate, :initialize_copy, INSTANCE
  end

  def test_initialize_clone
    assert_send_type  '(instance) -> self',
                      KernelTest.allocate, :initialize_clone, INSTANCE

    with_bool.and_nil do |freeze|
      assert_send_type  '(instance, freeze: bool?) -> self',
                        KernelTest.allocate, :initialize_clone, INSTANCE, freeze: freeze
    end
  end

  def test_initialize_dup
    assert_send_type  '(instance) -> self',
                      KernelTest.allocate, :initialize_dup, INSTANCE
  end
end
