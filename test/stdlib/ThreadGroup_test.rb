require_relative "test_helper"

class ThreadGroupTest < StdlibTest
  target ThreadGroup
  using hook.refinement

  def test_add
    tg = ThreadGroup.new
    tg.add(Thread.new {})
  end

  def test_enclose
    tg = ThreadGroup.new
    tg.enclose
  end

  def test_enclosed?
    tg = ThreadGroup.new
    tg.enclosed?
    tg.enclose
    tg.enclosed?
  end

  def test_list
    tg = ThreadGroup.new
    tg.list
    tg.add(Thread.new {})
    tg.list
  end
end
