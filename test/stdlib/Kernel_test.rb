require_relative "test_helper"

require "securerandom"

class KernelSingletonTest < Test::Unit::TestCase
  include TestHelper

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
