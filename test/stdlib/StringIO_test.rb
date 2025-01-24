require_relative "test_helper"

class StringIOTest < StdlibTest
  target StringIO

  def test_close_read
    io = StringIO.new('example')
    io.close_read
  end

  def test_closed_read?
    io = StringIO.new('example')
    io.closed_read?
    io.close_read
    io.closed_read?
  end

  def test_close_write
    io = StringIO.new(+'example')
    io.close_write
  end

  def test_closed_write?
    io = StringIO.new(+'example')
    io.closed_write?
    io.close_write
    io.closed_write?
  end

  def test_each
    io = StringIO.new("")
    io.each(chomp: 3) do end
    io.each(chomp: 3)
  end

  def test_gets
    io = StringIO.new("")
    io.gets(chomp: :true)
  end
end

class StringIOTypeTest < Test::Unit::TestCase
  include TestHelper

  testing '::StringIO'

  def test_write
    io = StringIO.new

    assert_send_type "(*String data) -> Integer",
                     io, :write, "a", "b"
  end

  def test_truncate
    io = StringIO.new

    assert_send_type(
      "(Integer) -> 0",
      io, :truncate, 10
    )
  end

  def test_readline
    assert_send_type  "() -> ::String",
                      StringIO.new("\n"), :readline
    assert_send_type  "(::String sep) -> ::String",
                      StringIO.new("\n"), :readline, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::String",
                      StringIO.new("\n"), :readline, "\n", 1
    assert_send_type  "(chomp: boolish) -> ::String",
                      StringIO.new("\n"), :readline, chomp: true
    assert_send_type  "(::String sep, ::Integer limit, chomp: boolish) -> ::String",
                      StringIO.new("\n"), :readline, "\n", 1, chomp: true
  end

  def test_readlines
    assert_send_type  "() -> ::Array[::String]",
                      StringIO.new("\n"), :readlines
    assert_send_type  "(::String sep) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n"
    assert_send_type  "(::String sep, ::Integer limit) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n", 1
    assert_send_type  "(chomp: boolish) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, chomp: true
    assert_send_type  "(::String sep, ::Integer limit, chomp: boolish) -> ::Array[::String]",
                      StringIO.new("\n"), :readlines, "\n", 1, chomp: true
  end
end
