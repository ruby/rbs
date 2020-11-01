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
    io = StringIO.new('example')
    io.close_write
  end

  def test_closed_write?
    io = StringIO.new('example')
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
