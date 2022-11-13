require_relative "test_helper"

class TracePointSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::TracePoint)"

  def test_new
    assert_send_type  "(*::Symbol events) { (::TracePoint tp) -> void } -> ::TracePoint",
                      TracePoint, :new, :line do end
  end

  # TODO
  # def test_allow_reentry
  #   assert_send_type  "() { () -> void } -> void",
  #                     TracePoint, :allow_reentry
  # end

  def test_stat
    assert_send_type  "() -> untyped",
                      TracePoint, :stat
  end

  def test_trace
    assert_send_type  "(*::Symbol events) { (::TracePoint tp) -> void } -> ::TracePoint",
                      TracePoint, :trace, :line do |tp| tp.disable end
  end
end

class TracePointTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::TracePoint"

  def test_initialize
    assert_send_type  "(*::Symbol events) { (::TracePoint tp) -> void } -> void",
                      TracePoint.new(:line){}, :initialize do end
  end

  def test_binding
    TracePoint.new(:line) do |tp|
      assert_send_type "() -> ::Binding",
                       tp, :binding
    end.enable { 1 }
  end

  def test_inspect
    TracePoint.new(:line) do |tp|
      assert_send_type "() -> ::String",
                       tp, :inspect
    end.enable { 1 }
  end

  def test_callee_id
    TracePoint.new(:call) do |tp|
      assert_send_type "() -> ::Symbol",
                       tp, :callee_id
    end.enable { 1 }
  end

  def test_defined_class
    TracePoint.new(:call) do |tp|
      assert_send_type "() -> ::Module",
                       tp, :defined_class
    end.enable { 1 }
  end

  def test_disable
    tp = TracePoint.new(:line) {}
    assert_send_type  "() -> bool",
                      tp, :disable
    assert_send_type  "() { () -> void } -> void",
                      tp, :disable do end
  end

  def test_enable
    tp = TracePoint.new(:line) {}
    assert_send_type  "(?target: (::Method | ::UnboundMethod | ::Proc)?, ?target_line: ::Integer?, ?target_thread: ::Thread?) -> bool",
                      tp, :enable
    assert_send_type  "[R] (?target: (::Method | ::UnboundMethod | ::Proc)?, ?target_line: ::Integer?, ?target_thread: ::Thread?) { () -> R } -> R",
                      tp, :enable do end
  end

  def test_enabled?
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> bool",
                        tp, :enabled?
    end.enable { 1 }
  end

  def test_event
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> ::Symbol",
                        tp, :event
    end.enable { 1 }
  end

  def test_lineno
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> ::Integer",
                        tp, :lineno
    end.enable { 1 }
  end

  def test_method_id
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> ::Symbol",
                        tp, :method_id
    end.enable { 1 }
  end

  def test_path
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> ::String",
                        tp, :path
    end.enable { 1 }
  end

  def test_parameters
    TracePoint.new(:call) do |tp|
      assert_send_type  "() -> ::Array[[ :req | :opt | :rest | :keyreq | :key | :keyrest | :block, ::Symbol ] | [ :rest | :keyrest ]]",
                        tp, :parameters
    end.enable { 1 }
  end

  def test_raised_exception
    TracePoint.new(:raise) do |tp|
      assert_send_type  "() -> untyped",
                        tp, :raised_exception
    end.enable { 1 }
  end

  def test_return_value
    TracePoint.new(:call) do |tp|
      assert_send_type  "() -> untyped",
                        tp, :return_value
    end.enable { 1 }
  end

  def test_self
    TracePoint.new(:line) do |tp|
      assert_send_type  "() -> untyped",
                        tp, :self
    end.enable { 1 }
  end

  def test_eval_script
    TracePoint.new(:script_compiled) do |tp|
      assert_send_type  "() -> ::String?",
                        tp, :eval_script
    end.enable { eval("'hello'") }
  end

  def test_instruction_sequence
    TracePoint.new(:script_compiled) do |tp|
      assert_send_type  "() -> ::RubyVM::InstructionSequence",
                        tp, :instruction_sequence
    end.enable { eval("'hello'") }
  end
end
