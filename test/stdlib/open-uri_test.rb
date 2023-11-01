require_relative "test_helper"
require "open-uri"

class OpenURISingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "open-uri"
  testing "singleton(::URI)"

  def test_URI_open
    assert_send_type "(String) -> StringIO",
                     URI, :open, "https://www.ruby-lang.org"
    assert_send_type "(String) { (StringIO) -> String } -> String",
                     URI, :open, "https://www.ruby-lang.org" do |io| io.read end
  end
end
