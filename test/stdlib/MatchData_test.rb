require_relative "test_helper"

class MatchDataTest < StdlibTest
  target MatchData
  using hook.refinement

  # test_==
  def test_equal
    /re/ == /re/
  end
end