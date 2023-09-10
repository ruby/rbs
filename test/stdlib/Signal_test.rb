require_relative 'test_helper'

class SignalSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing 'singleton(::Signal)'

  def test_list
    assert_send_type  '() -> Hash[String, Integer]',
                      Signal, :list
  end

  def test_signame
    with_int 0 do |int|
      assert_send_type  '(::int) -> String?',
                        Signal, :signame, int
    end

    with_int -1 do |int|
      assert_send_type  '(::int) -> Signal?',
                        Signal, :signame, int
    end
  end

  def test_trap
    old_usr2 = trap(:USR2, nil)

    with_interned(:USR2).chain([Signal.list['USR2']]).each do |signal|
      assert_send_type  '(Integer | ::interned) { (Integer) -> void } -> Signal::trap_command',
                        Signal, :trap, signal do |n| end

      with_string('').chain([true, false, nil, Class.new{def call(x)end}.new]).each do |command|
        assert_send_type  '(Integer | ::interned, Signal::trap_command) -> Signal::trap_command',
                          Signal, :trap, signal, command
      end
    end

  ensure
    trap(:USR2, old_usr2)
  end
end
