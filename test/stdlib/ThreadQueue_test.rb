# frozen_string_literal: true

require_relative "test_helper"
require "thread"

class Thread__Queue__InstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Thread::Queue[::Integer]"

  def test_push
    queue = Thread::Queue.new

    assert_send_type(
      "(::Integer) -> void",
      queue, :push, 1
    )
  end

  def test_length
    queue = Thread::Queue.new

    assert_send_type(
      "() -> ::Integer",
      queue, :length
    )
  end

  def test_num_waiting
    queue = Thread::Queue.new

    assert_send_type(
      "() -> ::Integer",
      queue, :num_waiting
    )
  end

  def test_empty?
    queue = Thread::Queue.new

    assert_send_type(
      "() -> bool",
      queue, :empty?
    )
  end

  def test_closed?
    queue = Thread::Queue.new

    assert_send_type(
      "() -> bool",
      queue, :closed?
    )
  end

  def test_close
    queue = Thread::Queue.new

    assert_send_type(
      "() -> void",
      queue, :close
    )
  end

  def test_clear
    queue = Thread::Queue.new

    assert_send_type(
      "() -> void",
      queue, :clear
    )
  end

  def test_pop
    queue = Thread::Queue.new

    queue.push(1)

    # Get an Integer from the queue
    assert_send_type(
      "() -> ::Integer",
      queue, :pop
    )

    queue.push(2)

    # Get an Integer from the queue with timeout
    assert_send_type(
      "(timeout: ::Float) -> ::Integer",
      queue, :pop, timeout: 0.1
    )

    queue.push(3)

    # Get an Integer from the queue with `nil` timeout
    assert_send_type(
      "(timeout: nil) -> ::Integer",
      queue, :pop, timeout: nil
    )

    # Returns `nil` when the queue is empty and with timeout
    assert_send_type(
      "(timeout: ::Float) -> nil",
      queue, :pop, timeout: 0.0
    )

    queue.push(4)

    # With nonblocking is true, but queue is not empty
    assert_send_type(
      "(bool) -> ::Integer",
      queue, :pop, true
    )

    # Raises an exception with nonblocking but queue is empty
    begin
      assert_send_type(
        "(bool) -> bot",
        queue, :pop, true
      )
    rescue ThreadError
    end

    queue.close()

    # Returns `nil` if the queue is closed
    assert_send_type(
      "() -> nil",
      queue, :pop
    )
  end
end


class Thread__SizedQueue__InstanceTest < Test::Unit::TestCase
  include TestHelper

  testing "::Thread::SizedQueue[::Integer]"

  def test_max
    queue = Thread::SizedQueue.new(10)

    assert_send_type(
      "() -> ::Integer",
      queue, :max
    )
  end

  def test_max=
    queue = Thread::SizedQueue.new(10)

    assert_send_type(
      "(::Integer) -> ::Integer",
      queue, :max=, 20
    )
  end

  def test_push
    queue = Thread::SizedQueue.new(1)

    assert_send_type(
      "(::Integer) -> void",
      queue, :push, 1
    )

    queue.pop

    # Nonblocking mode: queue is not full
    assert_send_type(
      "(::Integer, bool) -> void",
      queue, :push, 2, true
    )

    # Nonblocking mode: queue is full
    begin
      assert_send_type(
        "(::Integer, bool) -> bot",
        queue, :push, 3, true
      )
    rescue ThreadError
    end

    queue.pop

    # With timeout: queue is not full
    assert_send_type(
      "(::Integer, timeout: Float) -> ::Thread::SizedQueue[::Integer]",
      queue, :push, 3, timeout: 0.3
    )

    # With timeout: queue is full
    assert_send_type(
      "(::Integer, timeout: Float) -> nil",
      queue, :push, 4, timeout: 0.0
    )
  end
end
