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
    /(?<lft>foo)(?<rgt>bar)/ =~ "foobarbaz"
    $~[0]
    $~[0..2]
    $~[0, 3]
    $~[:rgt]
  end
end