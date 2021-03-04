require "test_helper"

class RBS::CharScannerTest < Test::Unit::TestCase
  def test_charpos
    scanner = RBS::CharScanner.new("ABC日本語テキスト")

    scanner.scan(/.../)
    assert_equal 3, scanner.pos
    assert_equal 3, scanner.charpos

    scanner.scan(/.../)
    assert_equal 12, scanner.pos
    assert_equal 6, scanner.charpos
end
end
