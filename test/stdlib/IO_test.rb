require_relative "test_helper"

class IOSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  testing "singleton(::IO)"

  def test_binread
    assert_send_type "(String) -> String",
                     IO, :binread, __FILE__
    assert_send_type "(String, Integer) -> String",
                     IO, :binread, __FILE__, 3
    assert_send_type "(String, Integer, Integer) -> String",
                     IO, :binread, __FILE__, 3, 0
  end

  def test_binwrite
    Dir.mktmpdir do |dir|
      filename = File.join(dir, "some_file")
      content = "foo"

      assert_send_type "(String, String) -> Integer",
                       IO, :binwrite, filename, content
      assert_send_type "(String, String, Integer) -> Integer",
                       IO, :binwrite, filename, content, 0
      assert_send_type "(String, String, mode: String) -> Integer",
                       IO, :binwrite, filename, content, mode: "a"
      assert_send_type "(String, String, Integer, mode: String) -> Integer",
                       IO, :binwrite, filename, content, 0, mode: "a"
    end
  end

  def test_open
    Dir.mktmpdir do |dir|
      fd = IO.sysopen(__FILE__)

      assert_send_type "(Integer) -> IO",
                       IO, :open, fd
      assert_send_type "(ToInt, String) -> IO",
                       IO, :open, ToInt.new(fd), "r"
      assert_send_type "(Integer) { (IO) -> String } -> String",
                       IO, :open, fd do |io| io.read end
    end
  end

  def test_copy_stream
    Dir.mktmpdir do |dir|
      src_name = File.join(dir, "src_file").tap { |f| IO.write(f, "foo") }
      dst_name = File.join(dir, "dst_file")

      assert_send_type "(String, String) -> Integer",
                       IO, :copy_stream, src_name, dst_name
      assert_send_type "(String, String, Integer) -> Integer",
                       IO, :copy_stream, src_name, dst_name, 1
      assert_send_type "(String, String, Integer, Integer) -> Integer",
                       IO, :copy_stream, src_name, dst_name, 1, 0

      File.open(dst_name, "w") do |dst_io|
        assert_send_type "(String, IO) -> Integer",
                         IO, :copy_stream, src_name, dst_io
        assert_send_type "(String, IO, Integer) -> Integer",
                         IO, :copy_stream, src_name, dst_io, 1
        assert_send_type "(String, IO, Integer, Integer) -> Integer",
                         IO, :copy_stream, src_name, dst_io, 1, 0
      end

      File.open(src_name) do |src_io|
        assert_send_type "(IO, String) -> Integer",
                         IO, :copy_stream, src_io, dst_name
        assert_send_type "(IO, String, Integer) -> Integer",
                         IO, :copy_stream, src_io, dst_name, 1
        assert_send_type "(IO, String, Integer, Integer) -> Integer",
                         IO, :copy_stream, src_io, dst_name, 1, 0
      end

      File.open(src_name) do |src_io|
        File.open(dst_name, "w") do |dst_io|
          assert_send_type "(IO, IO) -> Integer",
                           IO, :copy_stream, src_io, dst_io
          assert_send_type "(IO, IO, Integer) -> Integer",
                           IO, :copy_stream, src_io, dst_io, 1
          assert_send_type "(IO, IO, Integer, Integer) -> Integer",
                           IO, :copy_stream, src_io, dst_io, 1, 0
        end
      end
    end
  end
end

class IOInstanceTest < Test::Unit::TestCase
  include TypeAssertions

  testing "::IO"

  def test_append_symbol
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, "some_file"), "w") do |io|
        assert_send_type "(String) -> self",
                         io, :<<, "foo"
        assert_send_type "(Object) -> self",
                         io, :<<, Object.new
      end
    end
  end

  def test_advise
    IO.open(IO.sysopen(__FILE__)) do |io|
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :normal
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :sequential
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :random
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :willneed
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :dontneed
      assert_send_type "(Symbol) -> nil",
                       io, :advise, :noreuse
      assert_send_type "(Symbol, Integer) -> nil",
                       io, :advise, :normal, 1
      assert_send_type "(Symbol, Integer, Integer) -> nil",
                       io, :advise, :normal, 1, 2
    end
  end

  def test_autoclose=
    IO.open(IO.sysopen(__FILE__)) do |io|
      assert_send_type "(bool) -> bool",
                       io, :autoclose=, true
      assert_send_type "(bool) -> bool",
                       io, :autoclose=, false
    end
  end

  def test_autoclose?
    IO.open(IO.sysopen(__FILE__)) do |io|
      assert_send_type "() -> bool",
                       io, :autoclose?
    end
  end

  def test_read
    IO.open(IO.sysopen(__FILE__)) do |io|
      assert_send_type "() -> String",
                       io, :read
      assert_send_type "(Integer) -> String",
                       io, :read, 0
      assert_send_type "(Integer) -> nil",
                       io, :read, 1
      assert_send_type "(nil) -> String",
                       io, :read, nil
      assert_send_type "(Integer, String) -> String",
                       io, :read, 0, "buffer"
      assert_send_type "(Integer, String) -> nil",
                       io, :read, 1, "buffer"
      assert_send_type "(nil, String) -> String",
                       io, :read, nil, "buffer"
    end
  end

  def test_readpartial
    IO.open(IO.sysopen(__FILE__)) do |io|
      assert_send_type "(Integer) -> String",
                       io, :readpartial, 10
      assert_send_type "(Integer, String) -> String",
                       io, :readpartial, 10, "buffer"
    end
  end

  def test_write
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, "some_file"), "w") do |io|
        assert_send_type "() -> Integer",
                         io, :write
        assert_send_type "(String) -> Integer",
                         io, :write, "foo"
        assert_send_type "(String, Float) -> Integer",
                         io, :write, "foo", 1.5
      end
    end
  end
end
