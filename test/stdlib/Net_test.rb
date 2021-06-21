require_relative "test_helper"
require "net/http"
require "uri"

class NetSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "net-http"
  library "uri"
  testing "singleton(::Net::HTTP)"

  def test_get
    assert_send_type "(URI::Generic, nil, nil) -> nil",
                     Net::HTTP, :get_print, URI("https://www.ruby-lang.org"), nil, nil
    assert_send_type "(URI::Generic, Hash[String, String], Integer) -> nil",
                     Net::HTTP, :get_print, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"}, 443
    assert_send_type "(URI::Generic, nil, nil) -> String",
                     Net::HTTP, :get, URI("https://www.ruby-lang.org"), nil, nil
    assert_send_type "(URI::Generic, Hash[String, String], Integer) -> String",
                     Net::HTTP, :get, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"}, 443
    assert_send_type "(URI::Generic, nil, nil) -> Net::HTTPResponse",
                     Net::HTTP, :get_response, URI("https://www.ruby-lang.org"), nil, nil
    assert_send_type "(URI::Generic, Hash[String, String], Integer) -> Net::HTTPResponse",
                     Net::HTTP, :get_response, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"}, 443
  end

  def test_post
    assert_send_type "(URI, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP, :post, URI('http://www.example.com/api/search'), { "q" => "ruby", "max" => "50" }.to_json, "Content-Type" => "application/json"
    assert_send_type "(URI, Hash[String, Symbol]) -> Net::HTTPResponse",
                     Net::HTTP, :post_form, URI('http://www.example.com/api/search'), { "q" => :ruby, "max" => :max }
  end

  def test_new
    assert_send_type "(String, Integer, nil, nil, nil, nil, nil) -> Net::HTTP",
                     Net::HTTP, :new, 'www.ruby-lang.org', 443, nil, nil, nil, nil, nil
  end
end

class NetInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "net-http"
  library "uri"
  testing "::Net::HTTP"

  class TestNet
    include Net
  end


end