require_relative "test_helper"

class MatchDataTest < StdlibTest
  target MatchData
  using hook.refinement

  # test_==
  def test_equal
    foo = 'foo'
    foo.match('f') == foo.match('f')
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

  def test_end
    /(?<first>foo)(?<second>bar)(?<third>Baz)?/ =~ "foobarbaz"
    $~.end 0
    $~.end 3
    $~.end 'first'
    $~.end 'third'
    $~.end :first
    $~.end :third 
  end

  def test_eql?
    foo = 'foo'
    foo.match('f').eql? foo.match('f')
  end

  def test_hash
    'foo'.match('f').hash
  end

  def test_inspect
    'foo'.match('f').inspect
  end

  def test_length
    'foo'.match('f').length
  end
end