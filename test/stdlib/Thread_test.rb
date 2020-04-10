require_relative "test_helper"

class ThreadTest < StdlibTest
  target Thread
  using hook.refinement

  def test_class_method_fork
    Thread.fork(1) do |x|
      x
    end
  end

  def test_class_method_exit
    Thread.new do
      Thread.exit
    end
  end

  def test_class_method_current
    Thread.current
  end

  def test_class_method_main
    Thread.main
  end

  def test_class_method_abort_on_exception
    Thread.abort_on_exception
  end

  def test_class_method_abort_on_exception=
    original = Thread.abort_on_exception
    Thread.abort_on_exception = true
    Thread.abort_on_exception = false
    Thread.abort_on_exception = original
  end

  def test_class_method_exclusive
    Thread.exclusive do
      1
    end
  end

  def test_class_method_handle_interrupt
    Thread.handle_interrupt(RuntimeError => :immediate) do
      1
    end
  end

  def test_class_method_kill
    t = Thread.new {}
    Thread.kill(t)
  end

  def test_class_method_list
    Thread.list
  end

  def test_class_method_pass
    Thread.pass
  end

  def test_class_method_pending_interrupt?
    Thread.pending_interrupt?
    Thread.pending_interrupt?(RuntimeError)
  end

  def test_class_method_report_on_exception
    Thread.report_on_exception
  end

  def test_class_method_report_on_exception=
    original = Thread.report_on_exception
    Thread.report_on_exception = true
    Thread.report_on_exception = false
    Thread.report_on_exception = original
  end

  def test_class_method_start
    Thread.start(1) do |x|
      x
    end
  end

  def test_class_method_stop
    Thread.new do
      Thread.stop
    end
  end

  def test_initialize
    Thread.new do
    end
  end

  def test_exit
    t = Thread.new {}
    t.exit
  end

  def test_square_bracket
    t = Thread.new {}
    t['a']
    t[:a]
    t[:a] = 1
    t['a']
    t[:a]
  end

  def test_square_bracket_assign
    t = Thread.new {}
    t['a'] = 1
    t[:a] = 1
  end

  def test_alive?
    Thread.current.alive?
  end

  def test_kill
    Thread.new do
      Thread.current.kill
    end
  end

  def test_abort_on_exception
    Thread.current.abort_on_exception
  end

  def test_abort_on_exception=
    original = Thread.current.abort_on_exception
    Thread.current.abort_on_exception = true
    Thread.current.abort_on_exception = false
    Thread.current.abort_on_exception = original
  end

  def test_add_trace_func
    t = Thread.new {}
    t.add_trace_func(-> (*) {})
  end

  def test_backtrace
    Thread.current.backtrace
  end

  def test_backtrace_locations
    Thread.current.backtrace_locations
    Thread.current.backtrace_locations(1)
    Thread.current.backtrace_locations(1, 1)
    Thread.current.backtrace_locations(0..1)
  end

  def test_fetch
    t = Thread.new {}
    t['a'] = 1
    t.fetch('a')
    t.fetch(:b, 1)
  end

  def test_group
    Thread.current.group
  end

  def test_join
    t = Thread.new {}
    t.join
    t.join(1)
  end

  def test_key?
    t = Thread.new {}
    t.key?('a')
    t.key?(:a)
  end

  def test_keys
    t = Thread.new {}
    t['a'] = 1
    t[:a] = 1
    t.keys
  end

  def test_name
    Thread.current.name
    t = Thread.new {}
    t.name
  end

  def test_name=
    t = Thread.new {}
    t.name = '1'
  end

  def test_pending_interrupt?
    Thread.current.pending_interrupt?
  end

  def test_priority
    Thread.current.priority
  end

  def test_priority=
    t = Thread.new {}
    t.priority = 1
  end

  def test_report_on_exception
    Thread.current.report_on_exception
  end

  def test_report_on_exception=
    t = Thread.new {}
    t.report_on_exception = true
    t.report_on_exception = false
  end

  def test_run
    Thread.current.run
  end

  def test_safe_level
    Thread.current.safe_level
  end

  def test_status
    threads = []
    threads << Thread.new {}
    threads << Thread.new {
      Thread.current.report_on_exception = false
      Thread.current.abort_on_exception = false
      raise
    }
    threads.each(&:status)
    threads.each(&:join) rescue nil
    threads.each(&:status)
  end

  def test_stop?
    Thread.current.stop?
  end

  def test_terminate
    t = Thread.new {}
    t.terminate
  end

  def test_thread_variable?
    t = Thread.new {}
    t.thread_variable?('a')
    t.thread_variable?(:a)
    t[:a] = 1
    t.thread_variable?('a')
    t.thread_variable?(:a)
  end

  def test_thread_variable_get
    t = Thread.new {}
    t.thread_variable_get('a')
    t.thread_variable_get(:a)
    t[:a] = 1
    t.thread_variable_get('a')
    t.thread_variable_get(:a)
  end

  def test_thread_variable_set
    t = Thread.new {}
    t.thread_variable_set('a', 1)
    t.thread_variable_set(:a, 1)
  end

  def test_thread_variables
    Thread.current.thread_variables
  end

  def test_value
    t = Thread.new {}
    t.value
  end

  def test_wakeup
    Thread.current.wakeup
  end
end
