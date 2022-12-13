require_relative "test_helper"
require "net/http"
require "uri"

class NetSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "net-http", "uri"
  testing "singleton(::Net::HTTP)"

  def test_get
    $stdout = StringIO.new
    assert_send_type "(URI::Generic) -> nil",
                     Net::HTTP, :get_print, URI("https://www.ruby-lang.org")
    assert_send_type "(String, String) -> nil",
                     Net::HTTP, :get_print, 'www.ruby-lang.org', '/en'
    assert_send_type "(URI::Generic, Hash[String, String]) -> nil",
                     Net::HTTP, :get_print, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"} if RUBY_VERSION >= '3.0'
    assert_send_type "(URI::Generic) -> String",
                     Net::HTTP, :get, URI("https://www.ruby-lang.org")
    assert_send_type "(String, String) -> String",
                     Net::HTTP, :get, 'www.ruby-lang.org', '/en'
    assert_send_type "(URI::Generic, Hash[String, String]) -> String",
                     Net::HTTP, :get, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"} if RUBY_VERSION >= '3.0'
    assert_send_type "(URI::Generic) -> Net::HTTPResponse",
                     Net::HTTP, :get_response, URI("https://www.ruby-lang.org")
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP, :get_response, 'www.ruby-lang.org', '/en'
    assert_send_type "(URI::Generic, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP, :get_response, URI("https://www.ruby-lang.org"), {"Accept" => "text/html"} if RUBY_VERSION >= '3.0'
  ensure
    $stdout = STDOUT
  end

  def test_post
    assert_send_type "(URI, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP, :post, URI('http://www.example.com/api/search'), { "q" => "ruby", "max" => "50" }.to_json, "Content-Type" => "application/json"
    assert_send_type "(URI, Hash[String, Symbol]) -> Net::HTTPResponse",
                     Net::HTTP, :post_form, URI('http://www.example.com/api/search'), { "q" => :ruby, "max" => :max }
  end

  def test_new
    assert_send_type "(String, Integer, nil, nil, nil, nil, nil) -> Net::HTTP",
                     Net::HTTP, :new, 'www.ruby-lang.org', 80, nil, nil, nil, nil, nil
  end
end

class NetInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  library "net-http", "uri"
  testing "::Net::HTTP"

  class TestNet < Net::HTTP
    def self.new
      super "www.ruby-lang.org", 443
    end
  end

  def test_inspect
    assert_send_type "() -> String",
                     TestNet.new, :inspect
  end

  def test_set_debug_output
    assert_send_type "(IO) -> void",
                     TestNet.new, :set_debug_output, $stderr
  end

  def test_address
    assert_send_type "() -> String",
                     TestNet.new, :address
  end

  def test_port
    assert_send_type "() -> Integer",
                     TestNet.new, :port
  end

  def test_ipaddr
    assert_send_type "() -> nil",
                     TestNet.new, :ipaddr
    assert_send_type "(String) -> void",
                     TestNet.new, :ipaddr=, ('127.0.0.1')
  end

  def test_open_timeout
    assert_send_type "() -> Integer",
                     TestNet.new, :open_timeout
  end

  def test_read_timeout
    assert_send_type "() -> Integer",
                     TestNet.new, :read_timeout
    assert_send_type "(Integer) -> void",
                     TestNet.new, :read_timeout=, 10
  end

  def test_write_timeout
    assert_send_type "() -> Integer",
                     TestNet.new, :write_timeout
    assert_send_type "(Integer) -> void",
                     TestNet.new, :write_timeout=, 10
  end

  def test_continue_timeout
    assert_send_type "() -> nil",
                     TestNet.new, :continue_timeout
    assert_send_type "(Integer) -> void",
                     TestNet.new, :continue_timeout=, 10
  end

  def test_max_retries
    assert_send_type "() -> Integer",
                     TestNet.new, :max_retries
    assert_send_type "(Integer) -> void",
                     TestNet.new, :max_retries=, 10
  end

  def test_keep_alive_timeout
    assert_send_type "() -> Integer",
                     TestNet.new, :keep_alive_timeout
  end

  def test_started_?
    assert_send_type "() -> bool",
                     TestNet.new, :started?
    assert_send_type "() -> bool",
                     TestNet.new, :active?
  end

  def test_use_ssl
    assert_send_type "() -> bool",
                     TestNet.new, :use_ssl?
    assert_send_type "(bool) -> void",
                     TestNet.new, :use_ssl=, true
  end

  def test_start
    assert_send_type "() { (Net::HTTP) -> untyped } -> untyped",
                     TestNet.new, :start do |net_http| net_http.class end
    assert_send_type "() -> Net::HTTP",
                     TestNet.new, :start
  end

  def test_proxy
    assert_send_type "() -> bool",
                     TestNet.new, :proxy?
    assert_send_type "() -> bool",
                     TestNet.new, :proxy_from_env?
    assert_send_type "() -> nil",
                     TestNet.new, :proxy_uri
    assert_send_type "() -> nil",
                     TestNet.new, :proxy_address
    assert_send_type "() -> nil",
                     TestNet.new, :proxy_port
    assert_send_type "() -> nil",
                     TestNet.new, :proxyaddr
    assert_send_type "() -> nil",
                     TestNet.new, :proxyport
    assert_send_type "() -> nil",
                     TestNet.new, :proxy_user
    assert_send_type "() -> nil",
                     TestNet.new, :proxy_pass
  end

  def test_http_verbs
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get, '/en', { "Accept" => "text/html" }
    assert_send_type "(String) { (String) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get, '/en' do |string| string end
    assert_send_type "(String, Hash[String, String]) { (String) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get, '/en', { "Accept" => "text/html" } do |string| string end
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head, '/en', { "Accept" => "text/html" }
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post, '/api/users', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (String) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post, '/api/users', "name=morpheus&job=leader" do |string| string end
    assert_send_type "(String, String, Hash[String, String]) { (String) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" } do |string| string end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                      Net::HTTP.start('reqres.in', 443, use_ssl: true), :patch, '/api/users/2', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                      Net::HTTP.start('reqres.in', 443, use_ssl: true), :patch, '/api/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (String) -> untyped } -> Net::HTTPResponse",
                      Net::HTTP.start('reqres.in', 443, use_ssl: true), :patch, '/api/users/2', "name=morpheus&job=leader" do |string| string end
    assert_send_type "(String, String, Hash[String, String]) { (String) -> untyped } -> Net::HTTPResponse",
                      Net::HTTP.start('reqres.in', 443, use_ssl: true), :patch, '/api/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" } do |string| string end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put, '/api/users/users/2', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put, '/api/users/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :proppatch, '/api/users/users/2', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :proppatch, '/api/users/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :lock, '/api/users/users/2', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :lock, '/api/users/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :unlock, '/api/users/users/2', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :unlock, '/api/users/users/2', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :delete, '/api/users/users/2'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :delete, '/api/users/users/2', { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :move, '/api/users/users/2'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :move, '/api/users/users/2', { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :copy, '/api/users/users/2'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :copy, '/api/users/users/2', { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :mkcol, '/api/users/users/2'
    assert_send_type "(String, nil, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :mkcol, '/api/users/users/2', nil, { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :trace, '/api/users/users/2'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :trace, '/api/users/users/2', { "Accept" => "application/json" }
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_get, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_get, '/en', { "Accept" => "text/html" }
    assert_send_type "(String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_get, '/en' do |response| response end
    assert_send_type "(String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_get, '/en', { "Accept" => "text/html" } do |response| response end
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_head, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_head, '/en', { "Accept" => "text/html" }
    assert_send_type "(String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_head, '/en' do |response| response end
    assert_send_type "(String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request_head, '/en', { "Accept" => "text/html" } do |response| response end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_post, '/api/users', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_post, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_post, '/api/users', "name=morpheus&job=leader" do |response| response end
    assert_send_type "(String, String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_post, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" } do |response| response end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_put, '/api/users', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_put, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_put, '/api/users', "name=morpheus&job=leader" do |response| response end
    assert_send_type "(String, String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :request_put, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" } do |response| response end
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get2, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get2, '/en', { "Accept" => "text/html" }
    assert_send_type "(String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get2, '/en' do |response| response end
    assert_send_type "(String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :get2, '/en', { "Accept" => "text/html" } do |response| response end
    assert_send_type "(String) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head2, '/en'
    assert_send_type "(String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head2, '/en', { "Accept" => "text/html" }
    assert_send_type "(String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head2, '/en' do |response| response end
    assert_send_type "(String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :head2, '/en', { "Accept" => "text/html" } do |response| response end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post2, '/api/users', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post2, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post2, '/api/users', "name=morpheus&job=leader" do |response| response end
    assert_send_type "(String, String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :post2, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" } do |response| response end
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put2, '/api/users', "name=morpheus&job=leader"
    assert_send_type "(String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put2, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" }
    assert_send_type "(String, String) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put2, '/api/users', "name=morpheus&job=leader" do |response| response end
    assert_send_type "(String, String, Hash[String, String]) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :put2, '/api/users', "name=morpheus&job=leader", { "Accept" => "application/json" } do |response| response end
  end

  def test_request
    assert_send_type "(String, String) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :send_request, 'GET', 'api/users'
    assert_send_type "(String, String, String, Hash[String, String]) -> Net::HTTPResponse",
                     Net::HTTP.start('reqres.in', 443, use_ssl: true), :send_request, 'POST', 'api/users', 'name=morpheus&job=leader', { "Accept" => "application/json" }
    assert_send_type "(Net::HTTPRequest) -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request, Net::HTTP::Get.new(URI('https://www.ruby-lang.org'))
    assert_send_type "(Net::HTTPRequest) { (Net::HTTPResponse) -> untyped } -> Net::HTTPResponse",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true), :request, Net::HTTP::Get.new(URI('https://www.ruby-lang.org')) do |response| response.body end
  end
end

class TestHTTPRequest < Test::Unit::TestCase
  include TypeAssertions

  library "net-http", "uri"
  testing "::Net::HTTPRequest"

  def test_inspect
    assert_send_type "() -> String",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :inspect
  end

  def test_attr_readers
    assert_send_type "() -> String",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :method
    assert_send_type "() -> String",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :path
    assert_send_type "() -> URI::Generic",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :uri
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :decode_content
  end

  def test_body
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :request_body_permitted?
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :response_body_permitted?
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :body_exist?
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :body
    assert_send_type "(String) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :body=, "Body of the request"
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :body_stream
    assert_send_type "(untyped) -> untyped",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :body_stream=, "Pass any stream"
  end

  def test_manipulation_of_headers
    assert_send_type "(String) -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :[], "Content-Type"
    assert_send_type "(String, untyped) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :[]=, "Content-Type", "application/json"
    assert_send_type "(String, untyped) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :add_field, "Content-Type", "application/json"
    assert_send_type "(String) -> nil",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true).request_get('/en'), :get_fields, "Set-Cookie"
    assert_send_type "(String) { (String) -> String } -> String",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true).request_get('/en'), :fetch, "Set-Cookie" do |val| val end
    assert_send_type "(String) -> nil",
                     Net::HTTP.start('www.ruby-lang.org', 443, use_ssl: true).request_get('/en'), :delete, "Set-Cookie"
    assert_send_type "(String) -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :key?, "Set-Cookie"
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :range
    assert_send_type "(Range[Integer]) -> Range[Integer]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :set_range, 0..1023
    assert_send_type "(Numeric, Integer) -> Range[Integer]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :set_range, 0, 1023
    assert_send_type "(Range[Integer]) -> Range[Integer]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :range=, 0..1023
    assert_send_type "(Numeric, Integer) -> Range[Integer]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :range=, 0, 1023
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_length
    assert_send_type "(Integer) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_length=, 1023
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_range
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :chunked?
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :range_length
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_type
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :main_type
    assert_send_type "() -> nil",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :sub_type
    assert_send_type "() -> Hash[untyped, untyped]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :type_params
    assert_send_type "(String) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :set_content_type, "text/html"
    assert_send_type "(String, Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :set_content_type, "text/html", { "charset" => "iso-8859-1" }
    assert_send_type "(String) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_type=, "text/html"
    assert_send_type "(String, Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :content_type=, "text/html", { "charset" => "iso-8859-1" }
    assert_send_type "(Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :set_form_data, {"q" => "ruby", "lang" => "en"}
    assert_send_type "(Hash[untyped, untyped], String) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :set_form_data, {"q" => "ruby", "lang" => "en"}, '&'
    assert_send_type "(Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :form_data=, {"q" => "ruby", "lang" => "en"}
    assert_send_type "(Hash[untyped, untyped], String) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :form_data=, {"q" => "ruby", "lang" => "en"}, '&'
    assert_send_type "(Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :set_form, {"q" => "ruby", "lang" => "en"}
    assert_send_type "(Hash[untyped, untyped], String, Hash[untyped, untyped]) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :set_form, {"q" => "ruby", "lang" => "en"}, "multipart/form-data", { charset: "UTF-8" }
    assert_send_type "(String account, String password) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :basic_auth, "username", "password"
    assert_send_type "(String account, String password) -> void",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :proxy_basic_auth, "username", "password"
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :connection_close?
    assert_send_type "() -> bool",
                     Net::HTTP::Get.new(URI('https://reqres.in')), :connection_keep_alive?
  end

  def test_iteration_on_headers
    assert_send_type "() { (String, String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_header do |str, array| "#{str} #{array}" end
    assert_send_type "() -> Enumerator[[String, String], Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_header
    assert_send_type "() { (String, String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each do |str, array| "#{str} #{array}" end
    assert_send_type "() -> Enumerator[[String, String], Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each
    assert_send_type "() { (String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_name do |str| str end
    assert_send_type "() -> Enumerator[String, Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_name
    assert_send_type "() { (String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_key do |str| str end
    assert_send_type "() -> Enumerator[String, Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_key
    assert_send_type "() { (String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_value do |arr| arr end
    assert_send_type "() -> Enumerator[String, Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_value
    assert_send_type "() -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :to_hash
    assert_send_type "() { (String, String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_capitalized do |str_1, str_2| "#{str_1} #{str_2}" end
    assert_send_type "() -> Enumerator[[String, String], Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :each_capitalized
    assert_send_type "() { (String, String) -> untyped } -> Hash[String, Array[String]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :canonical_each do |str_1, str_2| "#{str_1} #{str_2}" end
    assert_send_type "() -> Enumerator[[String, String], Hash[String, Array[String]]]",
                     Net::HTTP::Get.new(URI('https://www.ruby-lang.org')), :canonical_each
  end
end

class TestSingletonNetHTTPResponse < Test::Unit::TestCase
  include TypeAssertions

  library "net-http", "uri"
  testing "singleton(::Net::HTTPResponse)"

  def test_body_permitted_?
    assert_send_type "() -> bool",
                     Net::HTTPSuccess, :body_permitted?
  end
end

class TestInstanceNetHTTPResponse < Test::Unit::TestCase
  include TypeAssertions

  library "net-http", "uri"
  testing "::Net::HTTPResponse"

  class Foo
    def self.success
      Net::HTTP.get_response(URI('https://www.ruby-lang.org'))
    end
  end

  def test_attr_readers
    assert_send_type "() -> String",
                     Foo.success, :http_version
    assert_send_type "() -> String",
                     Foo.success, :code
    assert_send_type "() -> String",
                     Foo.success, :message
    assert_send_type "() -> String",
                     Foo.success, :msg
    assert_send_type "() -> URI::Generic",
                     Foo.success, :uri
    assert_send_type "() -> bool",
                     Foo.success, :decode_content
  end

  def test_manipulation_function
    assert_send_type "() -> String",
                     Foo.success, :inspect
    assert_send_type "() -> untyped",
                     Foo.success, :code_type
    assert_send_type "() -> nil",
                     Foo.success, :value
    assert_send_type "(URI::Generic) -> void",
                     Foo.success, :uri=, URI('https://reqres.in')
    # assert_send_type "() { (String) -> untyped } -> String",
    #                  Net::HTTP.start('reqres.in', 443, use_ssl: true).request_get('/api/users'), :read_body do |str| str end
    # assert_send_type "() -> String",
    #                  Net::HTTP.start('reqres.in', 443, use_ssl: true).request_get('/api/users'), :read_body
    assert_send_type "() -> String",
                     Foo.success, :body
    assert_send_type "(untyped) -> void",
                     Foo.success, :body=, "Body"
    assert_send_type "() -> String",
                     Foo.success, :entity
  end
end
