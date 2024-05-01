require_relative "test_helper"

class ThreadGroupInstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::ThreadGroup"

  def test_Default
    assert_const_type 'ThreadGroup', 'ThreadGroup::Default'
  end

  def test_add
    thr = Thread.new{}
    assert_send_type  '(Thread) -> ::ThreadGroup',
                      ThreadGroup.new, :add, thr
  ensure
    thr.kill
  end

  def test_enclose
    assert_send_type  '() -> ::ThreadGroup',
                      ThreadGroup.new, :enclose
  end

  def test_enclosed?
    tg = ThreadGroup.new

    assert_send_type  '() -> bool',
                      tg, :enclosed?

    tg.enclose

    assert_send_type  '() -> bool',
                      tg, :enclosed?
  end

  def test_list
    tg = ThreadGroup.new
    thr = Thread.new{}

    assert_send_type  '() -> Array[Thread]',
                      tg, :list

    tg.add(thr)

    assert_send_type  '() -> Array[Thread]',
                      tg, :list
  ensure
    thr.kill
  end
end
