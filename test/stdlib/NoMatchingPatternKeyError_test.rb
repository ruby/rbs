require_relative "test_helper"

class NoMatchingPatternKeyErrorSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::NoMatchingPatternKeyError)"


  def test_new
    assert_send_type  "[Matchee, Key] (?::string message, matchee: Integer, key: Integer) -> ::NoMatchingPatternKeyError[Integer, Integer]",
                      NoMatchingPatternKeyError, :new, matchee: 123, key: 234
  end
end

class NoMatchingPatternKeyErrorTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::NoMatchingPatternKeyError[Hash[Symbol, untyped], Symbol]"


  def test_initialize
    assert_send_type  "(?::string message, matchee: Hash[Symbol, untyped], key: Symbol) -> void",
                      NoMatchingPatternKeyError.new(matchee: {a: 1}, key: :aa), :initialize, matchee: {a: 1}, key: :aa
  end

  def test_matchee
    assert_send_type  "() -> Hash[Symbol, untyped]",
                      NoMatchingPatternKeyError.new(matchee: {a: 1}, key: :aa), :matchee
  end

  def test_key
    assert_send_type  "() -> Symbol",
                      NoMatchingPatternKeyError.new(matchee: {a: 1}, key: :aa), :key
  end
end
