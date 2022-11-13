require_relative "test_helper"
require 'mutex_m'

class Mutex_mInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library 'mutex_m'
  testing "::Mutex_m"

  def mu
    Object.new.tap do |o|
      o.extend Mutex_m
    end
  end

  def test_mu_lock
    assert_send_type "() -> Thread::Mutex",
                     mu, :mu_lock
  end

  def test_mu_locked?
    mu = mu()
    assert_send_type "() -> false",
                     mu, :mu_locked?
    mu.lock
    assert_send_type "() -> true",
                     mu, :mu_locked?
  end

  def test_mu_synchronize
    assert_send_type "() { () -> String } -> String",
                     mu, :mu_synchronize do 'foo' end
  end

  def test_mu_try_lock
    assert_send_type "() -> bool",
                     mu, :mu_try_lock
  end

  def test_mu_unlock
    mu = mu()
    mu.lock
    assert_send_type "() -> Thread::Mutex",
                     mu, :mu_unlock
  end

  def test_sleep
    mu = mu()
    mu.lock
    assert_send_type "(Integer) -> Integer?",
                     mu, :sleep, 0
    assert_send_type "(Float) -> Integer?",
                     mu, :sleep, 0.1
  end
end
