require_relative "test_helper"
require "pathname"
require "tmpdir"

class MarshalSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  testing "singleton(::Marshal)"

  def test_dump
    assert_send_type "(::String) -> ::String",
                     Marshal, :dump, ""

    assert_send_type "(::String, ::Integer) -> ::String",
                     Marshal, :dump, "", 3

    io = (Pathname(Dir.mktmpdir) + "foo").open("w")

    assert_send_type "(::String, ::File) -> ::File",
                     Marshal, :dump, "", io
  end

  def test_load
    dump = Marshal.dump([1,2,3])

    assert_send_type(
      "(::String) -> ::Array[::Integer]",
      Marshal, :load, dump
    )

    assert_send_type(
      "(::String, freeze: bool) -> ::Array[::Integer]",
      Marshal, :load, dump, freeze: true
    )
    assert_send_type(
      "(::String, freeze: Symbol) -> ::Array[::Integer]",
      Marshal, :load, dump, freeze: :true
    )

    assert_send_type(
      "(::String, ^(untyped) -> void) -> ::Integer",
      Marshal, :load, dump, -> (_x) { 123 }
    )

    name = Pathname(Dir.mktmpdir) + "foo"

    File.open(name, "w") do |io|
      Marshal.dump([1,2,3], io)
    end
    File.open(name) do |io|
      assert_send_type(
        "(IO) -> ::Array[::Integer]",
        Marshal, :load, io
      )
    end
  end
end
