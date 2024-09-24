require_relative "test_helper"

require 'shellwords'
require 'pathname'
require 'stringio'
require 'tempfile'

class KernelModuleMethodsTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::Kernel)'

  def capture_stdout
    old_stdout = $stdout
    $stdout = File.new File::NULL, 'w'
    yield
  ensure
    $stdout.close rescue nil
    $stdout = old_stdout
  end

  class OnlyKernel < BlankSlate
    include ::Kernel

    # Temporary hack until `self?.` is solved.
    public ::Kernel.private_instance_methods
  end

  def with_kernel
    yield Kernel
    yield OnlyKernel.new
  end

  # It looks like these tests are working in parallel, so this ensures they're not.
  GETS_READLINE_READLINES_MUTEX = Mutex.new
  def with_no_argv_and_stdin(stdin)
    GETS_READLINE_READLINES_MUTEX.lock do
      old_argv = ARGV.dup
      ARGV.clear

      old_stdin, $stdin = $stdin, StringIO.new(stdin)
      yield
    ensure
      ARGV.replace old_argv
      $stdin = old_stdin
    end
  end

  # We use 1 trillion stackframes to be positive that between the test method and when
  # the `Kernel.caller` and `Kernel.caller_locations` is eventually called we don't create enough
  # stackframes to make the return value not nil.
  MORE_STACKFRAMES_THAN_POSSIBLE = 1_000_000_000_000

  def test_caller
    with_kernel do |kernel|
      assert_send_type  '() -> Array[String]',
                        kernel, :caller

      with_int 0 do |start|
        assert_send_type  '(int) -> Array[String]',
                          kernel, :caller, start

        with_int(1).and_nil do |length|
          assert_send_type  '(int, int?) -> Array[String]',
                            kernel, :caller, start, length
        end
      end

      with_int MORE_STACKFRAMES_THAN_POSSIBLE do |start|
        assert_send_type  '(int) -> nil',
                          kernel, :caller, start

        with_int(1).and_nil do |length|
          assert_send_type  '(int, int?) -> nil',
                            kernel, :caller, start, length
        end
      end

      with_range with_int(0).and_nil, with_int(1).and_nil do |range|
        assert_send_type  '(range[int?]) -> Array[String]',
                          kernel, :caller, range
      end

      # Don't include a nil start, because it's impossible to get a nil return value then.
      with_range with_int(MORE_STACKFRAMES_THAN_POSSIBLE), with_int(MORE_STACKFRAMES_THAN_POSSIBLE + 1).and_nil do |range|
        assert_send_type  '(range[int?]) -> nil',
                          kernel, :caller, range
      end
    end
  end

  def test_caller_locations
    with_kernel do |kernel|
      assert_send_type  '() -> Array[Thread::Backtrace::Location]',
                        kernel, :caller_locations

      with_int 0 do |start|
        assert_send_type  '(int) -> Array[Thread::Backtrace::Location]',
                          kernel, :caller_locations, start

        with_int(1).and_nil do |length|
          assert_send_type  '(int, int?) -> Array[Thread::Backtrace::Location]',
                            kernel, :caller_locations, start, length
        end
      end

      with_int MORE_STACKFRAMES_THAN_POSSIBLE do |start|
        assert_send_type  '(int) -> nil',
                          kernel, :caller_locations, start

        with_int(1).and_nil do |length|
          assert_send_type  '(int, int?) -> nil',
                            kernel, :caller_locations, start, length
        end
      end

      with_range with_int(0).and_nil, with_int(1).and_nil do |range|
        assert_send_type  '(range[int?]) -> Array[Thread::Backtrace::Location]',
                          kernel, :caller_locations, range
      end

      # Don't include a nil start, because it's impossible to get a nil return value then.
      with_range with_int(MORE_STACKFRAMES_THAN_POSSIBLE), with_int(MORE_STACKFRAMES_THAN_POSSIBLE + 1).and_nil do |range|
        assert_send_type  '(range[int?]) -> nil',
                          kernel, :caller_locations, range
      end
    end
  end

  def test_catch
    with_kernel do |kernel|
      assert_send_type  '() { (Object) -> untyped } -> untyped',
                        kernel, :catch do 1r end
      assert_send_type  '[T] (T) { (T) -> untyped } -> untyped',
                        kernel, :catch, BlankSlate.new do 1r end
    end
  end

  def test_eval
    with_kernel do |kernel|
      with_string '1+2' do |src|
        assert_send_type  '(string) -> untyped',
                          kernel, :eval, src

        with(binding).and_nil do |scope|
          assert_send_type  '(string, Binding?) -> untyped',
                            kernel, :eval, src, scope

          with_string 'some-file' do |filename|
            assert_send_type  '(string, Binding?, string) -> untyped',
                              kernel, :eval, src, scope, filename

            with_int 123 do |lineno|
              assert_send_type  '(string, Binding?, string, int) -> untyped',
                                kernel, :eval, src, scope, filename, lineno
            end
          end
        end
      end
    end
  end

  def was_block_given = block_given?
  def test_block_given?
    assert_type 'false', was_block_given
    assert_type 'true', was_block_given{}
  end

  def test_local_variables
    with_kernel do |kernel|
      x = 3
      assert_send_type  '() -> Array[Symbol]',
                        kernel, :local_variables
    end
  end

  def test_srand
    with_kernel do |kernel|
      prev_seed = kernel.srand 0

      assert_send_type  '() -> Integer',
                        kernel, :srand

      with_int 123 do |int|
        assert_send_type  '(int) -> Integer',
                          kernel, :srand, int
      end
    ensure
      kernel.srand prev_seed
    end
  end

  def test_fork
    with_kernel do |kernel|
      assert_send_type  '() { () -> void } -> Integer',
                        kernel, :fork do :foo end

      # There's no real easy way to test the no-argument variation of `fork()`, as it spawns a whole
      # new process. We have to test to make sure both `nil` and `Integer` are returned, so to do that
      # we have the child process exit with a predetermined exit code 

      # Keep track of the parent pid so the child knows to `exit!`
      parent_pid = Process.pid

      # Fork, we'll have both a child process and parent process.
      pid = kernel.fork

      # In the child process, we exit truthy if the pid is `nil` (i.e. what we expect), and falsey if
      # it's anything else. (Note we do `nil.equal?` instead of `pid.nil?` to ensure that `pid` is
      # actually `nil`, and isn't just overwriting `.nil?` (or anything else).)
      exit! nil.equal?(pid) unless Process.pid == parent_pid

      # -- Here and below, we know we're just the parent process --

      # Wait for the child to finish.
      _pid, status = Process.waitpid2 pid

      # Make sure the `pid` is actually an integer (check the `-> Integer` variant)
      assert_type 'Integer', pid

      # If `status` is successful, that means that the `nil.equal?(pid)` is true, and thus the child
      # process exited successfully.
      assert status.success?
    end
  end

  def test_Array
    with_kernel do |kernel|
      assert_send_type  '(nil) -> []',
                        kernel, :Array, nil

      with_array(1r).and ToA.new(1r) do |array|
        assert_send_type  '[T] (array[T] | _ToA[T]) -> Array[T]',
                          kernel, :Array, array
      end

      with_untyped do |element|
        next if defined?(element.to_ary) || defined?(element.to_a)

        assert_send_type  '[T] (T) -> [T]',
                          kernel, :Array, element
      end
    end
  end

  def test_Complex
    omit "todo: #{__method__}"
  end

  def test_Float
    with_kernel do |kernel|
      with 1, 1r, 1.0, '123e45', ToF.new do |float_like|
        assert_send_type  '(_ToF) -> Float',
                          kernel, :Float, float_like
        assert_send_type  '(_ToF, exception: true) -> Float',
                          kernel, :Float, float_like, exception: true
      end

      assert_send_type  '(_ToF, exception: bool) -> nil',
                        kernel, :Float, Class.new{def to_f = raise}.new, exception: false

      with_untyped.and 1.0 do |untyped|
        # Ensure sure we're testing the no-`exception` case, but also ensure that it's not
        # going to raise an exception on us.
        if nil != Float(untyped, exception: false)
          assert_send_type  '(untyped) -> Float',
                            kernel, :Float, untyped
          assert_send_type  '(untyped, exception: true) -> Float',
                            kernel, :Float, untyped, exception: true
        end

        assert_send_type  '(untyped, exception: bool) -> Float?',
                          kernel, :Float, untyped, exception: false
      end
    end
  end

  def test_Hash
    with_kernel do |kernel|
      assert_send_type  '[K, V] (nil) -> Hash[K, V]',
                        kernel, :Hash, nil
      assert_send_type  '[K, V] ([]) -> Hash[K, V]',
                        kernel, :Hash, []

      with_hash 'a' => :b do |hash|
        assert_send_type  '[K, V] (hash[K, V]) -> Hash[K, V]',
                          kernel, :Hash, hash
      end
    end
  end

  def test_Integer
    with_kernel do |kernel|
      with_int.and ToI.new, '12' do |int_like|
        assert_send_type  '(int | _ToI) -> Integer',
                          kernel, :Integer, int_like
        assert_send_type  '(int | _ToI, exception: true) -> Integer',
                          kernel, :Integer, int_like, exception: true

      end
      assert_send_type  '(int | _ToI, exception: bool) -> nil',
                        kernel, :Integer, Class.new{def to_i = fail}.new, exception: false

      with_int 11 do |base|
        with_string '12' do |string|
          assert_send_type  '(string, int) -> Integer',
                            kernel, :Integer, string, base
          assert_send_type  '(string, int, exception: true) -> Integer',
                            kernel, :Integer, string, base, exception: true
        end

        with_string '&' do |string|
          assert_send_type  '(string, int, exception: bool) -> Integer',
                            kernel, :Integer, string, base, exception: false
        end
      end
    end
  end

  def test_Rational
    omit "todo: #{__method__}"
  end

  def test_String
    with_kernel do |kernel|
      with_string.and ToS.new do |string|
        assert_send_type  '(string | _ToS) -> String',
                          kernel, :String, string
      end
    end
  end

  def test___callee__
    with_kernel do |kernel|
      assert_send_type  '() -> Symbol',
                        kernel, :__callee__

      # We're in a function, so we have to use this to ensure we're not in one.
      # Since we're using the top-level binding, we need to use a global.
      $__rbs_test___callee___kernel = kernel
      assert_type 'nil', TOPLEVEL_BINDING.eval('$__rbs_test___callee___kernel.__callee__')
    end
  end

  def test___dir__
    with_kernel do |kernel|
      assert_send_type  '() -> String',
                        kernel, :__dir__
      assert_type 'nil', eval('kernel.__dir__', binding) # no __FILE__ given means no `__dir__`
    end
  end

  def test___method__
    with_kernel do |kernel|
      assert_send_type  '() -> Symbol',
                        kernel, :__method__

      # We're in a function, so we have to use this to ensure we're not in one.
      $__rbs_test___method___kernel = kernel
      assert_type 'nil', TOPLEVEL_BINDING.eval('$__rbs_test___method___kernel.__method__')
    end
  end

  def test_op_grave
    with_kernel do |kernel|
      capture_stdout do
        with_string "#{RUBY_EXECUTABLE.shellescape} -v" do |cmd|
          assert_send_type  '(string) -> String',
                            kernel, :`, cmd
        end
      end
    end
  end

  def test_abort
    old_stderr = $stderr
    $stderr = File.new(File::NULL, 'w')

    with_kernel do |kernel|
      with_string 'oopsies' do |message|
        kernel.abort message
      rescue SystemExit
        pass 'abort raised `SystemExit` correctly'
      else
        flunk '`abort` should raise `SystemExit`'
      end
    end

  ensure
    $stderr.close rescue nil
    $stderr = old_stderr
  end

  def test_at_exit
    with_kernel do |kernel|
      assert_send_type '() { () -> void } -> ^() -> void',
                       kernel, :at_exit do end
    end
  end

  def test_autoload
    with_kernel do |kernel|
      with_interned :RBS_Autoload_test_autoload do |const|
        with_path File.join(__dir__, 'util', 'valid.rb') do |path|
          assert_send_type  '(interned, path) -> nil',
                            kernel, :autoload, const, path
        end
      end
    end
  end

  def test_autoload?
    Kernel.autoload :RBS_Autoload_test_autoload_p, File.join(__dir__, 'util', 'valid.rb')

    with_kernel do |kernel|
      with_interned :RBS_Autoload_test_autoload_p do |const|
        assert_send_type  '(interned) -> String',
                          kernel, :autoload?, const
        with_boolish do |inherit|      
          assert_send_type  '(interned, boolish) -> String',
                            kernel, :autoload?, const, inherit
        end
      end

      with_interned :RBS_Autoload_test_autoload_p_doesnt_exist do |const|
        assert_send_type  '(interned) -> nil',
                          kernel, :autoload?, const
        with_boolish do |inherit|      
          assert_send_type  '(interned, boolish) -> nil',
                            kernel, :autoload?, const, inherit
        end
      end
    end
  end

  def test_binding
    with_kernel do |kernel|
      assert_send_type  '() -> Binding',
                        kernel, :binding
    end
  end

  def test_exit
    with_kernel do |kernel|
      with_int.and(with_bool) do |status|
        assert_send_raises  '(int | bool) -> bot', SystemExit,
                            kernel, :exit, status
      end
    end
  end

  def test_exit!
    with_kernel do |kernel|
      with_int(12).and(with_bool) do |status|
        _pid, proc_status = Process.waitpid2 fork { kernel.exit! status }

        case status
        when true  then assert proc_status.success?
        when false then refute proc_status.success?
        else            assert proc_status.exitstatus.equal?(status.to_int)
        end
      end
    end
  end

  def test_fail(method: :fail)
    with_kernel do |kernel|
      # Since `test_fail` could theoretically have been called within the `rescue` block of some
      # other function, we cannot rely on a `Kernel.fail()` always raising a runtime error, so we
      # have to do it ourselves.
      assert_send_raises  '() -> bot', :any,
                          kernel, method

      with_string do |message|
        assert_send_raises  '(string) -> bot', :any,
                            kernel, method, message

        with(Exception.new).and_nil do |cause|
          assert_send_raises  '(string, cause: Exception?) -> bot', :any,
                              kernel, method, message, cause: cause
        end
      end

      assert_type_fn = method(:assert_type)
      exception = BlankSlate.new.__with_object_methods(:define_singleton_method)
      exception.define_singleton_method(:exception) do |message = (nomessage=true)|
        if nomessage
          pass 'no message given'
        else
          assert_type_fn.call('Rational', message)
        end
        StandardError.new
      end

      assert_send_raises  '[T] (Exception::_Exception[T]) -> bot', :any,
                          kernel, method, exception
      assert_send_raises  '[T] (Exception::_Exception[T], T) -> bot', :any,
                          kernel, method, exception, 1r
      with %w[a b c], 'd', Thread::Backtrace.allocate, nil do |backtrace|
        assert_send_raises  '[T] (Exception::_Exception[T], T, Array[String] | String | Thread::Backtrace | nil) -> bot', :any,
                            kernel, method, exception, 1r, backtrace
      end

      with(Exception.new).and_nil do |cause|
        assert_send_raises  '[T] (Exception::_Exception[T], cause: Exception?) -> bot', :any,
                            kernel, method, exception, cause: cause
        assert_send_raises  '[T] (Exception::_Exception[T], T, cause: Exception?) -> bot', :any,
                            kernel, method, exception, 1r, cause: cause
        with %w[a b c], 'd', Thread::Backtrace.allocate, nil do |backtrace|
          assert_send_raises  '[T] (Exception::_Exception[T], T, Array[String] | String | Thread::Backtrace | nil, cause: Exception?) -> bot', :any,
                              kernel, method, exception, 1r, backtrace, cause: cause
        end
      end
    end
  end

  def test_raise
    test_fail(method: :raise)
  end

  def test_sprintf(method: :sprintf)
    with_kernel do |kernel|
      with_string '%{a} %{b}' do |fmt|
        with_hash a: 3, b: 4 do |keywords|
          assert_send_type  '(string, hash[Symbol, untyped]) -> String',
                            kernel, method, fmt, keywords
        end

        assert_send_type  '(string, **untyped) -> String',
                          kernel, method, fmt, a: 3, b: 4
      end

      with_string '%s %s' do |fmt|
        assert_send_type  '(string, *untyped) -> String',
                          kernel, method, fmt, 3, 4
      end
    end
  end

  def test_format
    test_sprintf(method: :format)
  end

  def test_gets
    with_no_argv_and_stdin "abc\n" do
      with_kernel do |kernel|
        $stdin.rewind
        assert_send_type  '() -> String',
                          kernel, :gets
        assert_send_type  '() -> nil',
                          kernel, :gets

        with_boolish do |chomp|
          $stdin.rewind
          assert_send_type  '() -> String',
                            kernel, :gets
          assert_send_type  '() -> nil',
                            kernel, :gets
        end

        with_string("\n").and_nil do |sep|
          $stdin.rewind
          assert_send_type  '(string?) -> String',
                            kernel, :gets, sep
          assert_send_type  '(string?) -> nil',
                            kernel, :gets, sep

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(string?, chomp: boolish) -> String',
                              kernel, :gets, sep, chomp: chomp
            assert_send_type  '(string?, chomp: boolish) -> nil',
                              kernel, :gets, sep, chomp: chomp
          end

          with_int 5 do |limit|
            $stdin.rewind
            assert_send_type  '(string?, int) -> String',
                              kernel, :gets, sep, limit
            assert_send_type  '(string?, int) -> nil',
                              kernel, :gets, sep, limit

            with_boolish do |chomp|
              $stdin.rewind
              assert_send_type  '(string?, int, chomp: boolish) -> String',
                                kernel, :gets, sep, limit, chomp: chomp
              assert_send_type  '(string?, int, chomp: boolish) -> nil',
                                kernel, :gets, sep, limit, chomp: chomp
            end
          end
        end

        with_int 5 do |limit|
          $stdin.rewind
          assert_send_type  '(int) -> String',
                            kernel, :gets, limit
          assert_send_type  '(int) -> nil',
                            kernel, :gets, limit

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(int, chomp: boolish) -> String',
                              kernel, :gets, limit, chomp: chomp
            assert_send_type  '(int, chomp: boolish) -> nil',
                              kernel, :gets, limit, chomp: chomp
          end
        end
      end
    end
  end

  def test_global_variables
    with_kernel do |kernel|
      assert_send_type  '() -> Array[Symbol]',
                        kernel, :global_variables
    end
  end

  def test_load
    with_kernel do |kernel|
      with_path File.join(__dir__, 'util', 'valid.rb') do |path|
        assert_send_type  '(path) -> true',
                          kernel, :load, path

        # Technically MRI accepts `boolish`, but the docs state `Module | bool`, so im using that.
        with_bool.and Module.new do |wrap|
          assert_send_type  '(path, Module | bool) -> true',
                            kernel, :load, path, wrap
        end
      end
    end
  end

  def test_loop
    with_kernel do |kernel|
      # Technically, `loop.each` doesn't actually yield any arguments, so it doesn't fit into the
      # `Enumerator` interface, as that expects it to yield exactly one argument. So, since it
      # doesn't actually fit the interface (even though it technically _is_ an `Enumerator`), I've
      # commented out the interface.
      # assert_send_type  '() -> Enumerator[nil, untyped]',
      #                   kernel, :loop

      # The testing framework doesn't support breaking out of blocks given to `assert_send_type`.
      assert_type 'untyped', kernel.loop { break 123 }
    end
  end

  def test_open
    omit "todo: #{__method__}"
  end

  def test_print
    with_kernel do |kernel|
      capture_stdout do
        assert_send_type  '(*untyped) -> String',
                          kernel, :print, 12, 1r, ToS.new('123')
      end
    end
  end

  def test_printf
    with_kernel do |kernel|
      capture_stdout do
        writer = BlankSlate.new
        def writer.write(*x) = 0

        with_string '%{a} %{b}' do |fmt|
          with_hash a: 3, b: 4 do |keywords|
            assert_send_type  '(_Writer, string, hash[Symbol, untyped]) -> nil',
                              kernel, :printf, writer, fmt, keywords

            next unless String === fmt
            assert_send_type  '(String, hash[Symbol, untyped]) -> nil',
                              kernel, :printf, fmt, keywords
          end

          assert_send_type  '(_Writer, string, **untyped) -> nil',
                            kernel, :printf, writer, fmt, a: 3, b: 4

          next unless String === fmt
          assert_send_type  '(string, **untyped) -> nil',
                            kernel, :printf, fmt, a: 3, b: 4
        end

        with_string '%s %s' do |fmt|
          assert_send_type  '(_Writer, string, *untyped) -> nil',
                            kernel, :printf, writer, fmt, 3, 4

          next unless String === fmt
          assert_send_type  '(String, *untyped) -> nil',
                            kernel, :printf, fmt, 3, 4
        end
      end
    end
  end

  def test_proc
    with_kernel do |kernel|
      assert_send_type  '() { (?) -> untyped } -> Proc',
                        kernel, :proc do |a, *b, c:, d: 2, **e, &f| end 
    end
  end

  def test_lambda
    with_kernel do |kernel|
      assert_send_type  '() { (?) -> untyped } -> Proc',
                        kernel, :lambda do |a, *b, c:, d: 2, **e, &f| end 
    end
  end

  def test_putc
    with_kernel do |kernel|
      capture_stdout do
        assert_send_type  '(String) -> String',
                          kernel, :putc, '&'

        with_int ?&.ord do |chr|
          assert_send_type  '[T < _ToInt] (T) -> T',
                            kernel, :putc, chr
        end
      end
    end
  end

  def test_puts
    with_kernel do |kernel|
      capture_stdout do
        assert_send_type  '(*_ToS) -> nil',
                          kernel, :puts, 1, [2], ToS.new('123')
      end
    end
  end

  def test_p
    with_kernel do |kernel|
      assert_send_type  '() -> nil',
                        kernel, :p

      capture_stdout do
        inspectable = BlankSlate.new
        def inspectable.inspect = 'hi!'

        assert_send_type  '[T < _Inspect] (T) -> T',
                          kernel, :p, inspectable

        inspectable2 = BlankSlate.new
        def inspectable2.inspect = 'hi2!'

        assert_send_type  '[T < _Inspect] (T, T) -> Array[T]',
                          kernel, :p, inspectable, inspectable2
      end
    end
  end

  def test_pp
    with_kernel do |kernel|
      assert_send_type  '() -> nil',
                        kernel, :pp

      capture_stdout do
        pretty = BlankSlate.new.__with_object_methods(:is_a?)
        def pretty.pretty_print(x) = BlankSlate.new
        def pretty.pretty_print_cycle(x) = BlankSlate.new

        assert_send_type  '[T < PP::_PrettyPrint] (T) -> T',
                          kernel, :pp, pretty

        pretty2 = BlankSlate.new.__with_object_methods(:is_a?)
        def pretty2.pretty_print(x) = BlankSlate.new
        def pretty2.pretty_print_cycle(x) = BlankSlate.new

        assert_send_type  '[T < PP::_PrettyPrint] (T, T) -> Array[T]',
                          kernel, :pp, pretty, pretty2
      end
    end
  end

  def test_rand
    omit "todo: #{__method__}"
  end

  def test_readline
    with_no_argv_and_stdin "abc\n" do
      with_kernel do |kernel|
        $stdin.rewind
        assert_send_type  '() -> String',
                          kernel, :readline

        with_boolish do |chomp|
          $stdin.rewind
          assert_send_type  '() -> String',
                            kernel, :readline
        end

        with_string("\n").and_nil do |sep|
          $stdin.rewind
          assert_send_type  '(string?) -> String',
                            kernel, :readline, sep

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(string?, chomp: boolish) -> String',
                              kernel, :readline, sep, chomp: chomp
          end

          with_int 5 do |limit|
            $stdin.rewind
            assert_send_type  '(string?, int) -> String',
                              kernel, :readline, sep, limit

            with_boolish do |chomp|
              $stdin.rewind
              assert_send_type  '(string?, int, chomp: boolish) -> String',
                                kernel, :readline, sep, limit, chomp: chomp
            end
          end
        end

        with_int 5 do |limit|
          $stdin.rewind
          assert_send_type  '(int) -> String',
                            kernel, :readline, limit

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(int, chomp: boolish) -> String',
                              kernel, :readline, limit, chomp: chomp
          end
        end
      end
    end
  end

  def test_readlines
    with_no_argv_and_stdin "abc\ndef\n" do
      with_kernel do |kernel|
        $stdin.rewind
        assert_send_type  '() -> Array[String]',
                          kernel, :readlines

        with_boolish do |chomp|
          $stdin.rewind
          assert_send_type  '() -> Array[String]',
                            kernel, :readlines
        end

        with_string("\n").and_nil do |sep|
          $stdin.rewind
          assert_send_type  '(string?) -> Array[String]',
                            kernel, :readlines, sep

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(string?, chomp: boolish) -> Array[String]',
                              kernel, :readlines, sep, chomp: chomp
          end

          with_int 5 do |limit|
            $stdin.rewind
            assert_send_type  '(string?, int) -> Array[String]',
                              kernel, :readlines, sep, limit

            with_boolish do |chomp|
              $stdin.rewind
              assert_send_type  '(string?, int, chomp: boolish) -> Array[String]',
                                kernel, :readlines, sep, limit, chomp: chomp
            end
          end
        end

        with_int 5 do |limit|
          $stdin.rewind
          assert_send_type  '(int) -> Array[String]',
                            kernel, :readlines, limit

          with_boolish do |chomp|
            $stdin.rewind
            assert_send_type  '(int, chomp: boolish) -> Array[String]',
                              kernel, :readlines, limit, chomp: chomp
          end
        end
      end
    end
  end

  def test_require
    with_kernel do |kernel|
      with_path File.join(__dir__, 'util', 'valid.rb') do |path|
        assert_send_type  '(path) -> bool',
                          kernel, :require, path
      end
    end
  end

  def test_require_relative
    with_kernel do |kernel|
      # Technically `require_relative` can accept absolute paths; since the actual file where
      # `require_relative` will be run isn't this one, it's base `__dir__` is different. So we use
      # an absolute path to ensure we're requiring the valid file.
      with_path File.join(__dir__, 'util', 'valid.rb') do |path|
        assert_send_type  '(path) -> bool',
                          kernel, :require_relative, path
      end
    end
  end

  def test_select
    omit "todo: #{__method__}"
  end

  def test_sleep
    with_kernel do |kernel|
      with_timeout(seconds: 0, nanoseconds: 1) do |timeout|
        Thread.new do
          assert_send_type  '(Time::_Timeout) -> Integer',
                            kernel, :sleep, timeout
        end.join
      end

      # No way to test for `-> bot`, so instead check that the args given are ok.

      # Make sure we can call `sleep()`
      th_sleep = Thread.new do
        Thread.current.report_on_exception = false
        kernel.sleep
      end
      begin
        sleep 0.1 while th_sleep.status == 'run' # Wait until the thread's finished running
        assert_equal 'sleep', th_sleep.status # make sure it's sleeping (ie no exception was raised)
      ensure
        th_sleep.kill # cleanup after ourselves
      end

      # Make sure we can call `sleep(nil)`
      th = Thread.new do
        Thread.current.report_on_exception = false
        kernel.sleep(nil)
      end
      begin
        sleep 0.1 while th_sleep.status == 'run' # Wait until the thread's finished running
        assert_equal 'sleep', th_sleep.status # make sure it's sleeping (ie no exception was raised)
      ensure
        th_sleep.kill # cleanup after ourselves
      end
    end
  end

  def test_syscall
    omit 'There is no way to portably and safely test Kernel.syscall'
  end

  def test_test
    with_kernel do |kernel|
      %w[b c d e f g G k o O p S u z].each do |character|
        with_path(__FILE__).and $stdout do |file|
          assert_send_type  "(#{character.inspect}, IO | path) -> bool",
                            kernel, :test, character, file
          assert_send_type  "(#{character.ord}, IO | path) -> bool",
                            kernel, :test, character.ord, file

          with_int(character.ord).and character do |cmd|
            assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                              kernel, :test, cmd, file
          end
        end
      end

      %w[l r R w W x X].each do |character|
        with_path __FILE__ do |file|
          assert_send_type  "(#{character.inspect}, path) -> bool",
                            kernel, :test, character, file
          assert_send_type  "(#{character.ord}, path) -> bool",
                            kernel, :test, character.ord, file

          with_int(character.ord).and character do |cmd|
            assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                              kernel, :test, cmd, file
          end
        end
      end

      %w[s].each do |character|
        File.open __FILE__ do |f|
          with_path(__FILE__).and f do |file|
            assert_send_type  "(#{character.inspect}, IO | path) -> Integer",
                              kernel, :test, character, file
            assert_send_type  "(#{character.ord}, IO | path) -> Integer",
                              kernel, :test, character.ord, file

            with_int(character.ord).and character do |cmd|
              assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                                kernel, :test, cmd, file
            end
          end
        end

        # We have to use `STDOUT` here because `$stdout` might be redefined to
        # an actual file or even a `StringIO`.
        with_path('/__rbs/does/not/exist').and STDOUT do |file|
          assert_send_type  "(#{character.inspect}, IO | path) -> nil",
                            kernel, :test, character, file
          assert_send_type  "(#{character.ord}, IO | path) -> nil",
                            kernel, :test, character.ord, file

          with_int(character.ord).and character do |cmd|
            assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                              kernel, :test, cmd, file
          end
        end
      end

      %w[M A C].each do |character|
        File.open __FILE__ do |f|
          with_path(__FILE__).and f do |file|
            assert_send_type  "(#{character.inspect}, IO | path) -> Time",
                              kernel, :test, character, file
            assert_send_type  "(#{character.ord}, IO | path) -> Time",
                              kernel, :test, character.ord, file

            with_int(character.ord).and character do |cmd|
              assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                                kernel, :test, cmd, file
            end
          end
        end
      end

      %w[- = < >].each do |character|
        File.open __FILE__ do |f|
          with_path(__FILE__).and f do |file|
            assert_send_type  "(#{character.inspect}, IO | path, IO | path) -> bool",
                              kernel, :test, character, file, file
            assert_send_type  "(#{character.ord}, IO | path, IO | path) -> bool",
                              kernel, :test, character.ord, file, file

            with_int(character.ord).and character do |cmd|
              assert_send_type  '(String | int, IO | path, ?IO | path) -> (bool | Integer? | Time)',
                                kernel, :test, cmd, file, file
            end
          end
        end
      end
    end
  end

  def test_throw
    with_kernel do |kernel|
      # no way to test for `-> bot`, so just test arguments
      with_untyped do |tag|
        assert_send_raises  '(untyped) -> bot', UncaughtThrowError,
                            kernel, :throw, tag

        with_untyped do |obj|
          assert_send_raises  '(untyped, untyped) -> bot', UncaughtThrowError,
                              kernel, :throw, tag, obj
        end
      end
    end
  end

  # These are some known warning categories 
  KNOWN_WARNING_CATS = %i[deprecated experimental performance].select { (Warning[_1]; true) rescue false }

  def test_warn
    old_stderr, $stderr = $stderr, File.open(File::NULL, 'w')

    with_kernel do |kernel|
      assert_send_type  '() -> nil',
                        kernel, :warn

      assert_send_type  '(*_ToS) -> nil',
                        kernel, :warn, ToS.new, ToS.new

      with_int(3).and_nil do |uplevel|
        assert_send_type  '(*_ToS, uplevel: int?) -> nil',
                          kernel, :warn, ToS.new, ToS.new, uplevel: uplevel

        with(*KNOWN_WARNING_CATS, *KNOWN_WARNING_CATS.map(&ToSym.method(:new))).and_nil do |category|
          assert_send_type  '(*_ToS, uplevel: int?, category: Warning::category | _ToSym | nil) -> nil',
                            kernel, :warn, ToS.new, ToS.new, uplevel: uplevel, category: category
        end
      end
    end
  ensure
    $stderr.close rescue nil
    $stderr = old_stderr
  end

  def test_exec
    omit "todo: #{__method__}"
  end

  def test_spawn
    omit "todo: #{__method__}"
  end

  def test_system
    omit "todo: #{__method__}"
  end
end

class KernelInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing '::Kernel'

  class JustKernel < BlankSlate
    include ::Kernel
  end

  OBJ = JustKernel.new

  def test_op_nmatch
    obj = JustKernel.new
    def obj.=~(x) = /a/ =~ x rescue nil

    with_untyped.and "a" do |other|
      assert_send_type  '(untyped) -> bool',
                        obj, :!~, other
    end
  end

  def test_op_cmp
    obj = JustKernel.new.__with_object_methods(:==) # needed because <=> has an implicit dependency on it.

    with_untyped.and obj do |other|
      assert_send_type  '(untyped) -> 0?',
                        obj, :<=>, other
    end
  end

  def test_op_eqq
    obj = JustKernel.new.__with_object_methods(:==) # needed because === has an implicit dependency on it.

    with_untyped.and obj do |other|
      assert_send_type  '(untyped) -> bool',
                        obj, :===, other
    end
  end

  def test_clone
    assert_send_type  '() -> KernelInstanceTest::JustKernel',
                      OBJ, :clone
  end

  def test_define_singleton_method
    obj = JustKernel.new

    with_interned :foo do |name|
      assert_send_type  '(interned) { (?) -> untyped } -> Symbol',
                        obj, :define_singleton_method, name do 1r end

      obj.singleton_class.undef_method(:foo)
    end
  end

  def test_display
    old_stdout = $stdout
    $stdout = File.open(File::NULL, 'w')

    assert_send_type  '() -> nil',
                      OBJ, :display

    writer = BlankSlate.new
    def writer.write(*x) = nil
    assert_send_type  '(_Writer) -> nil',
                      OBJ, :display, writer
  ensure
    $stdout.close rescue nil
    old_stdout = $stdout
  end

  def test_dup
    assert_send_type  '() -> KernelInstanceTest::JustKernel',
                      OBJ, :dup
  end

  def test_enum_for
    test_to_enum(method: :enum_for)
  end

  def test_to_enum(method: :to_enum)
    obj = JustKernel.new
    def obj.each(a=3, *b, c: 5, **d, &e) = [1,2,3].each(&e)

    assert_send_type  '() -> Enumerator[untyped, untyped]',
                      obj, method
    assert_send_type  '() { () -> Integer } -> Enumerator[untyped, untyped]',
                      obj, method do 3 end

    with_interned :each do |name|
      assert_send_type  '(interned, *untyped, **untyped) -> Enumerator[untyped, untyped]',
                        obj, method, name, 1, 2, c: 3, d: 4
      assert_send_type  '(interned, *untyped, **untyped) { (?) -> Integer } -> Enumerator[untyped, untyped]',
                        obj, method, name, 1, 2, c: 3, d: 4 do 3 end
    end
  end

  def test_eql?
    with_untyped.and OBJ do |other|
      assert_send_type  '(untyped) -> bool',
                        OBJ, :eql?, other
    end
  end

  def test_extend
    obj = JustKernel.new

    assert_send_type  '(Module) -> KernelInstanceTest::JustKernel',
                      obj, :extend, Module.new

    assert_send_type  '(Module, *Module) -> KernelInstanceTest::JustKernel',
                      obj, :extend, Module.new, Module.new, Module.new
  end

  def test_freeze
    assert_send_type  '() -> KernelInstanceTest::JustKernel',
                      JustKernel.new, :freeze
  end

  def test_frozen?
    assert_send_type  '() -> bool',
                      JustKernel.new, :frozen?

    assert_send_type  '() -> bool',
                      JustKernel.new.freeze, :frozen?
  end

  def test_hash
    assert_send_type  '() -> Integer',
                      OBJ, :hash
  end

  def test_inspect
    assert_send_type  '() -> String',
                      OBJ, :inspect
  end

  def test_instance_of?
    with Class, Kernel, BasicObject, JustKernel, Integer, Enumerable do |class_or_module|
      assert_send_type  '(Class | Module) -> bool',
                        OBJ, :instance_of?, class_or_module
    end
  end

  def test_instance_variable_defined?
    obj = JustKernel.new

    obj.instance_variable_set(:@s, 3)
    with_interned :@s do |variable|
      assert_send_type  '(interned) -> bool',
                        obj, :instance_variable_defined?, variable
    end

    with_interned :@p do |variable|
      assert_send_type  '(interned) -> bool',
                        obj, :instance_variable_defined?, variable
    end
  end

  def test_instance_variable_get
    obj = JustKernel.new

    obj.instance_variable_set(:@s, 3)
    with_interned :@s do |variable|
      assert_send_type  '(interned) -> untyped',
                        obj, :instance_variable_get, variable
    end
  end

  def test_instance_variable_set
    obj = JustKernel.new

    with_untyped do |value|
      with_interned :@s do |variable|
        assert_send_type  '[T] (interned, T) -> T',
                          obj, :instance_variable_set, variable, value
      end
    end
  end

  def test_instance_variables
    obj = JustKernel.new

    assert_send_type  '() -> Array[Symbol]',
                      obj, :instance_variables

    obj.instance_variable_set(:@s, 3)
    assert_send_type  '() -> Array[Symbol]',
                      obj, :instance_variables
  end

  def test_is_a?(method: :is_a?)
    with Class, Kernel, BasicObject, JustKernel, Integer, Enumerable do |class_or_module|
      assert_send_type  '(Class | Module) -> bool',
                        OBJ, method, class_or_module
    end
  end

  def test_kind_of?
    test_is_a?(method: :kind_of?)
  end

  def test_itself
    assert_send_type  '() -> KernelInstanceTest::JustKernel',
                      OBJ, :itself
  end

  def test_method
    with_interned :method do |name|
      assert_send_type  '(interned) -> Method',
                        OBJ, :method, name
    end
  end

  def test_methods
    obj = JustKernel.new
    class << obj
      private def foo = 34
      protected def bar = 34
      public def baz = 34
    end

    assert_send_type  '() -> Array[Symbol]',
                      obj, :methods

    with_boolish do |boolish|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        obj, :methods, boolish
    end
  end

  def test_nil?
    assert_send_type  '() -> false',
                      OBJ, :nil?
  end

  def test_object_id
    assert_send_type  '() -> Integer',
                      OBJ, :object_id
  end

  def test_private_methods
    obj = JustKernel.new
    class << obj
      private def foo = 34
    end

    assert_send_type  '() -> Array[Symbol]',
                      obj, :private_methods

    with_boolish do |boolish|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        obj, :private_methods, boolish
    end
  end

  def test_protected_methods
    obj = JustKernel.new
    class << obj
      protected def foo = 34
    end

    assert_send_type  '() -> Array[Symbol]',
                      obj, :protected_methods

    with_boolish do |boolish|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        obj, :protected_methods, boolish
    end
  end

  def test_public_method
    with_interned :public_method do |name|
      assert_send_type  '(interned) -> Method',
                        OBJ, :public_method, name
    end
  end

  def test_public_methods
    assert_send_type  '() -> Array[Symbol]',
                      OBJ, :public_methods

    with_boolish do |boolish|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        OBJ, :public_methods, boolish
    end
  end

  def test_public_send
    obj = JustKernel.new
    def obj.foo(...) = nil

    with_interned :foo do |name|
      assert_send_type  '(interned, *untyped, **untyped) -> untyped',
                        obj, :public_send, name, 1, a: 2r
      assert_send_type  '(interned, *untyped, **untyped) { (?) -> untyped } -> untyped',
                        obj, :public_send, name, 1, a: 2r do 3i end
    end
  end

  def test_remove_instance_variable
    obj = JustKernel.new

    with_interned :@s do |variable|
      obj.instance_variable_set(:@s, 3)

      assert_send_type  '(interned) -> untyped',
                        obj, :remove_instance_variable, variable
    end
  end

  def test_respond_to?
    with_interned :respond_to? do |name|
      assert_send_type  '(interned) -> bool',
                        OBJ, :respond_to?, name
    end

    with_interned :__rbs_method_doesnt_exist do |name|
      assert_send_type  '(interned) -> bool',
                        OBJ, :respond_to?, name
    end
  end

  def test_send
    obj = JustKernel.new
    def obj.foo(...) = nil

    with_interned :foo do |name|
      assert_send_type  '(interned, *untyped, **untyped) -> untyped',
                        obj, :send, name, 1, a: 2r
      assert_send_type  '(interned, *untyped, **untyped) { (?) -> untyped } -> untyped',
                        obj, :send, name, 1, a: 2r do 3i end
    end
  end

  def test_singleton_class
    assert_send_type  '() -> Class',
                      OBJ, :singleton_class
  end

  def test_singleton_method
    obj = JustKernel.new
    class << obj
      protected def foo = 34
    end

    with_interned :foo do |name|
      assert_send_type  '(interned) -> Method',
                        obj, :singleton_method, name
    end
  end

  def test_singleton_methods
    obj = JustKernel.new
    class << obj
      private def foo = 34
      protected def bar = 34
      public def baz = 34
    end

    assert_send_type  '() -> Array[Symbol]',
                      obj, :singleton_methods

    with_boolish do |boolish|
      assert_send_type  '(boolish) -> Array[Symbol]',
                        obj, :singleton_methods, boolish
    end
  end

  def test_tap
    assert_send_type  '() { (KernelInstanceTest::JustKernel) -> void } -> KernelInstanceTest::JustKernel',
                      OBJ, :tap do end
  end

  def test_to_s
    assert_send_type  '() -> String',
                      OBJ, :to_s
  end

  def test_yield_self(method: :yield_self)
    assert_send_type  '() -> Enumerator[KernelInstanceTest::JustKernel, untyped]',
                      OBJ, method
    assert_send_type  '[T] () { (KernelInstanceTest::JustKernel) -> T } -> T',
                      OBJ, method do 1r end
  end

  def test_then
    test_yield_self(method: :then)
  end

  def test_initialize_copy
    assert_send_type  '(KernelInstanceTest::JustKernel) -> KernelInstanceTest::JustKernel',
                      JustKernel.allocate, :initialize_copy, OBJ
  end

  def test_initialize_clone
    assert_send_type  '(KernelInstanceTest::JustKernel) -> KernelInstanceTest::JustKernel',
                      JustKernel.allocate, :initialize_clone, OBJ

    with_bool.and_nil do |freeze|
      assert_send_type  '(KernelInstanceTest::JustKernel, freeze: bool?) -> KernelInstanceTest::JustKernel',
                        JustKernel.allocate, :initialize_clone, OBJ, freeze: freeze
    end
  end

  def test_initialize_dup
    assert_send_type  '(KernelInstanceTest::JustKernel) -> KernelInstanceTest::JustKernel',
                      JustKernel.allocate, :initialize_dup, OBJ
  end
end
