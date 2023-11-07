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

  testing '::Kernel'

  def test_nmatch
    omit 'todo'
  end

  def test_cmp
    omit 'todo'
  end

  def test_eqq
    omit 'todo'
  end

  def test_class
    omit 'todo'
  end

  def test_clone
    omit 'todo'
  end

  def test_define_singleton_method
    omit 'todo'
  end

  def test_display
    omit 'todo'
  end

  def test_dup
    omit 'todo'
  end

  def test_enum_for(method = :enum_for)
    omit 'todo'
  end

  def test_to_enum
    test_enum_for :to_enum
  end

  def test_eql?
    omit 'todo'
  end

  def test_extend
    omit 'todo'
  end

  def test_freeze
    omit 'todo'
  end

  def test_frozen?
    omit 'todo'
  end

  def test_hash
    omit 'todo'
  end

  def test_inspect
    omit 'todo'
  end

  def test_instance_of?
    omit 'todo'
  end

  def test_instance_variable_defined?
    omit 'todo'
  end

  def test_instance_variable_get
    omit 'todo'
  end

  def test_instance_variable_set
    omit 'todo'
  end

  def test_instance_variables
    omit 'todo'
  end

  def test_is_a?(method = :is_a?)
    omit 'todo'
  end

  def test_kind_of?
    test_is_a? :kind_of?
  end

  def test_itself
    omit 'todo'
  end

  def test_method
    omit 'todo'
  end

  def test_methods
    omit 'todo'
  end

  def test_nil?
    omit 'todo'
  end

  def test_object_id
    omit 'todo'
  end

  def test_private_methods
    omit 'todo'
  end

  def test_protected_methods
    omit 'todo'
  end

  def test_public_method
    omit 'todo'
  end

  def test_public_methods
    omit 'todo'
  end

  def test_public_send
    omit 'todo'
  end

  def test_remove_instance_variable
    omit 'todo'
  end

  def test_respond_to?
    omit 'todo'
  end

  def test_send
    omit 'todo'
  end

  def test_singleton_class
    omit 'todo'
  end

  def test_singleton_method
    omit 'todo'
  end

  def test_singleton_methods
    omit 'todo'
  end

  def test_tap
    omit 'todo'
  end

  def test_to_s
    omit 'todo'
  end

  def test_yield_self(method = :yield_self)
    omit 'todo'
  end

  def test_then
    test_yield_self :then
  end

  def test_respond_to_missing?
    omit 'todo'
  end

  def test_initialize_copy
    omit 'todo'
  end

  def test_initialize_clone
    omit 'todo'
  end

  def test_initialize_dup
    omit 'todo'
  end
end
