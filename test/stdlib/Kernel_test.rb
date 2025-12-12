require_relative "test_helper"

require "securerandom"

class KernelSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing "singleton(::Kernel)"

  def test_Array
    assert_send_type "(nil) -> []",
                     Kernel, :Array, nil

    with_untyped do |ele|
      with_array(ele, ele).and ToA.new(ele, ele) do |ary|
        assert_send_type "[T] (array[T] | _ToA[T]) -> Array[T]",
                         Kernel, :Array, ary
      end

      next if defined?(ele.to_a) || defined?(ele.to_ary)
      assert_send_type "[T] (T) -> [T]",
                       Kernel, :Array, ele
    end
  end

  def test_Complex
    # (_ToC complex_like, ?exception: true) -> Complex
    assert_send_type "(_ToC) -> Complex",
                     Kernel, :Complex, ToC.new
    assert_send_type "(_ToC, exception: true) -> Complex",
                     Kernel, :Complex, ToC.new, exception: true

    # (_ToC complex_like, exception: bool) -> Complex?
    assert_send_type "(_ToC, exception: bool) -> Complex",
                     Kernel, :Complex, ToC.new, exception: false
    assert_send_type "(_ToC, exception: bool) -> nil",
                     Kernel, :Complex, Class.new(BlankSlate){ def to_c = fail }.new, exception: false

    numeric = Class.new(Numeric).new

    # (Numeric numeric, ?exception: bool) -> Complex
    with 1, 1r, 1.0, (1+0i), numeric do |real|
      assert_send_type "(Numeric) -> Complex",
                       Kernel, :Complex, real

      # Single `Numeric`s can never fail
      with_bool do |exception|
        assert_send_type "(Numeric, exception: bool) -> Complex",
                         Kernel, :Complex, real, exception: exception
      end
    end

    # (String real_or_both, ?exception: true) -> Complex
    assert_send_type "(String) -> Complex",
                     Kernel, :Complex, '1'
    assert_send_type "(String, exception: true) -> Complex",
                     Kernel, :Complex, '1', exception: true

    # (untyped real_or_both, exception: bool) -> Complex?
    with_untyped.and 'oops' do |real_untype|
      assert_send_type '(untyped, exception: bool) -> Complex?',
                       Kernel, :Complex, real_untype, exception: false
    end

    with '1', 1, 1r, 1.0, (1+0i), numeric do |real|
      with '2', 2, 2r, 2.0, (2+0i), numeric do |imag|
        # (Numeric | String real, Numeric | String imag, ?exception: true) -> Complex
        assert_send_type "(Numeric | String, Numeric | String) -> Complex",
                         Kernel, :Complex, real, imag
        assert_send_type "(Numeric | String, Numeric | String, exception: true) -> Complex",
                         Kernel, :Complex, real, imag, exception: true

        # Complex has an awkward edgecase where `exception: false` will unconditionally return `nil`
        # if the imaginary argument is not one of the builtin `Numeric`s. Oddly enough, it's not for
        # the `real` one...
        case imag
        when Integer, Float, Rational, Complex
          # (Numeric | String real, Integer | Float | Rational | Complex imag, exception: bool) -> Complex
          assert_send_type "(Numeric | String, Integer | Float | Rational | Complex, exception: bool) -> Complex",
                           Kernel, :Complex, real, imag, exception: false
        end
      end

      # (Numeric | String real, untyped, exception: bool) -> Complex?
      with_untyped.and 'oops', numeric do |imag|
        next if [Integer, Float, Rational, Complex].any? { _1 === imag }
        assert_send_type "(Numeric | String, untyped, exception: bool) -> nil",
                         Kernel, :Complex, real, imag, exception: false
      end
    end
  end


  def test_Float
    with 1, 1.0, ToF.new(1.0), '1e3' do |float_like|
      assert_send_type "(_ToF) -> Float",
                       Kernel, :Float, float_like
      assert_send_type "(_ToF, exception: true) -> Float",
                       Kernel, :Float, float_like, exception: true
      assert_send_type "(_ToF, exception: bool) -> Float",
                       Kernel, :Float, float_like, exception: false
    end

    with_untyped do |untyped|
      next if defined? untyped.to_f
      assert_send_type "(untyped, exception: bool) -> nil",
                       Kernel, :Float, untyped, exception: false
    end
  end

  def test_Hash
    assert_send_type "[K, V] (nil) -> Hash[K, V]",
                     Kernel, :Hash, nil
    assert_send_type "[K, V] ([]) -> Hash[K, V]",
                     Kernel, :Hash, []

    with_hash 'a' => 3 do |hash|
      assert_send_type "[K, V] (hash[K, V]) -> Hash[K, V]",
                       Kernel, :Hash, hash
    end
  end

  def test_Integer
    with_int.and ToI.new do |int|
      assert_send_type "(int | _ToI) -> Integer",
                       Kernel, :Integer, int
      assert_send_type "(int | _ToI, exception: true) -> Integer",
                       Kernel, :Integer, int, exception: true
      assert_send_type "(int | _ToI, exception: bool) -> Integer?",
                       Kernel, :Integer, int, exception: false
    end

    with_string "123" do |string|
      with_int 8 do |base|
        assert_send_type "(string, int) -> Integer",
                         Kernel, :Integer, string, base
        assert_send_type "(string, int, exception: true) -> Integer",
                         Kernel, :Integer, string, base, exception: true
        assert_send_type "(string, int, exception: bool) -> Integer?",
                         Kernel, :Integer, string, base, exception: false
      end
    end

    with_untyped do |untyped|
      assert_send_type "(untyped, exception: bool) -> Integer?",
                       Kernel, :Integer, untyped, exception: false

      with_int 10 do |base|
        assert_send_type "(untyped, int, exception: bool) -> Integer?",
                         Kernel, :Integer, untyped, base, exception: false
      end
    end
  end

  def test_Rational
    with_int(1).and ToR.new(1r) do |numer|
      assert_send_type "(int | _ToR) -> Rational",
                       Kernel, :Rational, numer
      assert_send_type "(int | _ToR, exception: true) -> Rational",
                       Kernel, :Rational, numer, exception: true
      assert_send_type "(int | _ToR, exception: bool) -> Rational",
                       Kernel, :Rational, numer, exception: false

      with_int(2).and ToR.new(2r) do |denom|
        assert_send_type "(int | _ToR, int | _ToR) -> Rational",
                         Kernel, :Rational, numer, denom
        assert_send_type "(int | _ToR, int | _ToR, exception: true) -> Rational",
                         Kernel, :Rational, numer, denom, exception: true
        assert_send_type "(int | _ToR, int | _ToR, exception: bool) -> Rational",
                         Kernel, :Rational, numer, denom, exception: false
      end
    end

    bad_int = Class.new(BlankSlate){ def to_int = fail }.new
    bad_rat = Class.new(BlankSlate){ def to_r = fail }.new
    with bad_int, bad_rat do |bad_numer|
      assert_send_type "(int | _ToR, exception: bool) -> nil",
                       Kernel, :Rational, bad_numer, exception: false
      assert_send_type "(int | _ToR, int | _ToR, exception: bool) -> nil",
                       Kernel, :Rational, bad_numer, bad_numer, exception: false
    end


    numeric = Class.new(Numeric).new
    assert_send_type "[T < _Numeric] (T numer, 1) -> T",
                     Kernel, :Rational, numeric, 1
    assert_send_type "[T < _Numeric] (T numer, 1, exception: bool) -> T",
                     Kernel, :Rational, numeric, 1, exception: true
    assert_send_type "[T < _Numeric] (T numer, 1, exception: bool) -> T",
                     Kernel, :Rational, numeric, 1, exception: false

    numeric_div = Class.new(Numeric){ def /(other) = :hello }.new

    assert_send_type "[T] (Numeric & Kernel::_RationalDiv[T] numer, Numeric denom) -> T",
                     Kernel, :Rational, numeric_div, numeric
    assert_send_type "[T] (Numeric & Kernel::_RationalDiv[T] numer, Numeric denom, exception: bool) -> T",
                     Kernel, :Rational, numeric_div, numeric, exception: true
    assert_send_type "[T] (Numeric & Kernel::_RationalDiv[T] numer, Numeric denom, exception: bool) -> T",
                     Kernel, :Rational, numeric_div, numeric, exception: false

    with_untyped do |numer|
      with_untyped do |denom|
        assert_send_type "(untyped, untyped, exception: bool) -> Rational?",
                         Kernel, :Rational, numer, denom, exception: false
      end
    end
  end

  def test_String
    with_string do |string|
      assert_send_type "(string) -> String",
                       Kernel, :String, string
    end

    assert_send_type "(_ToS) -> String",
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

  def test_proc
    assert_send_type "() { () -> untyped } -> Proc", Kernel, :proc do end
    assert_send_type "() { () -> untyped } -> Proc", Kernel, :proc do |a, b| end
  end

  def test_rand
    assert_send_type "() -> Float", Kernel, :rand
    assert_send_type "(0) -> Float", Kernel, :rand, 0
    assert_send_type "(_ToInt) -> Float", Kernel, :rand, 0.0
    assert_send_type "(_ToInt) -> Float", Kernel, :rand, 0r
    assert_send_type "(_ToInt) -> Float", Kernel, :rand, 0i
    assert_send_type "(_ToInt) -> Integer", Kernel, :rand, 10
    assert_send_type "(Range[Integer]) -> Integer", Kernel, :rand, 1..10
    assert_send_type "(Range[Integer]) -> nil", Kernel, :rand, 0...0
    assert_send_type "(Range[Float]) -> Float", Kernel, :rand, 0.0...10.0
    assert_send_type "(Range[Float]) -> nil", Kernel, :rand, 0.0...0.0
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
    $stdout = old_stdout
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

  def test_system
    with_bool do |exception|
      assert_send_type '(String, exception: bool) -> bool',
                       Kernel, :system, ":", exception: exception
    end
  end

  class TestException < Exception
  end

  def test_raise
    begin
      assert_send_type(
        "(_Exception, String, Array[String]) -> bot",
        JustKernel.new, :raise, TestException, "test message", ["location.rb:123"]
      )
    rescue TestException
    end

    begin
      assert_send_type(
        "(_Exception, String, String) -> bot",
        JustKernel.new, :raise, TestException, "test message", "location.rb:123"
      )
    rescue TestException
    end

    if_ruby("3.4"..., skip: false) do
      begin
        assert_send_type(
          "(_Exception, String, Array[Thread::Backtrace::Location]) -> bot",
          JustKernel.new, :raise, TestException, "test message", [caller_locations[0]]
        )
      rescue TestException
      end
    end
  end

  def test_readlines
    $stdin = File.open(__FILE__)

    assert_send_type(
      "() -> Array[String]",
      JustKernel.new, :readlines
    )

    with_int(3) do |limit|
      with_string(",") do |separator|
        $stdin = File.open(__FILE__)
        assert_send_type(
          "(string, int, chomp: bool) -> Array[String]",
          JustKernel.new, :readlines, ",", 3, chomp: true
        )
      end
    end
  ensure
    $stdin = STDIN
  end
end
