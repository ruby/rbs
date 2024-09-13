require_relative 'test_helper'

class TracePointSingletonTest < Test::Unit::TestCase
  include TestHelper

  testing 'singleton(::TracePoint)'

  MyTracePoint = Class.new(TracePoint)

  def test_new
    assert_send_type  '(*::_ToSym) { (TracePointSingletonTest::MyTracePoint tp) -> void } -> TracePointSingletonTest::MyTracePoint',
                      MyTracePoint, :new, :line, ToSym.new(:line) do end
  end

  def test_allow_reentry
    tp = TracePoint.new :script_compiled do
      assert_send_type  '[T] () { (nil) -> T } -> T',
                        TracePoint, :allow_reentry do 1r end
    end
    tp.enable

    eval("1") # some no-op to trigger the tracepoint
  ensure
    tp.disable
  end

  def test_stat
    assert_send_type  '() -> untyped',
                      TracePoint, :stat
  end

  def test_trace
    # Make sure to pick a tracepoint that won't be accidentaly called, to prevent loops.
    tp = assert_send_type  '(*::_ToSym) { (TracePointSingletonTest::MyTracePoint tp) -> void } -> TracePointSingletonTest::MyTracePoint',
                           MyTracePoint, :trace, :script_compiled, ToSym.new(:script_compiled) do end
    tp.disable
  end
end

class TracePointTest < Test::Unit::TestCase
  include TestHelper

  testing '::TracePoint'

  def tracepoint(event=:line, do: proc{ 1 }, &tp_body)
    tp = TracePoint.new(event, &tp_body)
    tp.enable(&binding.local_variable_get(:do))
  ensure
    tp.disable
  end
  
  def test_binding
    tracepoint do |tp|
      assert_send_type  '() -> Binding',
                        tp, :binding
    end

    tracepoint :c_call, do: method(:print) do |tp|
      assert_send_type  '() -> nil',
                        tp, :binding
    end
  end

  TracePoint.new(:b_return) { |tp|
    const_set :CALLEE_ID_OUTSIDE_OF_A_METHOD, tp.callee_id
    const_set :METHOD_ID_OUTSIDE_OF_A_METHOD, tp.method_id
  }.enable { }
  def test_callee_id
    tracepoint do |tp|
      assert_send_type  '() -> Symbol',
                        tp, :callee_id
    end

    # No way to make the `callee_id` nil, as we're in a method already.
    assert_type 'nil', CALLEE_ID_OUTSIDE_OF_A_METHOD
  end
  
  def test_defined_class
    tracepoint do |tp|
      assert_send_type  '() -> (Class | Method)',
                        tp, :defined_class
    end

    tracepoint :end, do: proc{ eval("class X; proc{}.call end") }  do |tp|
      assert_send_type  '() -> nil',
                        tp, :defined_class
    end
  end
  
  def test_disable
    tracepoint do |tp|
      assert_send_type  '() -> bool',
                        tp, :disable

      assert_send_type  '[T] () { () -> T } -> T',
                        tp, :disable do end
    end
  end
  
  def test_enable
    # can't use the `tracepoint` helper here, because we're testing `enable`

    begin
      tp = TracePoint.new {}
      assert_send_type  '() -> bool',
                        tp, :enable
      assert_send_type  '[T] () { () -> T } -> T',
                        tp, :enable do 1r end
    ensure
      tp.disable
    end

    with(method(__method__), RubyVM::InstructionSequence.of(method(__method__)), proc{}).and_nil do |target|
      with_int.and_nil do |line|
        with(Thread.current, :default).and_nil do |thread|
          next if nil == target && nil != line

          begin
            tp = TracePoint.new {}
            assert_send_type  '(target: Method | RubyVM::InstructionSequence | Proc | nil, target_line: int?, target_thread: Thread | :default | nil) -> bool',
                              tp, :enable, target: target, target_line: line, target_thread: thread
          ensure
            tp.disable
          end

          begin
            tp = TracePoint.new {}
            assert_send_type  '[T] (target: Method | RubyVM::InstructionSequence | Proc | nil, target_line: int?, target_thread: Thread | :default | nil) { () -> T } -> T',
                              tp, :enable, target: target, target_line: line, target_thread: thread do 1r end
          ensure
            tp.disable
          end
        end
      end
    end
  end

  def test_enabled?
    tracepoint do |tp|
      assert_send_type  '() -> bool',
                        tp, :enabled?
    end
  end

  def test_event
    tracepoint do |tp|
      assert_send_type  '() -> Symbol',
                        tp, :event
    end
  end
  
  def test_inspect
    tracepoint do |tp|
      assert_send_type  '() -> String',
                        tp, :inspect
    end
  end
  
  def test_lineno
    tracepoint do |tp|
        assert_send_type  '() -> Integer',
                          tp, :lineno
    end
  end
  
  def test_method_id
    tracepoint do |tp|
      assert_send_type  '() -> Symbol',
                        tp, :method_id
    end

    # No way to make the `method_id` nil, as we're in a method already.
    assert_type 'nil', METHOD_ID_OUTSIDE_OF_A_METHOD
  end
  
  def test_path
    tracepoint do |tp|
      assert_send_type  '() -> String',
                        tp, :path
    end
  end
  
  def test_parameters
    obj = BlankSlate.new
    def obj.some_method(a, b=1, *c, d:, e: 2, **f, &g) = nil

    tracepoint :call, do: proc{obj.some_method(1, d: 2) } do |tp|
      assert_send_type  '() -> Method::param_types',
                        tp, :parameters
    end
  end
  
  def test_raised_exception
    tracepoint :rescue, do: proc{begin; raise; rescue; end} do |tp|
      assert_send_type  '() -> Exception',
                        tp, :raised_exception
    end
  end
  
  def test_return_value
    tracepoint :return do |tp|
      assert_send_type  '() -> untyped',
                        tp, :return_value
    end
  end
  
  def test_self
    tracepoint do |tp|
      assert_send_type  '() -> untyped',
                        tp, :self
    end
  end
  
  def test_eval_script
    # Technically the docs say you can get `-> nil` as a result, but I can't seem to find a way
    # to do that. (And, MRI's tests (such as `test_settracefunc.rb`) don't test for this case).
    # Just in case I'm wrong, I have the return value as `String?`.

    tracepoint :script_compiled, do: proc { eval("") } do |tp|
      assert_send_type  '() -> String',
                        tp, :eval_script
    end
  end
  
  def test_instruction_sequence
    omit 'not on MRI' unless defined?(RubyVM) && defined?(RubyVM::InstructionSequence)

    tracepoint :script_compiled, do: proc { eval("") } do |tp|
      assert_send_type  '() -> RubyVM::InstructionSequence',
                        tp, :instruction_sequence
    end
  end
end
