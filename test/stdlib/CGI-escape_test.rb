require_relative "test_helper"
require "cgi"

class CGI__EscapeSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "cgi-escape"
  testing "singleton(::CGI)"

  def test_escapeURIComponent
    assert_send_type(
      "(String) -> String",
      CGI, :escapeURIComponent, "hogehoge"
    )
    assert_send_type(
      "(ToStr) -> String",
      CGI, :escapeURIComponent, ToStr.new("hogehoge")
    )
  end

  def test_unescapeURIComponent
    assert_send_type(
      "(String) -> String",
      CGI, :unescapeURIComponent, "hogehoge"
    )
    assert_send_type(
      "(ToStr) -> String",
      CGI, :unescapeURIComponent, ToStr.new("hogehoge")
    )
  end
end
