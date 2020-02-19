require_relative "test_helper"

class MatchDataTest < StdlibTest
  target MatchData
  using hook.refinement

  # test_==
  def test_equal
    /re/ == /re/
  end

  # test_[]
  def test_square_bracket
    /(?<first>foo)(?<second>bar)(?<third>Baz)?/ =~ "foobarbaz"
    $~[0]
    $~[3]
    $~[0..2]
    $~[0, 3]
    $~['first']
    $~['third']
    $~[:first]
    $~[:third]
  end

  # test_begin
  def test_begin
    /(?<first>foo)(?<second>bar)(?<third>Baz)?/ =~ "foobarbaz"
    $~.begin 0
    $~.begin 3
    $~.begin 'first'
    $~.begin 'third'
    $~.begin :first
    $~.begin :third
  end

  def test_caputres
    /(?<first>foo)(?<second>bar)(?<third>Baz)?/ =~ "foobarbaz"
    $~.captures
  end
end