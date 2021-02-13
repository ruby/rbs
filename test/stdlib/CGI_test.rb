require_relative "test_helper"
require "cgi"

class CGISingletonTest < Test::Unit::TestCase
  include TypeAssertions

  library "cgi"
  testing "singleton(::CGI)"

  def test_new
    ARGV.replace(%w(abc=001 def=002))
    assert_send_type  "() -> ::CGI",
                      CGI, :new
    assert_send_type  "(?::String options) -> ::CGI",
                      CGI, :new, 'html3'
    assert_send_type  "[T] (?::String options) ?{ (::String name, ::String value) -> T } -> ::CGI",
                      CGI, :new, 'html3' do |name, value| name + value end
    assert_send_type  "[T, U] (?::Hash[::Symbol, T]) -> ::CGI",
                      CGI, :new, { tag_maker: 'html5', max_multipart_length: 2048 }
    assert_send_type  "[T, U] (?::Hash[::Symbol, T]) ?{ (::String name, ::String value) -> U } -> ::CGI",
                      CGI, :new, { tag_maker: 'html5', max_multipart_length: 2048 } do |name, value| name + value end
  end

  def test_accept_charset
    assert_send_type  "() -> ::String",
                      CGI, :accept_charset
  end

  def test_accept_charset=
    assert_send_type  "(::String accept_charset) -> ::String",
                      CGI, :accept_charset=, 'utf-8'
  end

  def test_parse
    assert_send_type  "[T] (::String query) -> ::Hash[::String, T]",
                      CGI, :parse, 'a=hoge&b=1&c[]=test1&c[]=test2'
  end
end

class CGITest < Test::Unit::TestCase
  include TypeAssertions

  library "cgi"
  testing "::CGI"

  def setup
    ARGV.replace(%w(abc=001 def=002))
  end

  def test_print
    assert_send_type  "(*::String options) -> void",
                      CGI.new, :print, ''
  end

  def test_http_header
    assert_send_type  "() -> ::String",
                      CGI.new, :http_header
    assert_send_type  "(::String options) -> ::String",
                      CGI.new, :http_header, 'text/csv'
    assert_send_type  "[T] (::Hash[::String, T]) -> ::String",
                      CGI.new, :http_header, { 'type' => 'text/csv', 'nph' => false, 'length' => 1024 }
    assert_send_type  "[T] (::Hash[::Symbol, T]) -> ::String",
                      CGI.new, :http_header, { type: 'text/csv', nph: false, length: 1024 }
  end

  def test_header
    assert_send_type  "() -> ::String",
                      CGI.new, :header
    assert_send_type  "(::String options) -> ::String",
                      CGI.new, :header, 'text/csv'
    assert_send_type  "[T] (::Hash[::String, T]) -> ::String",
                      CGI.new, :header, { 'type' => 'text/csv', 'nph' => false, 'length' => 1024 }
    assert_send_type  "[T] (::Hash[::Symbol, T]) -> ::String",
                      CGI.new, :header, { type: 'text/csv', nph: false, length: 1024 }
  end

  def test_nph?
    assert_send_type  "() -> ::boolish",
                      CGI.new, :nph?
  end

  def test_out
    assert_send_type  "() { () -> void } -> void",
                      CGI.new, :out do '' end
    assert_send_type  "(::String options) { () -> void } -> void",
                      CGI.new, :out, 'text/csv' do '' end
    assert_send_type  "[T] (::Hash[::String, T]) { () -> void } -> void",
                      CGI.new, :out, { 'type' => 'text/csv', 'nph' => false, 'length' => 1024 } do '' end
    assert_send_type  "[T] (::Hash[::String | ::Symbol, T]) { () -> void } -> void",
                      CGI.new, :out, { type: 'text/csv' } do '' end
  end

  def test_stdinput
    assert_send_type  "() -> ::IO",
                      CGI.new, :stdinput
  end

  def test_stdoutput
    assert_send_type  "() -> ::IO",
                      CGI.new, :stdoutput
  end
 end
